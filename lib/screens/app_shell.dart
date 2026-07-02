import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../screens/tasks_screen.dart';
import '../screens/shop_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_badge.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/app_drawer.dart';
import '../widgets/quick_add_panel.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showQuickAdd = false;

  void _openQuickAdd() => setState(() => _showQuickAdd = true);
  void _closeQuickAdd() => setState(() => _showQuickAdd = false);

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);
    final width = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    const screens = <Widget>[
      TasksScreen(),
      ShopScreen(),
    ];

    return PopScope(
      canPop: !_showQuickAdd,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showQuickAdd) _closeQuickAdd();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: palette.bg,
        // Don't let scaffold resize — the quick-add panel handles keyboard itself
        resizeToAvoidBottomInset: false,
        extendBody: true,
        drawer: const AppDrawer(),
        drawerEdgeDragWidth: width * 0.5,
        drawerScrimColor: Colors.black.withOpacity(0.45),
        body: Stack(
          children: [
            // ── Main content ───────────────────────────────────────────────
            Positioned.fill(
              child: IndexedStack(index: navIndex, children: screens),
            ),

            // ── Hamburger — top left ───────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: LiquidGlassIconButton(
                icon: Icons.menu_rounded,
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),

            // ── Coin badge — top right ─────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              right: 16,
              child: const CoinBadge(),
            ),

            // ── Backdrop blur when quick-add is open ───────────────────────
            if (_showQuickAdd)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: GestureDetector(
                      onTap: _closeQuickAdd,
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Quick-add panel — sits just above the keyboard ─────────────
            if (_showQuickAdd)
              Positioned(
                bottom: keyboardHeight,
                left: 0,
                right: 0,
                child: QuickAddPanel(
                  accentColor: settings.accentColor,
                  isDark: settings.isDarkMode,
                  onClose: _closeQuickAdd,
                ),
              ),
          ],
        ),
        bottomNavigationBar: _showQuickAdd
            ? null // hide nav bar while quick-add is open
            : _GlassBottomBar(
                navIndex: navIndex,
                palette: palette,
                onSelect: (i) =>
                    ref.read(navIndexProvider.notifier).state = i,
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _showQuickAdd
            ? null
            : _GlassFab(
                accent: settings.accentColor,
                onTap: _openQuickAdd,
              ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({
    required this.navIndex,
    required this.palette,
    required this.onSelect,
  });

  final int navIndex;
  final GlassPalette palette;
  final ValueChanged<int> onSelect;

  // Two tabs only — Quests and Shop. The FAB sits between them.
  static const _items = [
    (Icons.auto_stories_outlined, Icons.auto_stories, 'Quests'),
    (Icons.storefront_outlined, Icons.storefront, 'Shop'),
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
              const fabGapFraction = 0.22;
              final sideWidth =
                  constraints.maxWidth * (1 - fabGapFraction) / 2;
              return Stack(
                children: [
                  // Animated selection highlight
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: navIndex == 0
                        ? sideWidth * 0.1
                        : constraints.maxWidth - sideWidth * 1.1,
                    top: 6,
                    bottom: 6,
                    width: sideWidth * 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.accent.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tab buttons
                  Row(
                    children: [
                      SizedBox(
                        width: sideWidth,
                        child: _TabItem(
                          icon: _items[0].$1,
                          iconSelected: _items[0].$2,
                          label: _items[0].$3,
                          selected: navIndex == 0,
                          palette: palette,
                          onTap: () => onSelect(0),
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth * fabGapFraction),
                      SizedBox(
                        width: sideWidth,
                        child: _TabItem(
                          icon: _items[1].$1,
                          iconSelected: _items[1].$2,
                          label: _items[1].$3,
                          selected: navIndex == 1,
                          palette: palette,
                          onTap: () => onSelect(1),
                        ),
                      ),
                    ],
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconSelected;
  final String label;
  final bool selected;
  final GlassPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? iconSelected : icon,
              color: selected ? palette.accent : palette.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? palette.accent : palette.textMuted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _GlassFab extends StatefulWidget {
  const _GlassFab({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  State<_GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<_GlassFab>
    with SingleTickerProviderStateMixin {
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
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
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
            border:
                Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
