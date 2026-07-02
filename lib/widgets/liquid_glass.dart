import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Core "liquid glass" surface used throughout Screech's chrome: a frosted
/// backdrop blur, a soft translucent tint, a light-catching border, and an
/// optional slow-moving shimmer sweep for that "liquid" quality. Blur and
/// tint intensity read from Personalization settings by default so every
/// glass surface in the app breathes together.
class LiquidGlass extends ConsumerWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.blurOverride,
    this.opacityOverride,
    this.borderColor,
    this.shimmer = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? blurOverride;
  final double? opacityOverride;
  final Color? borderColor;
  final bool shimmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);
    final blur = blurOverride ?? settings.glassBlur;
    final opacity = opacityOverride ?? settings.glassOpacity;
    final tint = settings.isDarkMode ? Colors.white : Colors.white;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withOpacity((opacity + 0.08).clamp(0.0, 1.0)),
            tint.withOpacity((opacity * 0.35).clamp(0.0, 1.0)),
          ],
        ),
        border: Border.all(
          color: borderColor ?? palette.glassBorder,
          width: 1.2,
        ),
      ),
      child: child,
    );

    if (shimmer) {
      content = _ShimmerSweep(child: content);
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: palette.glassShadow.withOpacity(settings.isDarkMode ? 0.32 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// A slow diagonal highlight that sweeps across a glass surface on a loop,
/// giving it a subtle "liquid" catch-the-light quality.
class _ShimmerSweep extends StatefulWidget {
  const _ShimmerSweep({required this.child});

  final Widget child;

  @override
  State<_ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<_ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return LayoutBuilder(builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final travel = w * 1.6;
                    final dx = -travel / 2 + _ctrl.value * travel;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Container(
                          width: w * 0.28,
                          height: constraints.maxHeight * 2.2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.14),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A circular glass button with a press-scale animation — the app's
/// standard tappable glass control (hamburger, back arrows, etc).
class LiquidGlassIconButton extends ConsumerStatefulWidget {
  const LiquidGlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  ConsumerState<LiquidGlassIconButton> createState() =>
      _LiquidGlassIconButtonState();
}

class _LiquidGlassIconButtonState extends ConsumerState<LiquidGlassIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.86).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final iconColor = widget.color ??
        (settings.isDarkMode ? Colors.white : const Color(0xFF241832));

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
        child: LiquidGlass(
          borderRadius: widget.size / 2,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
