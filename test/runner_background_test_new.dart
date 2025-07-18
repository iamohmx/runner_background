import 'package:flutter_test/flutter_test.dart';
import 'package:runner_background/runner_background.dart';

void main() {
  group('RunnerBackground Tests', () {
    test('RunnerBackgroundConfig should be created with default values', () {
      const config = RunnerBackgroundConfig(
        notificationConfig: NotificationConfig(
          channelId: 'test',
          channelName: 'Test',
          defaultTitle: 'Title',
          defaultBody: 'Body',
        ),
      );

      expect(config.frequency, equals(const Duration(minutes: 15)));
      expect(config.initialDelay, equals(const Duration(seconds: 10)));
      expect(config.notificationConfig.channelId, equals('test'));
      expect(config.notificationConfig.channelName, equals('Test'));
      expect(config.notificationConfig.defaultTitle, equals('Title'));
      expect(config.notificationConfig.defaultBody, equals('Body'));
    });

    test('NotificationConfig should be created with default values', () {
      const config = NotificationConfig(
        channelId: 'test_channel',
        channelName: 'Test Channel',
        defaultTitle: 'Test Title',
        defaultBody: 'Test Body',
      );

      expect(config.channelId, equals('test_channel'));
      expect(config.channelName, equals('Test Channel'));
      expect(config.defaultTitle, equals('Test Title'));
      expect(config.defaultBody, equals('Test Body'));
      expect(config.channelDescription,
          equals('Background service notifications'));
      expect(config.showInForeground, equals(true));
    });

    test('RunnerBackgroundConfig should accept custom values', () {
      const customConfig = RunnerBackgroundConfig(
        frequency: Duration(minutes: 30),
        initialDelay: Duration(seconds: 20),
        notificationConfig: NotificationConfig(
          channelId: 'custom_channel',
          channelName: 'Custom Channel',
          defaultTitle: 'Custom Title',
          defaultBody: 'Custom Body',
          channelDescription: 'Custom description',
          showInForeground: false,
        ),
      );

      expect(customConfig.frequency, equals(const Duration(minutes: 30)));
      expect(customConfig.initialDelay, equals(const Duration(seconds: 20)));
      expect(
          customConfig.notificationConfig.channelId, equals('custom_channel'));
      expect(customConfig.notificationConfig.channelName,
          equals('Custom Channel'));
      expect(
          customConfig.notificationConfig.defaultTitle, equals('Custom Title'));
      expect(
          customConfig.notificationConfig.defaultBody, equals('Custom Body'));
      expect(customConfig.notificationConfig.channelDescription,
          equals('Custom description'));
      expect(customConfig.notificationConfig.showInForeground, equals(false));
    });

    test('should handle callbacks', () {
      bool backgroundTaskCalled = false;
      String? notificationPayload;

      final configWithCallbacks = RunnerBackgroundConfig(
        notificationConfig: const NotificationConfig(
          channelId: 'test',
          channelName: 'Test',
          defaultTitle: 'Title',
          defaultBody: 'Body',
        ),
        onBackgroundTask: () async {
          backgroundTaskCalled = true;
        },
        onNotificationTapped: (payload) {
          notificationPayload = payload;
        },
      );

      expect(configWithCallbacks.onBackgroundTask, isNotNull);
      expect(configWithCallbacks.onNotificationTapped, isNotNull);

      // Test callbacks
      configWithCallbacks.onBackgroundTask!();
      configWithCallbacks.onNotificationTapped!('test_payload');

      expect(backgroundTaskCalled, equals(true));
      expect(notificationPayload, equals('test_payload'));
    });

    test('BackgroundService should provide future methods', () async {
      final result = BackgroundService.isRunning();
      expect(result, isA<Future<bool>>());
    });

    test('BackgroundServiceManager should provide service stats', () async {
      final result = BackgroundServiceManager.getServiceStats();
      expect(result, isA<Future<Map<String, dynamic>>>());
    });
  });
}
