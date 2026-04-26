import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase/firebase_config.dart';
import 'pages/home_page.dart';
import 'pages/connect_page.dart';
import 'services/posture_monitor_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// background FCM handler
/// nction นี้จะถูกเรียกเมื่อแอปอยู่ใน background หรือถูกปิดอยู่ และมีการรับ notification เข้ามา
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: FirebaseConfig.webOptions,
  );

  debugPrint("Background notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); /// ทำให้สามารถใช้ async ใน main ได้

  /// initialize Firebase
  await Firebase.initializeApp( 
    options: FirebaseConfig.webOptions,
  );

  /// FCM background handler
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  /// ขอ permission notification
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  /// subscribe topic จาก Node.js
  await FirebaseMessaging.instance.subscribeToTopic("posture_alert");

  final prefs = await SharedPreferences.getInstance();
  final savedDevice = prefs.getString("deviceName");

  /// start posture monitor (อ่านจาก realtime database)
  if (savedDevice != null) {
    final monitor = PostureMonitorService();
    await monitor.init();
    monitor.startMonitoring(savedDevice);
  }

  runApp(MyApp(savedDevice: savedDevice));
}

class MyApp extends StatefulWidget {
  final String? savedDevice;

  const MyApp({super.key, this.savedDevice}); /// รับ deviceName ที่เคยบันทึกไว้จาก SharedPreferences

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    /// notification ตอนเปิดแอป
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground notification: ${message.notification?.title}");
    });

    /// กด notification แล้วเปิดแอป
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: widget.savedDevice != null
          ? HomePage(deviceName: widget.savedDevice!)
          : const ConnectPage(),
    );
  }
}