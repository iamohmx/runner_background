# Runner Background

[![pub package](https://img.shields.io/pub/v/runner_background.svg)](https://pub.dev/packages/runner_background)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter package for running background services and displaying notifications when the mobile device is turned on or when the app is in the background.

## Features

- 🔄 **Background Service**: Run tasks in the background even when the app is closed
- 📱 **Cross-platform**: Works on both Android and iOS
- 🔔 **Local Notifications**: Show notifications when tasks are completed
- ⚡ **Battery Optimized**: Efficient background task management
- 🎯 **Customizable**: Flexible configuration options
- 🛡️ **Reliable**: Built on top of workmanager and flutter_local_notifications

## Changelog

See what's new in the latest releases: [CHANGELOG.md](CHANGELOG.md)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  runner_background: ^1.0.0
```

Run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add these permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS

Add these permissions to your `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

## Usage

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:runner_background/runner_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background service
  await RunnerBackground.initialize(
    config: RunnerBackgroundConfig(
      frequency: const Duration(minutes: 15),
      notificationConfig: const NotificationConfig(
        channelId: 'background_service',
        channelName: 'Background Service',
        defaultTitle: '🔔 แอปทำงานอยู่เบื้องหลัง',
        defaultBody: 'แอปของคุณกำลังทำงานในโหมดเบื้องหลัง',
      ),
      onBackgroundTask: () async {
        print('Background task is running...');
        // Your background task logic here
      },
      onNotificationTapped: (payload) {
        print('Notification tapped: $payload');
      },
    ),
  );

  runApp(MyApp());
}
```

## API Reference

### RunnerBackground

Main class for managing background services.

#### Methods

- `initialize(config)` - Initialize the background service
- `stop()` - Stop the background service
- `isRunning()` - Check if service is running
- `showNotification(title, body, payload)` - Show immediate notification

### RunnerBackgroundConfig

Configuration class for background service settings.

#### Properties

- `frequency` - Background task execution frequency
- `initialDelay` - Initial delay before starting
- `constraints` - System constraints for task execution
- `notificationConfig` - Notification settings
- `onBackgroundTask` - Background task callback
- `onNotificationTapped` - Notification tap callback

## Example

See the [example](example/) directory for a complete example application.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
