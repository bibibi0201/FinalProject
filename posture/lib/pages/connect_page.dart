import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

/// หน้าสำหรับเชื่อมต่อกับบอร์ด โดยผู้ใช้จะต้องกรอกชื่อบอร์ดที่ต้องการเชื่อมต่อ (ซึ่งต้องตรงกับชื่อที่อุปกรณ์ส่งขึ้นไปเก็บใน Realtime Database) และเมื่อกดปุ่ม Connect จะทำการตรวจสอบว่ามีข้อมูลของบอร์ดนั้นอยู่ใน Realtime Database หรือไม่ ถ้ามีจะทำการบันทึกชื่อบอร์ดลงใน SharedPreferences และนำผู้ใช้ไปยังหน้า HomePage เพื่อเริ่มใช้งานแอป
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}
/// State ของ ConnectPage จะมี TextEditingController สำหรับจัดการกับ TextField ที่ผู้ใช้กรอกชื่อบอร์ด และตัวแปร isLoading เพื่อแสดงสถานะการเชื่อมต่อ
class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController controller = TextEditingController();
  bool isLoading = false;
  /// ฟังชั่น connectToBoard จะถูกเรียกเมื่อผู้ใช้กดปุ่ม Connect โดยจะทำการตรวจสอบว่าชื่อบอร์ดที่กรอกไม่ว่างเปล่า จากนั้นจะทำการเชื่อมต่อกับ Realtime Database เพื่อตรวจสอบว่ามีข้อมูลของบอร์ดนั้นอยู่หรือไม่ ถ้ามีจะทำการบันทึกชื่อบอร์ดลงใน SharedPreferences และนำผู้ใช้ไปยังหน้า HomePage ถ้าไม่มีจะทำการแสดง SnackBar แจ้งว่าไม่พบบอร์ด และถ้ามีข้อผิดพลาดในการเชื่อมต่อก็จะแสดง SnackBar แจ้งว่าเกิดข้อผิดพลาด
  Future<void> connectToBoard() async {
    final deviceName = controller.text.trim();
    // ตรวจสอบว่าชื่อบอร์ดไม่ว่างเปล่า
    if (deviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter board name")),
      );
      return;
    }

    setState(() => isLoading = true);  // แสดงสถานะกำลังเชื่อมต่อ

    // พยายามเชื่อมต่อกับ Realtime Database เพื่อตรวจสอบว่ามีข้อมูลของบอร์ดนั้นอยู่หรือไม่
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref(deviceName).get();

      if (!mounted) return;

      if (snapshot.exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("deviceName", deviceName);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomePage(deviceName: deviceName),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Board not found ❌")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error")),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  /// ฟังชั่น dispose จะถูกเรียกเมื่อหน้า ConnectPage ถูกทำลาย (เช่น เมื่อผู้ใช้ไปยังหน้าอื่น) โดยจะทำการปล่อยทรัพยากรที่ใช้โดย TextEditingController เพื่อป้องกัน memory leak
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  /// ฟังชั่น build จะสร้าง UI ของหน้า ConnectPage โดยมี TextField ให้ผู้ใช้กรอกชื่อบอร์ด และปุ่ม Connect ที่จะเรียกฟังชั่น connectToBoard เมื่อถูกกด นอกจากนี้ยังมีการแสดงสถานะกำลังเชื่อมต่อด้วย CircularProgressIndicator เมื่อ isLoading เป็น true
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.memory,
                  size: 70,
                  color: Color(0xFF6E9F8D),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Connect Your Board",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enter your board name (e.g. esp01)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Board name",
                    filled: true,
                    fillColor: const Color(0xFFF4F7F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : connectToBoard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E9F8D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Connect",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}