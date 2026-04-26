import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connect_page.dart';


/// หน้าสำหรับตั้งค่าการแจ้งเตือนและการจัดการกับการเชื่อมต่อกับบอร์ด โดยผู้ใช้สามารถเปิด/ปิดการแจ้งเตือนท่านั่งผิดได้ และสามารถตัดการเชื่อมต่อกับบอร์ดเพื่อเปลี่ยนบอร์ดที่ต้องการเชื่อมต่อได้ โดยจะมีการจัดเก็บสถานะการแจ้งเตือนใน SharedPreferences เพื่อให้สามารถจำค่าการตั้งค่าได้แม้หลังจากปิดแอปไปแล้ว
class SettingsPage extends StatefulWidget {
  final String deviceName;

  const SettingsPage({super.key, required this.deviceName});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// State ของ SettingsPage จะมีการจัดการกับสถานะการแจ้งเตือนท่านั่งผิดและการเชื่อมต่อกับบอร์ด โดยจะมีการโหลดค่าการตั้งค่าจาก SharedPreferences เมื่อหน้า SettingsPage ถูกสร้างขึ้น และมีฟังชั่นสำหรับเปิด/ปิดการแจ้งเตือนท่านั่งผิดที่อัพเดตค่าใน SharedPreferences และฟังชั่นสำหรับตัดการเชื่อมต่อกับบอร์ดที่ลบชื่อบอร์ดออกจาก SharedPreferences และนำผู้ใช้กลับไปยังหน้า ConnectPage เพื่อเลือกบอร์ดใหม่
class _SettingsPageState extends State<SettingsPage> {

  bool notificationEnabled = true;

  @override
  /// ฟังชั่น initState จะถูกเรียกเมื่อหน้า SettingsPage ถูกสร้างขึ้นครั้งแรก โดยจะทำการโหลดค่าการตั้งค่าการแจ้งเตือนท่านั่งผิดจาก SharedPreferences และอัพเดตสถานะในหน้า SettingsPage ให้ตรงกับค่าที่บันทึกไว้
  void initState() {
    super.initState();
    loadSetting();
  }

  /// ฟังชั่น loadSetting จะทำการโหลดค่าการตั้งค่าการแจ้งเตือนท่านั่งผิดจาก SharedPreferences และอัพเดตสถานะในหน้า SettingsPage ให้ตรงกับค่าที่บันทึกไว้ โดยถ้าไม่มีค่าที่บันทึกไว้จะตั้งค่าเริ่มต้นเป็น true (เปิดการแจ้งเตือน)
  Future<void> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationEnabled = prefs.getBool("notificationEnabled") ?? true;
    });
  }

  /// ฟังชั่น toggleNotification จะถูกเรียกเมื่อผู้ใช้เปิด/ปิดสวิตช์การแจ้งเตือนท่านั่งผิด โดยจะอัพเดตสถานะในหน้า SettingsPage และบันทึกค่าการตั้งค่าใหม่ลงใน SharedPreferences เพื่อให้สามารถจำค่าการตั้งค่าได้แม้หลังจากปิดแอปไปแล้ว
  Future<void> toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      notificationEnabled = value;
    });

    await prefs.setBool("notificationEnabled", value);
  }

  /// ฟังชั่น disconnect จะถูกเรียกเมื่อผู้ใช้กดปุ่ม Disconnect & Change Board โดยจะทำการลบชื่อบอร์ดออกจาก SharedPreferences และนำผู้ใช้กลับไปยังหน้า ConnectPage เพื่อเลือกบอร์ดใหม่
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deviceName');

    if (!mounted) return;

    // นำผู้ใช้กลับไปยังหน้า ConnectPage โดยลบหน้าทั้งหมดใน stack เพื่อป้องกันการกลับไปยังหน้า HomePage ด้วยปุ่ม Back
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ConnectPage()),
      (route) => false,
    );
  }

  @override
  /// ฟังชั่น build จะถูกเรียกเมื่อหน้า SettingsPage ต้องการแสดงผล โดยจะมีการจัดการกับการแสดงผลของการตั้งค่าการแจ้งเตือนท่านั่งผิดและปุ่มสำหรับตัดการเชื่อมต่อกับบอร์ด โดยจะมีการจัดเก็บสถานะการแจ้งเตือนใน SharedPreferences เพื่อให้สามารถจำค่าการตั้งค่าได้แม้หลังจากปิดแอปไปแล้ว และมีการนำผู้ใช้กลับไปยังหน้า ConnectPage เมื่อกดปุ่ม Disconnect & Change Board
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.memory, color: Color(0xFF6E9F8D)),
                  const SizedBox(width: 10),
                  Text(
                    "Connected Board: ${widget.deviceName}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔔 notification toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications, color: Color(0xFF6E9F8D)),
                      SizedBox(width: 10),
                      Text(
                        "Posture Notification",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Switch(
                    value: notificationEnabled,
                    onChanged: toggleNotification,
                    activeThumbColor: const Color(0xFF6E9F8D),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Disconnect & Change Board",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}