import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard_page.dart';
import 'calibration_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String deviceName;

  const HomePage({super.key, required this.deviceName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  late DatabaseReference historyRef;

  int badPostureCount = 0;
  bool isDialogShowing = false;

  @override
  void initState() {
    super.initState();

    historyRef =
        FirebaseDatabase.instance.ref("${widget.deviceName}/history");

    listenLatestPosture();
  }

  void listenLatestPosture() {
    historyRef.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null) return;

      final historyMap = Map<String, dynamic>.from(data as Map);

      // เอาวันล่าสุด
      final latestDateKey = historyMap.keys.last;
      final dateMap =
          Map<String, dynamic>.from(historyMap[latestDateKey]);

      // เอาเวลาล่าสุด
      final latestTimeKey = dateMap.keys.last;
      final latestEntry =
          Map<String, dynamic>.from(dateMap[latestTimeKey]);

      final posture =
          latestEntry["posture"]?.toString().toLowerCase();

      if (posture == "incorrect") {
        badPostureCount++;

        if (badPostureCount >= 3) {
          showWarningDialog();
        }
      } else if (posture == "correct") {
        badPostureCount = 0;
      }
    });
  }

  void showWarningDialog() {
    if (!mounted || isDialogShowing) return;

    isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Wrong Posture ⚠️"),
        content: Text(
          "You are sitting incorrectly $badPostureCount times.\nPlease adjust your posture.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              isDialogShowing = false;
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[selectedIndex],
      ),
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