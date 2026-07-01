import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit.dart';
import '../services/db_service.dart';
import 'wallet_provider.dart';

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier(this.ref) : super([]) {
    _load();
  }

  final Ref ref;
  final Isar _isar = DbService.instance;

  Future<void> _load() async {
    final habits = await _isar.habits.where().sortByCreatedAtDesc().findAll();
    state = habits;
  }

  Future<void> addHabit({
    required String title,
    String? notes,
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> activeWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    int baseCoinValue = 8,
  }) async {
    final habit = Habit()
      ..title = title
      ..notes = notes
      ..frequency = frequency
      ..activeWeekdays = activeWeekdays
      ..baseCoinValue = baseCoinValue;
    await _isar.writeTxn(() async {
      await _isar.habits.put(habit);
    });
    await _load();
  }

  bool isCompletedToday(Habit habit) {
    if (habit.lastCompletedAt == null) return false;
    final now = DateTime.now();
    final last = habit.lastCompletedAt!;
    return now.year == last.year && now.month == last.month && now.day == last.day;
  }

  /// Forgiving streak design: if the user misses exactly one day, a streak
  /// freeze is consumed automatically instead of resetting the streak to
  /// zero. This avoids the "I missed one day so why bother" spiral that
  /// punishing streak systems tend to create.
  Future<void> completeHabit(Habit habit) async {
    if (isCompletedToday(habit)) return;

    final now = DateTime.now();
    final last = habit.lastCompletedAt;
    int newStreak;

    if (last == null) {
      newStreak = 1;
    } else {
      final daysSince = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;

      if (daysSince == 1) {
        newStreak = habit.currentStreak + 1;
      } else if (daysSince == 2 && habit.streakFreezesAvailable > 0) {
        // exactly one day missed -> consume a freeze, keep streak alive
        habit.streakFreezesAvailable -= 1;
        newStreak = habit.currentStreak + 1;
      } else if (daysSince <= 0) {
        newStreak = habit.currentStreak; // safety guard, shouldn't normally hit
      } else {
        newStreak = 1; // streak broken, restart gently — no zero-shame messaging
      }
    }

    habit.currentStreak = newStreak;
    habit.bestStreak = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;
    habit.lastCompletedAt = now;
    habit.totalCompletions += 1;

    await _isar.writeTxn(() async {
      await _isar.habits.put(habit);
    });

    // Gentle streak bonus: +1 coin per 5 streak days, capped, so growth
    // feels rewarding without making the base loop feel punishing if broken.
    final bonus = (newStreak ~/ 5).clamp(0, 10);
    final payout = habit.baseCoinValue + bonus;

    await ref.read(walletProvider.notifier).earn(
          payout,
          'Habit streak (${newStreak}d): ${habit.title}',
        );

    await _load();
  }

  Future<void> deleteHabit(Habit habit) async {
    await _isar.writeTxn(() async {
      await _isar.habits.delete(habit.id);
    });
    await _load();
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier(ref);
});
