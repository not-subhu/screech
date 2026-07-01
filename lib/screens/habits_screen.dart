import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/habits_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_sheet.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥',
                          style: TextStyle(
                              fontSize: 48,
                              color: AppColors.mint.withOpacity(0.5)))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        duration: 1600.ms,
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.15, 1.15),
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 20),
                  Text('No habits yet!',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Build streaks, earn bonus coins  (´｡• ᵕ •｡`)',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: habits.length,
              itemBuilder: (ctx, i) {
                final habit = habits[i];
                return Dismissible(
                  key: ValueKey(habit.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.urgentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.urgentRed),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Delete habit?',
                                style:
                                    TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                                'Your streak of ${habit.currentStreak} days will be lost.',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel',
                                    style:
                                        TextStyle(color: AppColors.textMuted)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style: TextStyle(
                                        color: AppColors.urgentRed)),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) =>
                      ref.read(habitsProvider.notifier).deleteHabit(habit),
                  child: HabitCard(
                    habit: habit,
                    isCompletedToday: notifier.isCompletedToday(habit),
                    onComplete: () =>
                        ref.read(habitsProvider.notifier).completeHabit(habit),
                  ).animate().fadeIn(delay: (i * 40).ms).slideX(
                        begin: 0.05,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddHabitSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Habit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
      ),
    );
  }
}
