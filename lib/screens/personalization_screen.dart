import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

class PersonalizationScreen extends ConsumerWidget {
  const PersonalizationScreen({super.key});

  static const _accentChoices = [
    AppColors.defaultAccent, // crimson
    AppColors.sakura,
    AppColors.mint,
    AppColors.coinGold,
    Color(0xFF7C5CFF), // violet
    Color(0xFF4FA6FF), // sky
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
          children: [
            Row(
              children: [
                LiquidGlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                  size: 40,
                  iconSize: 18,
                ),
                const SizedBox(width: 14),
                Text(
                  'Personalization',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionLabel('APPEARANCE', palette),
            const SizedBox(height: 10),
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      selected: settings.isDarkMode,
                      palette: palette,
                      onTap: () => notifier.setDarkMode(true),
                    ),
                  ),
                  Expanded(
                    child: _ModeButton(
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      selected: !settings.isDarkMode,
                      palette: palette,
                      onTap: () => notifier.setDarkMode(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('ACCENT COLOR', palette),
            const SizedBox(height: 4),
            Text(
              'Colors the + button, tab icons, and the completion ring.',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _accentChoices
                  .map((c) => _ColorSwatch(
                        color: c,
                        selected: c.value == settings.accentColor.value,
                        onTap: () => notifier.setAccent(c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            _SectionLabel('HEADER STYLE', palette),
            const SizedBox(height: 4),
            Text(
              'What shows behind "Keep going" on the Quests screen.',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: HeaderStyle.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final style = HeaderStyle.values[i];
                  return _HeaderStyleThumb(
                    style: style,
                    selected: style == settings.headerStyle,
                    onTap: () => notifier.setHeaderStyle(style),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('GLASS INTENSITY', palette),
            const SizedBox(height: 4),
            Text(
              'Controls the blur and frost on every glass surface.',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 8),
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  _SliderRow(
                    label: 'Blur',
                    value: settings.glassBlur,
                    min: 4,
                    max: 32,
                    accent: settings.accentColor,
                    palette: palette,
                    onChanged: notifier.setGlassBlur,
                  ),
                  _SliderRow(
                    label: 'Frost opacity',
                    value: settings.glassOpacity,
                    min: 0.04,
                    max: 0.4,
                    accent: settings.accentColor,
                    palette: palette,
                    onChanged: notifier.setGlassOpacity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            LiquidGlass(
              borderRadius: 20,
              shimmer: true,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: settings.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live preview — this card uses your current settings.',
                      style: TextStyle(fontSize: 12, color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: palette.textMuted,
        ),
      );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final GlassPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? palette.accent.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: palette.accent.withOpacity(0.6))
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? palette.accent : palette.textMuted, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? palette.accent : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: selected ? 52 : 44,
        height: selected ? 52 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.9 : 0.25),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.55), blurRadius: 16, spreadRadius: 1)]
              : [],
        ),
        child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
      ),
    );
  }
}

class _HeaderStyleThumb extends StatelessWidget {
  const _HeaderStyleThumb({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final HeaderStyle style;
  final bool selected;
  final VoidCallback onTap;

  Gradient get _gradient {
    switch (style) {
      case HeaderStyle.photo:
        return const LinearGradient(colors: [Color(0xFF3A2566), Color(0xFF120B1C)]);
      case HeaderStyle.sakuraDusk:
        return const LinearGradient(
          colors: [Color(0xFFFF6FA5), Color(0xFF6A3E9C), Color(0xFF1A1025)],
        );
      case HeaderStyle.cursedViolet:
        return const LinearGradient(
          colors: [Color(0xFF120B1C), Color(0xFF3A2566), Color(0xFF6A1B2F)],
        );
      case HeaderStyle.mintDawn:
        return const LinearGradient(
          colors: [Color(0xFF7DE0D3), Color(0xFF2D6E63), Color(0xFF12251F)],
        );
    }
  }

  String get _label {
    switch (style) {
      case HeaderStyle.photo:
        return 'Photo';
      case HeaderStyle.sakuraDusk:
        return 'Sakura Dusk';
      case HeaderStyle.cursedViolet:
        return 'Cursed Violet';
      case HeaderStyle.mintDawn:
        return 'Mint Dawn';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.15),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (style == HeaderStyle.photo)
                Image.asset('assets/images/header_hero.webp', fit: BoxFit.cover)
              else
                DecoratedBox(decoration: BoxDecoration(gradient: _gradient)),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.palette,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final Color accent;
  final GlassPalette palette;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            Text(
              value.toStringAsFixed(value < 1 ? 2 : 0),
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withOpacity(0.2),
            inactiveTrackColor: palette.border,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
