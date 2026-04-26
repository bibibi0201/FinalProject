import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'calibration_page.dart';
import 'settings_page.dart';
import '../services/posture_monitor_service.dart';


/// หน้าหลักของแอป (HomePage) ที่จะแสดง Dashboard, Calibration, และ Settings โดยมีการจัดการกับการเชื่อมต่อกับ Realtime Database เพื่อรับข้อมูลท่านั่งและแสดงผลในรูปแบบต่างๆ รวมถึงการจัดการกับสถานะการเชื่อมต่อและการเริ่มต้น/หยุดการตรวจสอบท่านั่งเมื่อผู้ใช้เข้าสู่หน้า HomePage หรือออกจากหน้า HomePage
class HomePage extends StatefulWidget {
  final String deviceName;

  const HomePage({super.key, required this.deviceName});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State ของ HomePage จะมีการจัดการกับการเชื่อมต่อกับ Realtime Database เพื่อรับข้อมูลท่านั่งและแสดงผลในรูปแบบต่างๆ รวมถึงการจัดการกับสถานะการเชื่อมต่อและการเริ่มต้น/หยุดการตรวจสอบท่านั่งเมื่อผู้ใช้เข้าสู่หน้า HomePage หรือออกจากหน้า HomePage โดยจะมีการสร้าง instance ของ PostureMonitorService เพื่อจัดการกับการตรวจสอบท่านั่งและเชื่อมต่อกับ Realtime Database
class _HomePageState extends State<HomePage> {

  int selectedIndex = 0;

  final PostureMonitorService monitorService = PostureMonitorService();

  @override
  /// ฟังชั่น initState จะถูกเรียกเมื่อหน้า HomePage ถูกสร้างขึ้นครั้งแรก โดยจะทำการเชื่อมต่อกับ Realtime Database ที่ path "deviceName" และเริ่มฟังข้อมูลท่านั่งที่ถูกอัพเดตใน Realtime Database เพื่ออัพเดตข้อมูลในหน้า HomePage ให้เป็นปัจจุบันอยู่เสมอ และเมื่อผู้ใช้ออกจากหน้า HomePage จะทำการหยุดการตรวจสอบท่านั่งเพื่อประหยัดพลังงานและลดการใช้งานทรัพยากรของแอป
  void initState() {
    super.initState();

    monitorService.init();
    monitorService.startMonitoring(widget.deviceName);
  }

  @override
  /// ฟังชั่น dispose จะถูกเรียกเมื่อผู้ใช้ออกจากหน้า HomePage โดยจะทำการหยุดการตรวจสอบท่านั่งเพื่อประหยัดพลังงานและลดการใช้งานทรัพยากรของแอป
  void dispose() {
    monitorService.stopMonitoring();
    super.dispose();
  }

  @override
  /// ฟังชั่น build จะถูกเรียกเมื่อหน้า HomePage ต้องการแสดงผล โดยจะมีการจัดการกับการแสดงผลของ Dashboard, Calibration, และ Settings ตามที่ผู้ใช้เลือกใน BottomNavigationBar และมีการจัดการกับการเชื่อมต่อกับ Realtime Database เพื่อรับข้อมูลท่านั่งและแสดงผลในรูปแบบต่างๆ รวมถึงการจัดการกับสถานะการเชื่อมต่อและการเริ่มต้น/หยุดการตรวจสอบท่านั่งเมื่อผู้ใช้เข้าสู่หน้า HomePage หรือออกจากหน้า HomePage
  Widget build(BuildContext context) {

    final pages = [
      DashboardPage(deviceName: widget.deviceName),
      CalibrationPage(deviceName: widget.deviceName),
      SettingsPage(deviceName: widget.deviceName),
    ];
    /// แสดงหน้า Dashboard, Calibration, หรือ Settings ตามที่ผู้ใช้เลือกใน BottomNavigationBar โดยจะมีการจัดการกับการแสดงผลของแต่ละหน้าตามที่ผู้ใช้เลือก และมีการจัดการกับการเชื่อมต่อกับ Realtime Database เพื่อรับข้อมูลท่านั่งและแสดงผลในรูปแบบต่างๆ รวมถึงการจัดการกับสถานะการเชื่อมต่อและการเริ่มต้น/หยุดการตรวจสอบท่านั่งเมื่อผู้ใช้เข้าสู่หน้า HomePage หรือออกจากหน้า HomePage
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF6E9F8D),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: "Calibration",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}