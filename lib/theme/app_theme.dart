import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Questify design tokens.
///
/// Direction: JRPG status-screen / quest-log aesthetic — think the party
/// menu in a Persona-style game — rather than generic "pastel anime app."
/// Deep indigo-violet base, sakura pink + mint cyan dual accent, coin-gold
/// for currency. Rounded display face for personality, clean sans for body.
class AppColors {
  AppColors._();

  // Base
  static const bg = Color(0xFF1A1025);
  static const bgDeep = Color(0xFF120B1C);
  static const surface = Color(0xFF2D1B4E);
  static const surfaceRaised = Color(0xFF3A2566);
  static const surfaceBorder = Color(0xFF4A3370);

  // Accents
  static const sakura = Color(0xFFFF6FA5);
  static const sakuraDeep = Color(0xFFE0518A);
  static const mint = Color(0xFF7DE0D3);
  static const mintDeep = Color(0xFF4FC4B4);
  static const coinGold = Color(0xFFFFC857);
  static const coinGoldDeep = Color(0xFFE0A93B);
  static const urgentRed = Color(0xFFFF5C7A);

  // Text
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

ThemeData buildQuestifyTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.sakura,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.sakura,
      secondary: AppColors.mint,
      tertiary: AppColors.coinGold,
      surface: AppColors.surface,
      error: AppColors.urgentRed,
    ),
    textTheme: AppText.textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.textTheme.displayMedium,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: const CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.sakura,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgDeep,
      selectedItemColor: AppColors.sakura,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppText.textTheme.labelSmall,
      unselectedLabelStyle: AppText.textTheme.labelSmall,
    ),
    dividerColor: AppColors.surfaceBorder,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  );
}