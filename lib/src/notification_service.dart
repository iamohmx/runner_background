import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'runner_background_config.dart';

/// Service for managing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static RunnerBackgroundConfig? _config;
  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize(RunnerBackgroundConfig config) async {
    if (_isInitialized) return;

    _config = config;

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }

    _isInitialized = true;
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    final notificationConfig = _config!.notificationConfig;

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationConfig.channelId,
      notificationConfig.channelName,
      description: notificationConfig.channelDescription,
      importance: notificationConfig.importance,
      sound: notificationConfig.sound != null
          ? RawResourceAndroidNotificationSound(notificationConfig.sound!)
          : null,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request permissions for iOS
  static Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Show a notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized || _config == null) {
      throw Exception('NotificationService not initialized');
    }

    final notificationConfig = _config!.notificationConfig;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      notificationConfig.channelId,
      notificationConfig.channelName,
      channelDescription: notificationConfig.channelDescription,
      importance: notificationConfig.importance,
      priority: notificationConfig.priority,
      icon: notificationConfig.icon,
      sound: notificationConfig.sound != null
          ? RawResourceAndroidNotificationSound(notificationConfig.sound!)
          : null,
      actions: notificationConfig.actions,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show a scheduled notification
  static Future<void> showScheduledNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized || _config == null) {
      throw Exception('NotificationService not initialized');
    }

    final notificationConfig = _config!.notificationConfig;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      notificationConfig.channelId,
      notificationConfig.channelName,
      channelDescription: notificationConfig.channelDescription,
      importance: notificationConfig.importance,
      priority: notificationConfig.priority,
      icon: notificationConfig.icon,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a notification
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (_config?.onNotificationTapped != null) {
      _config!.onNotificationTapped!(response.payload);
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    return true; // iOS handles this at system level
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
