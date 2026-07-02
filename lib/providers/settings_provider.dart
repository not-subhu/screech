import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Background treatments for the screen hero headers.
enum HeaderStyle { photo, sakuraDusk, cursedViolet, mintDawn }

@immutable
class AppSettings {
  const AppSettings({
    required this.accentColor,
    required this.isDarkMode,
    required this.headerStyle,
    required this.glassBlur,
    required this.glassOpacity,
    required this.headerQuote,
    required this.headerSubtitle,
    this.customPhotoPath,
  });

  final Color accentColor;
  final bool isDarkMode;
  final HeaderStyle headerStyle;

  /// Backdrop blur sigma applied to every glass surface in the app.
  final double glassBlur;

  /// Opacity of the frosted tint layered over the blur.
  final double glassOpacity;

  /// Main quote shown at the bottom of the hero header.
  final String headerQuote;

  /// Subtitle shown under the quote (supports Japanese/other scripts).
  final String headerSubtitle;

  /// Path to a user-picked custom header photo. Null when not set.
  final String? customPhotoPath;

  static const defaults = AppSettings(
    accentColor: AppColors.defaultAccent,
    isDarkMode: true,
    headerStyle: HeaderStyle.photo,
    glassBlur: 18,
    glassOpacity: 0.16,
    headerQuote: 'Keep going.',
    headerSubtitle: 'Discipline today, freedom tomorrow.',
    customPhotoPath: null,
  );

  AppSettings copyWith({
    Color? accentColor,
    bool? isDarkMode,
    HeaderStyle? headerStyle,
    double? glassBlur,
    double? glassOpacity,
    String? headerQuote,
    String? headerSubtitle,
    String? customPhotoPath,
    bool clearCustomPhoto = false,
  }) {
    assert(
      !(clearCustomPhoto && customPhotoPath != null),
      'clearCustomPhoto and customPhotoPath are mutually exclusive',
    );
    return AppSettings(
      accentColor: accentColor ?? this.accentColor,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      headerStyle: headerStyle ?? this.headerStyle,
      glassBlur: glassBlur ?? this.glassBlur,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      headerQuote: headerQuote ?? this.headerQuote,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      customPhotoPath:
          clearCustomPhoto ? null : (customPhotoPath ?? this.customPhotoPath),
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings.defaults) {
    _load();
  }

  static const _kAccent = 'screech_settings_accent';
  static const _kDark = 'screech_settings_dark';
  static const _kHeader = 'screech_settings_header';
  static const _kBlur = 'screech_settings_blur';
  static const _kOpacity = 'screech_settings_opacity';
  static const _kQuote = 'screech_settings_quote';
  static const _kSubtitle = 'screech_settings_subtitle';
  static const _kCustomPhoto = 'screech_settings_custom_photo';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final headerIndex = prefs.getInt(_kHeader);
    state = AppSettings(
      accentColor: Color(
        prefs.getInt(_kAccent) ?? AppSettings.defaults.accentColor.value,
      ),
      isDarkMode: prefs.getBool(_kDark) ?? AppSettings.defaults.isDarkMode,
      headerStyle: headerIndex != null &&
              headerIndex >= 0 &&
              headerIndex < HeaderStyle.values.length
          ? HeaderStyle.values[headerIndex]
          : AppSettings.defaults.headerStyle,
      glassBlur: prefs.getDouble(_kBlur) ?? AppSettings.defaults.glassBlur,
      glassOpacity:
          prefs.getDouble(_kOpacity) ?? AppSettings.defaults.glassOpacity,
      headerQuote:
          prefs.getString(_kQuote) ?? AppSettings.defaults.headerQuote,
      headerSubtitle:
          prefs.getString(_kSubtitle) ?? AppSettings.defaults.headerSubtitle,
      customPhotoPath: prefs.getString(_kCustomPhoto),
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccent, state.accentColor.value);
    await prefs.setBool(_kDark, state.isDarkMode);
    await prefs.setInt(_kHeader, state.headerStyle.index);
    await prefs.setDouble(_kBlur, state.glassBlur);
    await prefs.setDouble(_kOpacity, state.glassOpacity);
    await prefs.setString(_kQuote, state.headerQuote);
    await prefs.setString(_kSubtitle, state.headerSubtitle);
    if (state.customPhotoPath != null) {
      await prefs.setString(_kCustomPhoto, state.customPhotoPath!);
    } else {
      await prefs.remove(_kCustomPhoto);
    }
  }

  void setAccent(Color color) {
    state = state.copyWith(accentColor: color);
    _persist();
  }

  void setDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
    _persist();
  }

  void setHeaderStyle(HeaderStyle style) {
    state = state.copyWith(headerStyle: style);
    _persist();
  }

  void setGlassBlur(double value) {
    state = state.copyWith(glassBlur: value);
    _persist();
  }

  void setGlassOpacity(double value) {
    state = state.copyWith(glassOpacity: value);
    _persist();
  }

  void setHeaderQuote(String value) {
    state = state.copyWith(
        headerQuote: value.isEmpty ? AppSettings.defaults.headerQuote : value);
    _persist();
  }

  void setHeaderSubtitle(String value) {
    state = state.copyWith(headerSubtitle: value);
    _persist();
  }

  void setCustomPhotoPath(String? path) {
    if (path == null) {
      state = state.copyWith(clearCustomPhoto: true);
    } else {
      state = state.copyWith(customPhotoPath: path);
    }
    _persist();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
