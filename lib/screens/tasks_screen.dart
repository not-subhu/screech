import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/tasks_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_card.dart';

/// Tasks screen, One UI style: a big "viewing area" hero on top and an
/// "interaction area" (the quest list) below. Scrolling down fades and
/// shrinks the hero away entirely so the list — and every control on it —
/// stays reachable one-handed, even when there's nothing to show yet.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingTasksProvider);
    final completed = ref.watch(completedTasksProvider);
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);

    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.46).clamp(300.0, 460.0);
    final isEmpty = pending.isEmpty && completed.isEmpty;

    return Container(
      color: palette.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: false,
            delegate: _HeroHeaderDelegate(
              maxHeight: heroHeight,
              headerStyle: settings.headerStyle,
            ),
          ),
          if (isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                // Tall enough on its own to let the hero scroll fully away
                // — an empty list still becomes a full-screen surface.
                height: screenHeight,
                child: _EmptyState(palette: palette),
              ),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text('ACTIVE QUESTS', style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => QuestCard(
                    key: ValueKey(pending[i].id),
                    task: pending[i],
                    onComplete: () =>
                        ref.read(tasksProvider.notifier).completeTask(pending[i]),
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
                  child: Text('COMPLETED', style: Theme.of(context).textTheme.labelSmall),
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.urgentRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppColors.urgentRed),
                    ),
                    onDismissed: (_) =>
                        ref.read(tasksProvider.notifier).deleteTask(completed[i]),
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
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✦', style: TextStyle(fontSize: 48, color: palette.accent.withOpacity(0.5)))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 1800.ms,
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.15, 1.15),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 20),
          Text('No quests yet!', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tap + below to add one  (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text('scroll up to bring the art back ↑',
              style: TextStyle(fontSize: 11, color: palette.textMuted)),
        ],
      ),
    );
  }
}

/// One UI-style collapsing hero: shrinks from [maxHeight] to 0 as the user
/// scrolls, fading and drifting away rather than just being clipped off.
class _HeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeroHeaderDelegate({required this.maxHeight, required this.headerStyle});

  final double maxHeight;
  final HeaderStyle headerStyle;

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = maxHeight <= 0 ? 0.0 : (shrinkOffset / maxHeight).clamp(0.0, 1.0);
    final opacity = (1 - progress * 1.4).clamp(0.0, 1.0);

    return ClipRect(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, -shrinkOffset * 0.35),
          child: SizedBox(
            height: maxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _HeroBackground(style: headerStyle),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x05000000), Color(0x9E000000)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
                const Positioned(
                  left: 26,
                  right: 26,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep going.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Discipline today, freedom tomorrow.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeroHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight || oldDelegate.headerStyle != headerStyle;
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.style});

  final HeaderStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case HeaderStyle.photo:
        return Image.asset('assets/images/header_hero.webp', fit: BoxFit.cover);
      case HeaderStyle.sakuraDusk:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6FA5), Color(0xFF6A3E9C), Color(0xFF1A1025)],
            ),
          ),
        );
      case HeaderStyle.cursedViolet:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF120B1C), Color(0xFF3A2566), Color(0xFF6A1B2F)],
            ),
          ),
        );
      case HeaderStyle.mintDawn:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7DE0D3), Color(0xFF2D6E63), Color(0xFF12251F)],
            ),
          ),
        );
    }
  }
}
