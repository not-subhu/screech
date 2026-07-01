import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/db_service.dart';
import 'services/notification_service.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — intentional UX choice for a task app.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay to blend with our dark background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await DbService.open();
  await NotificationService.init();

  runApp(const ProviderScope(child: QuestifyApp()));
}

class QuestifyApp extends StatelessWidget {
  const QuestifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questify',
      debugShowCheckedModeBanner: false,
      theme: buildQuestifyTheme(),
      home: const AppShell(),
    );
  }
}
