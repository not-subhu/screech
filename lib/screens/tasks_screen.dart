import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_card.dart';
import '../widgets/add_task_sheet.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingTasksProvider);
    final completed = ref.watch(completedTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (pending.isEmpty && completed.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'ACTIVE QUESTS',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => QuestCard(
                    key: ValueKey(pending[i].id),
                    task: pending[i],
                    onComplete: () => ref
                        .read(tasksProvider.notifier)
                        .completeTask(pending[i]),
                    onTap: () {},
                  ).animate().fadeIn(delay: (i * 40).ms).slideX(
                        begin: 0.05,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                  childCount: pending.length,
                ),
              ),
            ],
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'COMPLETED',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Dismissible(
                    key: ValueKey('done_${completed[i].id}'),
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
                    onDismissed: (_) => ref
                        .read(tasksProvider.notifier)
                        .deleteTask(completed[i]),
                    child: QuestCard(
                      key: ValueKey(completed[i].id),
                      task: completed[i],
                      onComplete: () {},
                      onTap: () {},
                    ),
                  ),
                  childCount: completed.length,
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTaskSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Quest',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.sakura,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✦', style: TextStyle(fontSize: 48, color: AppColors.sakura.withOpacity(0.5)))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 1800.ms,
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.15, 1.15),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 20),
          Text('No quests yet!',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Add your first quest below  (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
