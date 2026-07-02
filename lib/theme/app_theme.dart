import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screech design tokens.
///
/// The app now runs on a "liquid glass" chrome layer (drawer, nav bar, FAB,
/// hero header controls, personalization screen) built on top of this
/// palette. Existing screens (Habits/Shop/Stats) keep using the original
/// dark JRPG palette below unchanged, so none of those fields were removed
/// — only new dynamic (light/dark aware) tokens were added alongside them.
class AppColors {
  AppColors._();

  // Base (dark)
  static const bg = Color(0xFF1A1025);
  static const bgDeep = Color(0xFF120B1C);
  static const surface = Color(0xFF2D1B4E);
  static const surfaceRaised = Color(0xFF3A2566);
  static const surfaceBorder = Color(0xFF4A3370);

  // Base (light) — used when Personalization → Appearance is set to Light.
  static const bgLight = Color(0xFFF5F0FB);
  static const bgDeepLight = Color(0xFFEAE1F7);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedLight = Color(0xFFF2EAFB);
  static const surfaceBorderLight = Color(0xFFDACEEF);
  static const textPrimaryLight = Color(0xFF241832);
  static const textSecondaryLight = Color(0xFF5B4B78);
  static const textMutedLight = Color(0xFF8B7BA8);

  // Accents
  static const sakura = Color(0xFFFF6FA5);
  static const sakuraDeep = Color(0xFFE0518A);
  static const mint = Color(0xFF7DE0D3);
  static const mintDeep = Color(0xFF4FC4B4);
  static const coinGold = Color(0xFFFFC857);
  static const coinGoldDeep = Color(0xFFE0A93B);
  static const urgentRed = Color(0xFFFF5C7A);

  /// Default accent for a fresh install (crimson — matches Screech's
  /// scribble logo mark). User can change this in Personalization.
  static const defaultAccent = Color(0xFFE23744);

  // Text (dark)
  static const textPrimary = Color(0xFFF4EBFF);
  static const textSecondary = Color(0xFFB8A8D9);
  static const textMuted = Color(0xFF7C6B9C);

  // Priority tags
  static const priorityLow = Color(0xFF7DE0D3);
  static const priorityMedium = Color(0xFFFFC857);
  static const priorityHigh = Color(0xFFFF9A6F);
  static const priorityUrgent = Color(0xFFFF5C7A);

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceRaised, surface],
  );

  static const sakuraGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sakura, sakuraDeep],
  );

  static const coinGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coinGold, coinGoldDeep],
  );

  /// The "rarity stripe" gradient used on the edge of quest cards —
  /// the app's signature visual motif.
  static const rarityStripe = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sakura, mint, coinGold],
  );
}

class AppText {
  AppText._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.baloo2(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.baloo2(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.baloo2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.4,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      );
}

/// Resolves the right colors for the current appearance (dark/light) and
/// the user's chosen accent, so glass widgets never hardcode a palette.
class GlassPalette {
  const GlassPalette({required this.isDark, required this.accent});

  final bool isDark;
  final Color accent;

  Color get bg => isDark ? AppColors.bgDeep : AppColors.bgLight;
  Color get bgSecondary => isDark ? AppColors.bg : AppColors.bgDeepLight;
  Color get surface => isDark ? AppColors.surface : AppColors.surfaceLight;
  Color get surfaceRaised =>
      isDark ? AppColors.surfaceRaised : AppColors.surfaceRaisedLight;
  Color get border =>
      isDark ? AppColors.surfaceBorder : AppColors.surfaceBorderLight;
  Color get textPrimary =>
      isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textSecondary =>
      isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.textMutedLight;

  /// Border used on frosted-glass panels — brighter/whiter in dark mode to
  /// read as a light-catching edge, softer in light mode.
  Color get glassBorder =>
      isDark ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.7);

  Color get glassShadow => isDark ? Colors.black : Colors.black.withOpacity(0.5);
}

ThemeData buildAppTheme({required Color accent, required bool isDark}) {
  final palette = GlassPalette(isDark: isDark, accent: accent);
  final base = isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  final textTheme = isDark
      ? AppText.textTheme
      : AppText.textTheme.apply(
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        );

  return base.copyWith(
    scaffoldBackgroundColor: palette.bg,
    primaryColor: accent,
    colorScheme:
        (isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
      primary: accent,
      secondary: AppColors.mint,
      tertiary: AppColors.coinGold,
      surface: palette.surface,
      error: AppColors.urgentRed,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.displayMedium,
      iconTheme: IconThemeData(color: palette.textPrimary),
    ),
    cardTheme: CardTheme(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
    dividerColor: palette.border,
    iconTheme: IconThemeData(color: palette.textPrimary),
  );
}

/// Legacy helper kept for compatibility — builds the original always-dark
/// Screech theme with the default accent.
ThemeData buildQuestifyTheme() =>
    buildAppTheme(accent: AppColors.defaultAccent, isDark: true);
