library runner_background;

import 'package:runner_background/runner_background.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'src/background_service.dart';
export 'src/notification_service.dart';
export 'src/runner_background_config.dart';

/// Main entry point for the runner_background library
class RunnerBackground {
  static const String _taskName = 'runner_background_task';
  static const String _taskTag = 'runner_background_notification';

  /// Initialize the background service
  static Future<void> initialize({
    required RunnerBackgroundConfig config,
  }) async {
    // Initialize notification service
    await NotificationService.initialize(config);

    // Initialize background service
    await BackgroundService.initialize(config);

    // Register background task
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskTag,
      frequency: config.frequency,
      initialDelay: config.initialDelay,
      constraints: config.constraints,
    );
  }

  /// Stop the background service
  static Future<void> stop() async {
    await Workmanager().cancelByTag(_taskTag);
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await NotificationService.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Check if background service is running
  static Future<bool> isRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('runner_background_active') ?? false;
  }
}
