import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../screens/tasks_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/stats_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_badge.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/app_drawer.dart';
import '../widgets/add_task_sheet.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

/// Height reserved above Habits/Shop/Stats so their content clears the
/// floating hamburger + coin chrome, which is drawn in a Stack above
/// everything (Tasks screen instead builds that space into its own hero).
const _kChromeReserve = 64.0;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);
    final width = MediaQuery.of(context).size.width;
    final topSafe = MediaQuery.of(context).padding.top;

    final screens = <Widget>[
      const TasksScreen(),
      Padding(
        padding: EdgeInsets.only(top: topSafe + _kChromeReserve),
        child: const HabitsScreen(),
      ),
      Padding(
        padding: EdgeInsets.only(top: topSafe + _kChromeReserve),
        child: const ShopScreen(),
      ),
      Padding(
        padding: EdgeInsets.only(top: topSafe + _kChromeReserve),
        child: const StatsScreen(),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.bg,
      extendBody: true,
      drawer: const AppDrawer(),
      // Sliding from the left half of the screen opens the drawer, not just
      // the usual thin edge strip.
      drawerEdgeDragWidth: width * 0.5,
      drawerScrimColor: Colors.black.withOpacity(0.45),
      body: Stack(
        children: [
          Positioned.fill(child: IndexedStack(index: navIndex, children: screens)),
          Positioned(
            top: topSafe + 12,
            left: 16,
            child: LiquidGlassIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Positioned(
            top: topSafe + 14,
            right: 16,
            child: const CoinBadge(),
          ),
        ],
      ),
      bottomNavigationBar: _GlassBottomBar(
        navIndex: navIndex,
        palette: palette,
        onSelect: (i) => ref.read(navIndexProvider.notifier).state = i,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: navIndex == 0
          ? _GlassFab(
              accent: settings.accentColor,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddTaskSheet(),
              ),
            )
          : null,
    );
  }
}

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({
    required this.navIndex,
    required this.palette,
    required this.onSelect,
  });

  final int navIndex;
  final GlassPalette palette;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.auto_stories_outlined, Icons.auto_stories, 'Quests'),
    (Icons.local_fire_department_outlined, Icons.local_fire_department, 'Habits'),
    (Icons.storefront_outlined, Icons.storefront, 'Shop'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: LiquidGlass(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: itemWidth * navIndex,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.accent.withOpacity(0.22),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.accent.withOpacity(0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_items.length, (i) {
                      final selected = i == navIndex;
                      final entry = _items[i];
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                          child: AnimatedScale(
                            scale: selected ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selected ? entry.$2 : entry.$1,
                                  color: selected ? palette.accent : palette.textMuted,
                                  size: 22,
                                ),
                                const SizedBox(height: 2),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected ? palette.accent : palette.textMuted,
                                  ),
                                  child: Text(entry.$3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassFab extends StatefulWidget {
  const _GlassFab({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  State<_GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<_GlassFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.85).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.accent, widget.accent.withOpacity(0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
