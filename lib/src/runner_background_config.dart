import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configuration class for RunnerBackground
class RunnerBackgroundConfig {
  /// The frequency of background task execution
  final Duration frequency;

  /// Initial delay before starting the background task
  final Duration initialDelay;

  /// Constraints for background task execution
  final Constraints constraints;

  /// Notification settings
  final NotificationConfig notificationConfig;

  /// Callback function to execute in background
  final Future<void> Function()? onBackgroundTask;

  /// Callback function when notification is tapped
  final void Function(String?)? onNotificationTapped;

  RunnerBackgroundConfig({
    this.frequency = const Duration(minutes: 15),
    this.initialDelay = const Duration(seconds: 10),
    Constraints? constraints,
    required this.notificationConfig,
    this.onBackgroundTask,
    this.onNotificationTapped,
  }) : constraints = constraints ??
            Constraints(
              networkType: NetworkType.not_required,
              requiresBatteryNotLow: true,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false,
            );
}

/// Configuration for notifications
class NotificationConfig {
  /// Notification channel ID
  final String channelId;

  /// Notification channel name
  final String channelName;

  /// Notification channel description
  final String channelDescription;

  /// Default notification title
  final String defaultTitle;

  /// Default notification body
  final String defaultBody;

  /// Notification icon (Android)
  final String? icon;

  /// Notification sound
  final String? sound;

  /// Notification importance
  final Importance importance;

  /// Notification priority
  final Priority priority;

  /// Whether to show notification when app is in foreground
  final bool showInForeground;

  /// Custom notification actions
  final List<AndroidNotificationAction>? actions;

  const NotificationConfig({
    this.channelId = 'runner_background_channel',
    this.channelName = 'Runner Background',
    this.channelDescription = 'Background service notifications',
    this.defaultTitle = 'Background Service',
    this.defaultBody = 'Your app is running in the background',
    this.icon,
    this.sound,
    this.importance = Importance.defaultImportance,
    this.priority = Priority.defaultPriority,
    this.showInForeground = true,
    this.actions,
  });
}
