import 'package:isar/isar.dart';

part 'habit.g.dart';

enum HabitFrequency { daily, weekly, custom }

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String title;

  String? notes;

  @enumerated
  HabitFrequency frequency = HabitFrequency.daily;

  /// For custom frequency: which weekdays (1=Mon..7=Sun) it's active.
  List<int> activeWeekdays = [1, 2, 3, 4, 5, 6, 7];

  DateTime? lastCompletedAt;

  /// Current streak count. Forgiving design: missing a single day doesn't
  /// zero this out immediately — see [streakFreezeAvailable].
  int currentStreak = 0;

  int bestStreak = 0;

  /// Base coin reward per completion; actual payout scales gently with streak.
  int baseCoinValue = 8;

  DateTime createdAt = DateTime.now();

  /// Forgiving streak mechanic: each habit gets periodic "streak freezes"
  /// (like Duolingo) so one missed day doesn't erase progress and
  /// discourage the user from opening the app again.
  int streakFreezesAvailable = 2;

  /// Tracks total completions ever, independent of streak resets.
  int totalCompletions = 0;

  int? reminderHour;
  int? reminderMinute;
  int? notificationId;
}
