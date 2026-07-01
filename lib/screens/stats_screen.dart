import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../providers/wallet_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/habits_provider.dart';
import '../theme/app_theme.dart';

// TODO: Import the file where LedgerType is defined, if it isn't part of the providers above.
// For example: import '../models/ledger_entry.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final ledger = ref.watch(ledgerHistoryProvider);

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary row
          Row(
            children: [
              _StatTile(
                label: 'Quests Done',
                value: '$completedTasks',
                icon: '⚔️',
                color: AppColors.sakura,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Coins Earned',
                value: '${wallet.totalEarnedLifetime}',
                icon: '✦',
                color: AppColors.coinGold,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 60.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Best Streak',
                value: '${bestStreak}d',
                icon: '🔥',
                color: AppColors.mint,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 120.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
          const SizedBox(height: 16),
          // Quest completion bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quest Progress',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      totalTasks == 0
                          ? '—'
                          : '$completedTasks / $totalTasks',
                      style: const TextStyle(
                          color: AppColors.sakura,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalTasks == 0
                        ? 0
                        : completedTasks / totalTasks,
                    minHeight: 10,
                    backgroundColor: AppColors.bgDeep,
                    valueColor: const AlwaysStoppedAnimation(AppColors.sakura),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: 12),
          // Habits overview
          if (habits.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Habits',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  ...habits.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(h.title,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                          Text(
                            '${h.currentStreak}d streak',
                            style: const TextStyle(
                                color: AppColors.coinGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
            const SizedBox(height: 12),
          ],
          // Recent activity
          Text('RECENT ACTIVITY',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          ledger.when(
            data: (entries) => entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Complete quests to see activity here!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : Column(
                    children: entries.asMap().entries.map((e) {
                      final entry = e.value;
                      final isEarn = entry.type == LedgerType.earned;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isEarn
                                        ? AppColors.mint
                                        : AppColors.coinGold)
                                    .withOpacity(0.18),
                              ),
                              child: Center(
                                child: Text(
                                  isEarn ? '✦' : '✦',
                                  style: TextStyle(
                                    color: isEarn
                                        ? AppColors.mint
                                        : AppColors.coinGold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.reason,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, h:mm a')
                                        .format(entry.timestamp),
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isEarn ? '+' : '-'}${entry.amount}',
                              style: TextStyle(
                                color: isEarn
                                    ? AppColors.mint
                                    : AppColors.coinGold,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (e.key * 30).ms);
                    }).toList(),
                  ),
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.sakura)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}