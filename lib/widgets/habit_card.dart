import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/habit.dart';
import '../theme/app_theme.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onComplete,
  });

  final Habit habit;
  final bool isCompletedToday;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final payout = habit.baseCoinValue + (habit.currentStreak ~/ 5).clamp(0, 10);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.cardGradient,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mint stripe for habits (distinguishes from task sakura stripe)
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompletedToday
                        ? [AppColors.mint.withOpacity(0.3), AppColors.mint.withOpacity(0.1)]
                        : [AppColors.mint, AppColors.mintDeep],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              habit.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isCompletedToday
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${habit.currentStreak} day streak',
                                  style: const TextStyle(
                                    color: AppColors.coinGold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (habit.streakFreezesAvailable > 0) ...[
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(
                                      habit.streakFreezesAvailable.clamp(0, 3),
                                      (_) => const Padding(
                                        padding: EdgeInsets.only(right: 2),
                                        child: Icon(Icons.ac_unit,
                                            size: 12, color: AppColors.mint),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Complete button
                      GestureDetector(
                        onTap: isCompletedToday ? null : onComplete,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isCompletedToday ? null : const LinearGradient(
                                  colors: [AppColors.mint, AppColors.mintDeep],
                                ),
                                color: isCompletedToday ? AppColors.surfaceBorder : null,
                                boxShadow: isCompletedToday
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppColors.mint.withOpacity(0.4),
                                          blurRadius: 10,
                                        ),
                                      ],
                              ),
                              child: Icon(
                                isCompletedToday ? Icons.check : Icons.add,
                                color: isCompletedToday ? AppColors.mint : Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: AppColors.coinGold, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '+$payout',
                                  style: const TextStyle(
                                    color: AppColors.coinGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate(target: isCompletedToday ? 0 : 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
