import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CalibrationPage extends StatefulWidget {
  final String deviceName;

  const CalibrationPage({super.key, required this.deviceName});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  late DatabaseReference ref;

  bool isLoading = false;

  double pitch0 = 0;
  double roll0 = 0;

  @override
  void initState() {
    super.initState();

    ref = FirebaseDatabase.instance.ref("${widget.deviceName}/calibration");

    listenCalibration();
  }

  void listenCalibration() {
    ref.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) return;

      setState(() {
        pitch0 = (data["pitch0"] ?? 0).toDouble();
        roll0 = (data["roll0"] ?? 0).toDouble();
      });
    });
  }

  Future<void> sendCalibrationRequest() async {
    setState(() => isLoading = true);

    await ref.child("request").set(true);

    if (!mounted) return;

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("ส่งคำขอ Calibration ไปยัง ${widget.deviceName} แล้ว"),
        backgroundColor: const Color(0xFF6E9F8D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Calibration - ${widget.deviceName}",
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: double.infinity,
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
                children: [
                  /// ICON
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E9F8D).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_seat,
                      size: 60,
                      color: Color(0xFF6E9F8D),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TITLE
                  const Text(
                    "ตั้งค่าท่านั่งที่ถูกต้อง",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  const Text(
                    "ให้นั่งในท่าที่ถูกต้องตามปกติของคุณ\nแล้วกดปุ่มด้านล่างเพื่อให้ระบบจดจำท่านั่งนี้",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// SHOW CALIBRATION VALUES
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E9F8D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "ค่าท่านั่งที่ถูกต้องของคุณ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text("Pitch0",
                                    style: TextStyle(color: Colors.black54)),
                                Text(
                                  "${pitch0.toStringAsFixed(2)}°",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text("Roll0",
                                    style: TextStyle(color: Colors.black54)),
                                Text(
                                  "${roll0.toStringAsFixed(2)}°",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Pitch = การก้ม/เงยของลำตัว\nRoll = การเอียงซ้ายหรือขวา\nค่าทั้งสองนี้คือค่ามุมที่ถือว่าเป็นท่านั่งที่ถูกต้องของคุณ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : sendCalibrationRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E9F8D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
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
                              "เริ่ม Calibration",
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
      ),
    );
  }
}