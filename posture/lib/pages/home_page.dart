import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'calibration_page.dart';
import 'settings_page.dart';
import '../services/posture_monitor_service.dart';

class HomePage extends StatefulWidget {
  final String deviceName;

  const HomePage({super.key, required this.deviceName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int selectedIndex = 0;

  final PostureMonitorService monitorService = PostureMonitorService();

  @override
  void initState() {
    super.initState();

    monitorService.init();
    monitorService.startMonitoring(widget.deviceName);
  }

  @override
  void dispose() {
    monitorService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final pages = [
      DashboardPage(deviceName: widget.deviceName),
      CalibrationPage(deviceName: widget.deviceName),
      SettingsPage(deviceName: widget.deviceName),
    ];

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