# Runner Background Package - คู่มือการใช้งานฉบับสมบูรณ์

## 📱 ภาพรวม

Runner Background เป็น Flutter package ที่พัฒนาขึ้นเพื่อให้แอปของคุณสามารถทำงานในโหมดเบื้องหลัง (Background Service) และแสดงการแจ้งเตือน (Notifications) แม้ว่าแอปจะถูกปิดหรืออยู่ในสถานะพื้นหลัง

## 🌟 ฟีเจอร์หลัก

### ✅ Background Service

- ทำงานต่อเนื่องแม้แอปถูกปิด
- รองรับทั้ง Android และ iOS
- ปรับแต่งความถี่ในการทำงานได้
- ประหยัดแบตเตอรี่ด้วยระบบข้อจำกัด (Constraints)

### 🔔 Notification System

- แสดงการแจ้งเตือนแบบ Local
- สร้าง Notification Channel สำหรับ Android
- รองรับการตั้งค่าความสำคัญและเสียง
- จัดการ Notification Actions

### ⚙️ Configuration System

- กำหนดค่าได้อย่างยืดหยุ่น
- รองรับ Callback Functions
- จัดเก็บการตั้งค่าใน SharedPreferences
- ตรวจสอบสถานะการทำงาน

## 🚀 การติดตั้งและตั้งค่า

### 1. เพิ่ม Dependencies

```yaml
dependencies:
  runner_background: ^0.0.1
```

### 2. Android Setup

แก้ไขไฟล์ `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 3. iOS Setup

แก้ไขไฟล์ `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

## 💻 การใช้งานเบื้องต้น

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:runner_background/runner_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // กำหนดค่า Background Service
  await RunnerBackground.initialize(
    config: RunnerBackgroundConfig(
      frequency: const Duration(minutes: 15), // ทำงานทุก 15 นาที
      notificationConfig: const NotificationConfig(
        channelId: 'background_service',
        channelName: 'Background Service',
        defaultTitle: '🔔 แอปทำงานอยู่เบื้องหลัง',
        defaultBody: 'แอปของคุณกำลังซิงข์ข้อมูลและตรวจสอบการอัพเดท',
      ),
      onBackgroundTask: () async {
        // งานที่ต้องการให้ทำใน background
        print('Syncing data...');
        await syncDataWithServer();
        await cleanupOldFiles();
      },
      onNotificationTapped: (payload) {
        // จัดการเมื่อผู้ใช้แตะ notification
        print('User tapped notification: $payload');
        navigateToMainScreen();
      },
    ),
  );

  runApp(MyApp());
}
```

### Advanced Configuration

```dart
final config = RunnerBackgroundConfig(
  // ความถี่ในการทำงาน
  frequency: const Duration(minutes: 30),

  // หน่วงเวลาก่อนเริ่มทำงาน
  initialDelay: const Duration(seconds: 15),

  // เงื่อนไขการทำงาน
  constraints: Constraints(
    networkType: NetworkType.connected, // ต้องมีอินเทอร์เน็ต
    requiresBatteryNotLow: true,       // แบตไม่ต่ำเกินไป
    requiresCharging: false,           // ไม่จำเป็นต้องชาร์จ
  ),

  // การตั้งค่า Notification
  notificationConfig: NotificationConfig(
    channelId: 'my_app_bg_service',
    channelName: 'Background Service',
    channelDescription: 'แจ้งเตือนจาก background service',
    defaultTitle: '⚡ Background Service',
    defaultBody: 'กำลังซิงข์ข้อมูลเบื้องหลัง...',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    showInForeground: true,
    actions: [
      AndroidNotificationAction(
        'stop_action',
        'หยุดการทำงาน',
        cancelNotification: true,
      ),
    ],
  ),

  // งานที่ทำใน background
  onBackgroundTask: () async {
    try {
      // 1. ซิงข์ข้อมูลกับเซิร์ฟเวอร์
      await ApiService.syncData();

      // 2. ล้างข้อมูลเก่า
      await CacheManager.clearOldCache();

      // 3. ตรวจสอบการอัพเดท
      await UpdateChecker.checkForUpdates();

      // 4. บันทึก log
      Logger.info('Background task completed successfully');
    } catch (e) {
      Logger.error('Background task failed: $e');
    }
  },

  // จัดการเมื่อแตะ notification
  onNotificationTapped: (payload) {
    if (payload == 'open_main') {
      Navigator.pushNamed(context, '/main');
    } else if (payload == 'open_settings') {
      Navigator.pushNamed(context, '/settings');
    }
  },
);
```

## 🎯 การจัดการ App Lifecycle

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // แอปกลับมาที่ foreground
        BackgroundServiceManager.startForegroundMonitoring();
        _checkPendingNotifications();
        break;
      case AppLifecycleState.paused:
        // แอปไปที่ background
        BackgroundServiceManager.stopForegroundMonitoring();
        break;
      case AppLifecycleState.detached:
        // แอปกำลังจะปิด
        break;
    }
  }

  Future<void> _checkPendingNotifications() async {
    final stats = await BackgroundServiceManager.getServiceStats();
    if (stats['pendingNotificationsCount'] > 0) {
      // มี notification รอแสดง
      _showPendingNotificationsDialog();
    }
  }
}
```

## 📊 การตรวจสอบสถานะ

```dart
// ตรวจสอบว่า Background Service ทำงานหรือไม่
bool isRunning = await RunnerBackground.isRunning();

// ดูสถิติการทำงาน
Map<String, dynamic> stats = await BackgroundServiceManager.getServiceStats();
print('Service running: ${stats['isRunning']}');
print('Last execution: ${stats['lastExecution']}');
print('Pending notifications: ${stats['pendingNotificationsCount']}');

// ดู notification ที่รอแสดง
List<Map<String, String>> pending = await BackgroundService.getPendingNotifications();
for (final notification in pending) {
  print('Title: ${notification['title']}');
  print('Body: ${notification['body']}');
}
```

## 🛑 การหยุดและจัดการ Service

```dart
// หยุด Background Service
await RunnerBackground.stop();

// ยกเลิก notification ที่รอแสดง
await BackgroundService.clearPendingNotifications();

// ยกเลิก notification ทั้งหมด
await NotificationService.cancelAll();

// ยกเลิก notification โดย ID
await NotificationService.cancel(notificationId);
```

## 🔔 การแสดง Notification แบบทันที

```dart
// แสดง notification ทันที
await RunnerBackground.showNotification(
  title: '📦 ดาวน์โหลดเสร็จสิ้น',
  body: 'ไฟล์ของคุณพร้อมใช้งานแล้ว',
  payload: 'download_complete',
);

// แสดง notification ตามเวลาที่กำหนด
await NotificationService.showScheduledNotification(
  title: '⏰ เตือนความจำ',
  body: 'ถึงเวลาทำงานที่คุณกำหนดไว้',
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
  payload: 'reminder_task',
);
```

## ⚠️ ข้อควรระวังและแนวทางปฏิบัติ

### Android

- Background service จะถูกจำกัดโดย Android Doze Mode
- ผู้ใช้อาจต้องปิด Battery Optimization สำหรับแอป
- ระบบอาจหยุด background service เมื่อทรัพยากรต่ำ

### iOS

- Background execution มีข้อจำกัดเวลา
- ต้องเปิด Background App Refresh ในการตั้งค่า
- ระบบจะจำกัดการทำงานตามสถานะแบตเตอรี่

### แนวทางปฏิบัติที่ดี

1. **ใช้ความถี่ที่เหมาะสม**: อย่าตั้งให้ทำงานบ่อยเกินไป
2. **จัดการข้อผิดพลาด**: ใช้ try-catch ใน background tasks
3. **ประหยัดแบตเตอรี่**: ตั้งค่า constraints ที่เหมาะสม
4. **ข้อมูลผู้ใช้**: อธิบายเหตุผลการใช้ background service
5. **ทดสอบ**: ทดสอบการทำงานในสถานการณ์ต่างๆ

## 🎉 สรุป

Runner Background Package ช่วยให้แอป Flutter ของคุณสามารถ:

- ทำงานในโหมดเบื้องหลังได้อย่างมีประสิทธิภาพ
- แสดงการแจ้งเตือนที่เหมาะสม
- จัดการระบบอย่างประหยัดทรัพยากร
- รองรับทั้ง Android และ iOS

ด้วยการใช้งานที่ง่ายและฟีเจอร์ที่ครบครัน ทำให้เป็นตัวเลือกที่ดีสำหรับแอปที่ต้องการทำงานเบื้องหลัง

---

สำหรับข้อมูลเพิ่มเติมและตัวอย่างการใช้งาน กรุณาดูที่ [GitHub Repository](https://github.com/yourusername/runner_background)
