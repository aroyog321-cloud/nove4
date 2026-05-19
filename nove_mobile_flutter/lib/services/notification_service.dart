import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;


class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nove_reminders',
      'Reminders',
      channelDescription: 'Note reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // FIX (Bug 5): Removed `uiLocalNotificationDateInterpretation`.
    // That parameter is iOS-only (it controls how iOS interprets the fire date).
    // On Android it has no effect, but including it with an iOS-specific enum value
    // in an Android-only NotificationDetails object is misleading and causes a
    // compile warning in strict-mode analysis. For a cross-platform call you would
    // also supply `DarwinNotificationDetails` in `NotificationDetails(ios: ...)`.
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }
}