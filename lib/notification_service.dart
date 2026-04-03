import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      // Try to set local location, but don't fail if it's already set or errors
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); 
      } catch (_) {
        // Already set or invalid
      }
    } catch (e) {
      debugPrint("Timezone initialization error: $e");
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const fln.DarwinInitializationSettings initializationSettingsDarwin = 
        fln.DarwinInitializationSettings();

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    if (!kIsWeb) {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
            // Handle notification tap
        },
      );

      // Explicitly create channels for FCM background compatibility
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(const fln.AndroidNotificationChannel(
          'instant_alerts',
          'Instant Alerts',
          description: 'Immediate notifications for user actions',
          importance: fln.Importance.max,
        ));
        
        await androidPlugin.createNotificationChannel(const fln.AndroidNotificationChannel(
          'medicine_reminders',
          'Medicine Reminders',
          description: 'Daily reminders for medication',
          importance: fln.Importance.max,
        ));
      }
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) {
      debugPrint("Web Warning: Local notifications are not fully supported on Web. Use a mobile device for full alarm functionality.");
      // We could implement a simple HTML5 Notification here if needed.
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'medicine_reminders', 
            'Medicine Reminders', 
            channelDescription: 'Daily reminders for medication',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            fullScreenIntent: true, // Key for better 'alarm' feel on Android
          ),
          iOS: fln.DarwinNotificationDetails(
             presentAlert: true,
             presentBadge: true,
             presentSound: true,
          ),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
      debugPrint("Scheduled notification $id for $hour:$minute");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      debugPrint("Notification: $title - $body");
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'instant_alerts', 
            'Instant Alerts', 
            channelDescription: 'Immediate notifications for user actions',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(
             presentAlert: true,
             presentBadge: true,
             presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint("Cancelled notification $id");
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
     debugPrint("Cancelled ALL notifications");
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
  
  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
    
    // Request notification permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();
    
    // Request exact alarm permission (Android 14+)
    await androidPlugin?.requestExactAlarmsPermission();
  }
}
