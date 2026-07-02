import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/db_service.dart';
import 'services/notification_service.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — intentional UX choice for a task app.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DbService.open();
  await NotificationService.init();

  runApp(const ProviderScope(child: ScreechApp()));
}

class ScreechApp extends ConsumerWidget {
  const ScreechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // System UI (status bar / nav bar) follows the user's dark/light choice.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            settings.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            settings.isDarkMode ? AppColors.bgDeep : AppColors.bgLight,
        systemNavigationBarIconBrightness:
            settings.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Screech',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(accent: settings.accentColor, isDark: settings.isDarkMode),
      home: const AppShell(),
    );
  }
}
