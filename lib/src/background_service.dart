import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'runner_background_config.dart';
import 'notification_service.dart';

/// Background service for running tasks in the background
class BackgroundService {
  static RunnerBackgroundConfig? _config;
  static bool _isInitialized = false;

  /// Initialize the background service
  static Future<void> initialize(RunnerBackgroundConfig config) async {
    if (_isInitialized) return;

    _config = config;

    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Mark service as active
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('runner_background_active', true);

    _isInitialized = true;
  }

  /// Stop the background service
  static Future<void> stop() async {
    await Workmanager().cancelAll();

    // Mark service as inactive
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('runner_background_active', false);
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('runner_background_active') ?? false;
  }

  /// Register a periodic task
  static Future<void> registerPeriodicTask({
    required String taskName,
    required String taskTag,
    Duration frequency = const Duration(minutes: 15),
    Duration? initialDelay,
    Constraints? constraints,
  }) async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskTag,
      frequency: frequency,
      initialDelay: initialDelay ?? const Duration(seconds: 10),
      constraints: constraints ??
          Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: true,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
    );
  }

  /// Register a one-time task
  static Future<void> registerOneOffTask({
    required String taskName,
    required String taskTag,
    Duration? initialDelay,
    Constraints? constraints,
  }) async {
    await Workmanager().registerOneOffTask(
      taskName,
      taskTag,
      initialDelay: initialDelay ?? const Duration(seconds: 0),
      constraints: constraints,
    );
  }

  /// Cancel a task by tag
  static Future<void> cancelByTag(String tag) async {
    await Workmanager().cancelByTag(tag);
  }

  /// Cancel a task by unique name
  static Future<void> cancelByUniqueName(String uniqueName) async {
    await Workmanager().cancelByUniqueName(uniqueName);
  }

  /// Execute custom background task
  static Future<void> executeCustomTask() async {
    if (_config?.onBackgroundTask != null) {
      try {
        await _config!.onBackgroundTask!();
      } catch (e) {
        if (kDebugMode) {
          print('Error executing custom background task: $e');
        }
      }
    }
  }

  /// Show notification from background
  static Future<void> showBackgroundNotification({
    String? title,
    String? body,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final configTitle =
        prefs.getString('notification_title') ?? 'Background Service';
    final configBody = prefs.getString('notification_body') ??
        'Your app is running in the background';

    // Since we're in background, we need to use a different approach
    // We'll store the notification request and show it when app comes to foreground
    final notifications = prefs.getStringList('pending_notifications') ?? [];
    notifications
        .add('${title ?? configTitle}|${body ?? configBody}|${payload ?? ''}');
    await prefs.setStringList('pending_notifications', notifications);
  }

  /// Get pending notifications from background
  static Future<List<Map<String, String>>> getPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('pending_notifications') ?? [];

    return notifications.map((notification) {
      final parts = notification.split('|');
      return {
        'title': parts[0],
        'body': parts[1],
        'payload': parts.length > 2 ? parts[2] : '',
      };
    }).toList();
  }

  /// Clear pending notifications
  static Future<void> clearPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_notifications');
  }

  /// Save configuration to shared preferences
  static Future<void> saveConfig(RunnerBackgroundConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'notification_title', config.notificationConfig.defaultTitle);
    await prefs.setString(
        'notification_body', config.notificationConfig.defaultBody);
    await prefs.setString(
        'notification_channel_id', config.notificationConfig.channelId);
    await prefs.setString(
        'notification_channel_name', config.notificationConfig.channelName);
  }
}

/// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) {
      print('Background task executed: $task');
    }

    try {
      // Execute the background task
      await BackgroundService.executeCustomTask();

      // Show notification if configured
      await BackgroundService.showBackgroundNotification(
        title: inputData?['title'],
        body: inputData?['body'],
        payload: inputData?['payload'],
      );

      // Update last execution time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_execution_time', DateTime.now().millisecondsSinceEpoch);

      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Background task error: $e');
      }
      return Future.value(false);
    }
  });
}

/// Utility class for background service management
class BackgroundServiceManager {
  static Timer? _foregroundTimer;

  /// Start monitoring for foreground/background state
  static void startForegroundMonitoring() {
    _foregroundTimer?.cancel();
    _foregroundTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkAndShowPendingNotifications();
    });
  }

  /// Stop monitoring for foreground/background state
  static void stopForegroundMonitoring() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
  }

  /// Check and show pending notifications
  static Future<void> _checkAndShowPendingNotifications() async {
    final pendingNotifications =
        await BackgroundService.getPendingNotifications();

    for (final notification in pendingNotifications) {
      await NotificationService.showNotification(
        title: notification['title']!,
        body: notification['body']!,
        payload: notification['payload'],
      );
    }

    if (pendingNotifications.isNotEmpty) {
      await BackgroundService.clearPendingNotifications();
    }
  }

  /// Get background service statistics
  static Future<Map<String, dynamic>> getServiceStats() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = await BackgroundService.isRunning();
    final lastExecution = prefs.getInt('last_execution_time') ?? 0;
    final pendingNotifications =
        await BackgroundService.getPendingNotifications();

    return {
      'isRunning': isRunning,
      'lastExecution': DateTime.fromMillisecondsSinceEpoch(lastExecution),
      'pendingNotificationsCount': pendingNotifications.length,
    };
  }
}
