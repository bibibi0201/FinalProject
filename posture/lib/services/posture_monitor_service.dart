import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostureMonitorService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  late DatabaseReference _historyRef;

  String? _lastRecord;
  int _badCount = 0;

  /// init notification
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings: settings);
  }

  /// start monitor
  void startMonitoring(String deviceName) {

    /// reset ค่าเมื่อเริ่ม monitor
    _badCount = 0;
    _lastRecord = null;

    _historyRef = FirebaseDatabase.instance.ref("$deviceName/history");

    _historyRef.onValue.listen((event) async {

      final data = event.snapshot.value;

      if (data == null) return;

      final history = Map<String, dynamic>.from(data as Map);

      /// หา date ล่าสุด
      final dates = history.keys.toList()..sort();
      final latestDate = dates.last;

      final dayData = Map<String, dynamic>.from(history[latestDate]);

      /// หา time ล่าสุด
      final times = dayData.keys.toList()..sort();
      final latestTime = times.last;

      /// ป้องกัน record ซ้ำ
      String currentRecord = "$latestDate-$latestTime";

      if (currentRecord == _lastRecord) return;

      _lastRecord = currentRecord;

      final latestData = Map<String, dynamic>.from(dayData[latestTime]);

      final posture = latestData["posture"];
      final detail = latestData["postureDetail"];

      /// นับ incorrect
      if (posture == "incorrect") {
        _badCount++;
      } else {
        _badCount = 0;
      }

      /// ถ้าผิด 3 ครั้งติด
      if (_badCount >= 3) {

        await _showNotification(
          "ท่านั่งไม่ถูกต้อง",
          detail ?? "โปรดปรับท่านั่ง",
        );

        /// reset เพื่อให้แจ้งรอบต่อไป
        _badCount = 0;
      }

    });
  }

  /// show notification
  Future<void> _showNotification(String title, String body) async {

    final prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool("notificationEnabled") ?? true;


    /// ถ้าปิด notification → ไม่แจ้งเตือน
    if (!enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'posture_channel',
      'Posture Alerts',
      channelDescription: 'แจ้งเตือนเมื่อท่านั่งผิด',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}