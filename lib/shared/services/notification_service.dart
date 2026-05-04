import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/app_models.dart';

/// Channel untuk notifikasi sistem bar.
/// Public agar NotificationProvider bisa memilih channel yang sesuai.
enum NotifChannel {
  reminders(
    'reminders',
    'Pengingat',
    'Notifikasi pengingat acara kalender',
    Importance.high,
    Priority.high,
  ),
  attendance(
    'attendance',
    'Absensi',
    'Pengingat check-in dan check-out harian',
    Importance.high,
    Priority.high,
  ),
  tracker(
    'tracker',
    'Tracker',
    'Pengingat pencatatan aktivitas harian',
    Importance.defaultImportance,
    Priority.defaultPriority,
  ),
  system(
    'system',
    'Sistem',
    'Notifikasi umum aplikasi',
    Importance.defaultImportance,
    Priority.defaultPriority,
  );

  const NotifChannel(
      this.channelId, this.channelName, this.channelDesc,
      this.importance, this.priority);

  final String channelId;
  final String channelName;
  final String channelDesc;
  final Importance importance;
  final Priority priority;
}

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

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ (API 33) memerlukan izin eksplisit POST_NOTIFICATIONS
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Show immediate system-bar notification ────────────────────────────────

  /// Tampilkan notifikasi langsung di notification bar HP.
  /// Dipakai oleh NotificationProvider setiap kali ada item baru yang
  /// belum pernah ditampilkan ke OS.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotifChannel channel = NotifChannel.system,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.channelId,
          channel.channelName,
          channelDescription: channel.channelDesc,
          importance: channel.importance,
          priority: channel.priority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Scheduled reminders ───────────────────────────────────────────────────

  Future<void> scheduleReminder(ReminderEvent event) async {
    if (!_initialized) return;
    await cancelReminder(event);

    for (final offset in event.reminderOffsetsInMinutes) {
      final notifTime =
          event.startDateTime.subtract(Duration(minutes: offset));
      if (notifTime.isBefore(DateTime.now())) continue;

      final id = event.id.hashCode ^ offset;
      final body = offset == 0 ? 'Sedang berlangsung' : '$offset menit lagi';

      final ch = NotifChannel.reminders;
      await _plugin.zonedSchedule(
        id,
        event.title,
        body,
        tz.TZDateTime.from(notifTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            ch.channelId,
            ch.channelName,
            channelDescription: ch.channelDesc,
            importance: ch.importance,
            priority: ch.priority,
          ),
          iOS: const DarwinNotificationDetails(
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
