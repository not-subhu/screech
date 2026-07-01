import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    const channel = AndroidNotificationChannel(
      'quest_reminders',
      'Quest Reminders',
      description: 'Reminders for tasks and habits due soon.',
      importance: Importance.high,
    );
    await androidImpl?.createNotificationChannel(channel);
  }

  /// Schedules a one-off reminder at [scheduledTime] for a task/habit.
  /// Returns the notification id used, so it can be cancelled/rescheduled later.
  static Future<int> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quest_reminders',
          'Quest Reminders',
          channelDescription: 'Reminders for tasks and habits due soon.',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF6FA5),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return id;
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quest_reminders',
          'Quest Reminders',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF6FA5),
        ),
      ),
    );
  }
}
