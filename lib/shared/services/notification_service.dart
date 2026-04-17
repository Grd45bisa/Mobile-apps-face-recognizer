import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/app_models.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> scheduleReminder(ReminderEvent event) async {
    if (!_initialized) return;
    await cancelReminder(event);

    for (final offset in event.reminderOffsetsInMinutes) {
      final notifTime =
          event.startDateTime.subtract(Duration(minutes: offset));
      if (notifTime.isBefore(DateTime.now())) continue;

      final id = event.id.hashCode ^ offset;
      final body = offset == 0 ? 'Sedang berlangsung' : '$offset menit lagi';

      await _plugin.zonedSchedule(
        id,
        event.title,
        body,
        tz.TZDateTime.from(notifTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders',
            'Pengingat',
            channelDescription: 'Notifikasi pengingat acara',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelReminder(ReminderEvent event) async {
    if (!_initialized) return;
    for (final offset in event.reminderOffsetsInMinutes) {
      await _plugin.cancel(event.id.hashCode ^ offset);
    }
  }
}
