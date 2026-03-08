/*/ import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static Future init() async {

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    // ใช้ named parameter
    await notifications.initialize(
      settings: settings,
    );
  }

  static Future<void> showBadPosture() async {

    const android = AndroidNotificationDetails(
      'posture_alert',
      'Posture Alert',
      channelDescription: 'แจ้งเตือนเมื่อท่านั่งผิด',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: android,
    );

    // ใช้ named parameters
    await notifications.show(
      id: 0,
      title: "ท่านั่งไม่ถูกต้อง",
      body: "โปรดปรับท่านั่ง",
      notificationDetails: details,
    );
  }
}

**/