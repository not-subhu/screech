import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  static const _accentChoices = [
    AppColors.defaultAccent, // crimson
    AppColors.sakura,
    AppColors.mint,
    AppColors.coinGold,
    Color(0xFF7C5CFF), // violet
    Color(0xFF4FA6FF), // sky
    Color(0xFFFF9A6F), // peach
    Color(0xFF50C878), // emerald
  ];

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState
    extends ConsumerState<PersonalizationScreen> {
  late TextEditingController _quoteCtrl;
  late TextEditingController _subtitleCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _quoteCtrl = TextEditingController(text: s.headerQuote);
    _subtitleCtrl = TextEditingController(text: s.headerSubtitle);
  }

  /// Sync text controllers whenever the provider state changes (e.g. after
  /// async _load() finishes or another notifier method updates the values).
  /// Only update when the text actually differs so we don't clobber the cursor.
  void _syncControllers(AppSettings s) {
    if (_quoteCtrl.text != s.headerQuote) {
      _quoteCtrl.value = _quoteCtrl.value.copyWith(text: s.headerQuote);
    }
    if (_subtitleCtrl.text != s.headerSubtitle) {
      _subtitleCtrl.value =
          _subtitleCtrl.value.copyWith(text: s.headerSubtitle);
    }
  }

  @override
  void dispose() {
    _quoteCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);

    // Keep controllers in sync if settings load asynchronously after init.
    ref.listen(settingsProvider, (_, next) => _syncControllers(next));

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
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

            // ── Appearance ───────────────────────────────────────────────────
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

            // ── Accent color ─────────────────────────────────────────────────
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
              children: PersonalizationScreen._accentChoices
                  .map((c) => _ColorSwatch(
                        color: c,
                        selected: c.value == settings.accentColor.value,
                        onTap: () => notifier.setAccent(c),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 28),

            // ── Header style ─────────────────────────────────────────────────
            _SectionLabel('HEADER STYLE', palette),
            const SizedBox(height: 4),
            Text(
              'Background shown in the hero area on all screens.',
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
                    customPhotoPath: settings.customPhotoPath,
                    onTap: () async {
                      if (style == HeaderStyle.photo) {
                        // Launch image picker
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (picked != null && context.mounted) {
                          // Copy to app documents for persistence
                          final docs = await getApplicationDocumentsDirectory();
                          final dest = '${docs.path}/custom_header.jpg';
                          await File(picked.path).copy(dest);
                          notifier.setCustomPhotoPath(dest);
                          notifier.setHeaderStyle(HeaderStyle.photo);
                        }
                      } else {
                        notifier.setHeaderStyle(style);
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // ── Header quote ─────────────────────────────────────────────────
            _SectionLabel('HEADER QUOTE', palette),
            const SizedBox(height: 4),
            Text(
              'The text shown over the hero image on the Quests screen.',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 12),
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Main quote',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _quoteCtrl,
                    style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    decoration: _inputDec(
                        'e.g. Keep going.', palette, settings.accentColor),
                    onChanged: notifier.setHeaderQuote,
                  ),
                  const SizedBox(height: 12),
                  Text('Subtitle',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _subtitleCtrl,
                    style:
                        TextStyle(color: palette.textPrimary, fontSize: 14),
                    decoration: _inputDec(
                        'e.g. Discipline today, freedom tomorrow.',
                        palette,
                        settings.accentColor),
                    onChanged: notifier.setHeaderSubtitle,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _quoteCtrl.text = AppSettings.defaults.headerQuote;
                      _subtitleCtrl.text =
                          AppSettings.defaults.headerSubtitle;
                      notifier.setHeaderQuote(
                          AppSettings.defaults.headerQuote);
                      notifier.setHeaderSubtitle(
                          AppSettings.defaults.headerSubtitle);
                    },
                    child: Text(
                      'Reset to default',
                      style: TextStyle(
                          fontSize: 12,
                          color: palette.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Glass intensity ──────────────────────────────────────────────
            _SectionLabel('GLASS INTENSITY', palette),
            const SizedBox(height: 4),
            Text(
              'Controls the blur and frost on every glass surface.',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 8),
            LiquidGlass(
              borderRadius: 20,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
            const SizedBox(height: 10),
            LiquidGlass(
              borderRadius: 20,
              shimmer: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: settings.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live preview — this card uses your current settings.',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── More to come ─────────────────────────────────────────────────
            _SectionLabel('COMING SOON', palette),
            const SizedBox(height: 10),
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  _ComingSoonRow(
                    icon: Icons.font_download_outlined,
                    label: 'Font & text size',
                    sub: 'Choose your preferred reading size',
                    palette: palette,
                  ),
                  _Divider(palette),
                  _ComingSoonRow(
                    icon: Icons.style_outlined,
                    label: 'Card style',
                    sub: 'Compact list vs expanded cards',
                    palette: palette,
                  ),
                  _Divider(palette),
                  _ComingSoonRow(
                    icon: Icons.translate_rounded,
                    label: 'Quote language',
                    sub: 'Japanese, Korean, or keep English',
                    palette: palette,
                  ),
                  _Divider(palette),
                  _ComingSoonRow(
                    icon: Icons.notifications_active_outlined,
                    label: 'Notification sound',
                    sub: 'Pick a sound for quest reminders',
                    palette: palette,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(
          String hint, GlassPalette palette, Color accent) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
        filled: true,
        fillColor: palette.bgSecondary.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

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
          color: selected
              ? palette.accent.withOpacity(0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: palette.accent.withOpacity(0.6))
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? palette.accent : palette.textMuted,
                size: 20),
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
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.55),
                      blurRadius: 16,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _HeaderStyleThumb extends StatelessWidget {
  const _HeaderStyleThumb({
    required this.style,
    required this.selected,
    required this.onTap,
    this.customPhotoPath,
  });

  final HeaderStyle style;
  final bool selected;
  final VoidCallback onTap;
  final String? customPhotoPath;

  Gradient get _gradient {
    switch (style) {
      case HeaderStyle.photo:
        return const LinearGradient(
            colors: [Color(0xFF3A2566), Color(0xFF120B1C)]);
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
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.15),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (style == HeaderStyle.photo && customPhotoPath != null)
                Image.file(File(customPhotoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/header_hero.webp',
                        fit: BoxFit.cover))
              else if (style == HeaderStyle.photo)
                Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/images/header_hero.webp',
                      fit: BoxFit.cover),
                  const ColoredBox(color: Color(0x44000000)),
                  const Center(
                    child: Icon(Icons.add_photo_alternate_rounded,
                        color: Colors.white70, size: 22),
                  ),
                ])
              else
                DecoratedBox(
                    decoration: BoxDecoration(gradient: _gradient)),
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
                  child: Icon(Icons.check_circle,
                      color: Colors.white, size: 16),
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
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                )),
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
          child:
              Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String sub;
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12, color: palette.textMuted)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Soon',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.palette);
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) => Divider(
      height: 1, thickness: 1, color: palette.border.withOpacity(0.5),
      indent: 50, endIndent: 16);
}
