import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../screens/personalization_screen.dart';
import '../theme/app_theme.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: settings.glassBlur, sigmaY: settings.glassBlur),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.bg.withOpacity(0.93),
                  palette.bgSecondary.withOpacity(0.97),
                ],
              ),
              border: Border(right: BorderSide(color: palette.glassBorder)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/logo.webp',
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Screech',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Small habits. Loud results.',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                    const SizedBox(height: 30),
                    _DrawerTile(
                      icon: Icons.palette_outlined,
                      label: 'Personalization',
                      palette: palette,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PersonalizationScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.notifications_outlined,
                      label: 'Reminders',
                      palette: palette,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _DrawerTile(
                      icon: Icons.info_outline,
                      label: 'About Screech',
                      palette: palette,
                      onTap: () {
                        Navigator.of(context).pop();
                        showAboutDialog(
                          context: context,
                          applicationName: 'Screech',
                          applicationVersion: '0.1.0',
                          applicationIcon: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/logo.webp',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      'v0.1.0 · built for one-handed chaos',
                      style: TextStyle(fontSize: 10, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatefulWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final GlassPalette palette;
  final VoidCallback onTap;

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.palette.accent.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 20, color: widget.palette.textPrimary),
            const SizedBox(width: 14),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
