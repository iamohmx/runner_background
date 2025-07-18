import 'package:flutter/material.dart';
import 'package:runner_background/runner_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Background Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isServiceRunning = false;
  Map<String, dynamic>? _serviceStats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBackgroundService();
    _checkServiceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackgroundServiceManager.stopForegroundMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App กลับมาที่ foreground
        BackgroundServiceManager.startForegroundMonitoring();
        _checkServiceStatus();
        break;
      case AppLifecycleState.paused:
        // App ไปที่ background
        BackgroundServiceManager.stopForegroundMonitoring();
        break;
      case AppLifecycleState.detached:
        // App กำลังจะถูกปิด
        break;
      case AppLifecycleState.inactive:
        // App ไม่ active (เช่น กำลังรับ call)
        break;
      case AppLifecycleState.hidden:
        // App ถูกซ่อน
        break;
    }
  }

  Future<void> _initializeBackgroundService() async {
    try {
      final config = RunnerBackgroundConfig(
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(seconds: 10),
        notificationConfig: const NotificationConfig(
          channelId: 'runner_background_channel',
          channelName: 'Runner Background Service',
          channelDescription: 'แสดงการแจ้งเตือนจาก background service',
          defaultTitle: '🔔 แอปทำงานอยู่เบื้องหลัง',
          defaultBody:
              'แอปของคุณกำลังทำงานในโหมดเบื้องหลังเพื่อให้บริการที่ดีที่สุด',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showInForeground: true,
        ),
        onBackgroundTask: () async {
          // งานที่ต้องการให้ทำใน background
          print('Background task is running...');

          // ตัวอย่าง: บันทึก log, sync ข้อมูล, ตรวจสอบอัพเดท
          await _performBackgroundTasks();
        },
        onNotificationTapped: (payload) {
          // เมื่อผู้ใช้แตะ notification
          print('Notification tapped with payload: $payload');
          _showSnackBar('การแจ้งเตือนถูกแตะ: $payload');
        },
      );

      await RunnerBackground.initialize(config: config);
      await BackgroundService.saveConfig(config);

      // เริ่ม monitoring เมื่อ app อยู่ใน foreground
      BackgroundServiceManager.startForegroundMonitoring();

      print('Background service initialized successfully');
    } catch (e) {
      print('Error initializing background service: $e');
    }
  }

  Future<void> _performBackgroundTasks() async {
    // ตัวอย่างงานที่ทำใน background
    try {
      // 1. ตรวจสอบข้อมูลใหม่
      await Future.delayed(const Duration(seconds: 2));

      // 2. Sync ข้อมูลกับ server
      await Future.delayed(const Duration(seconds: 1));

      // 3. ทำความสะอาดข้อมูลเก่า
      await Future.delayed(const Duration(seconds: 1));

      print('Background tasks completed successfully');
    } catch (e) {
      print('Error in background tasks: $e');
    }
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await RunnerBackground.isRunning();
    final stats = await BackgroundServiceManager.getServiceStats();

    setState(() {
      _isServiceRunning = isRunning;
      _serviceStats = stats;
    });
  }

  Future<void> _startService() async {
    try {
      await _initializeBackgroundService();
      await _checkServiceStatus();
      _showSnackBar('Background service เริ่มทำงานแล้ว');
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _stopService() async {
    try {
      await RunnerBackground.stop();
      BackgroundServiceManager.stopForegroundMonitoring();
      await _checkServiceStatus();
      _showSnackBar('Background service หยุดทำงานแล้ว');
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _showTestNotification() async {
    try {
      await RunnerBackground.showNotification(
        title: '🧪 ทดสอบการแจ้งเตือน',
        body: 'นี่คือการแจ้งเตือนทดสอบจาก Runner Background',
        payload: 'test_notification',
      );
      _showSnackBar('ส่งการแจ้งเตือนทดสอบแล้ว');
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runner Background Example'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถานะ Background Service',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isServiceRunning ? Icons.check_circle : Icons.cancel,
                          color: _isServiceRunning ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isServiceRunning ? 'กำลังทำงาน' : 'หยุดทำงาน',
                          style: TextStyle(
                            color:
                                _isServiceRunning ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_serviceStats != null) ...[
                      const SizedBox(height: 12),
                      Text(
                          'การทำงานครั้งล่าสุด: ${_serviceStats!['lastExecution']}'),
                      Text(
                          'การแจ้งเตือนรอ: ${_serviceStats!['pendingNotificationsCount']}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isServiceRunning ? null : _startService,
              icon: const Icon(Icons.play_arrow),
              label: const Text('เริ่ม Background Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isServiceRunning ? _stopService : null,
              icon: const Icon(Icons.stop),
              label: const Text('หยุด Background Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showTestNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('ทดสอบการแจ้งเตือน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _checkServiceStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('ตรวจสอบสถานะ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลการใช้งาน',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Background service จะทำงานทุก 15 นาที\n'
                      '• แสดงการแจ้งเตือนเมื่อแอปทำงานเบื้องหลัง\n'
                      '• สามารถกำหนดงานเพิ่มเติมได้ใน onBackgroundTask\n'
                      '• รองรับทั้ง Android และ iOS\n'
                      '• ประหยัดแบตเตอรี่และทรัพยากรระบบ',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
