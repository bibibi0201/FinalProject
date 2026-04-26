import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';


/// หน้าสำหรับแสดงข้อมูลสรุปท่านั่งของผู้ใช้ โดยจะเชื่อมต่อกับ Realtime Database เพื่อรับข้อมูลท่านั่งล่าสุดและประวัติท่านั่งในอดีต และแสดงผลในรูปแบบ Dashboard ที่มีการจัดกลุ่มข้อมูลตามวันที่และแสดงรายละเอียดของท่านั่งแต่ละช่วงเวลา
class HistoryPage extends StatefulWidget {
  final String deviceName;

  /// วันที่ที่ Dashboard ส่งมา (optional)
  final String? selectedDate;

  const HistoryPage({
    super.key,
    required this.deviceName,
    this.selectedDate,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

/// State ของ HistoryPage จะมีการเชื่อมต่อกับ Realtime Database เพื่อรับข้อมูลท่านั่งล่าสุดและประวัติท่านั่งในอดีต และจัดการกับการแสดงผลในรูปแบบ Dashboard โดยมีการจัดกลุ่มข้อมูลตามวันที่และแสดงรายละเอียดของท่านั่งแต่ละช่วงเวลา
class _HistoryPageState extends State<HistoryPage> {

  /// Firebase reference
  late DatabaseReference ref;

  /// เก็บข้อมูลรายวัน
  Map<String, Map<String, dynamic>> dailyData = {};

  /// list วันที่เรียงจากใหม่ -> เก่า
  List<String> sortedDates = [];

  /// วันที่ที่กำลังเลือก
  String? selectedDate;

  @override
  void initState() {
    super.initState();

    /// path firebase
    ref = FirebaseDatabase.instance.ref("${widget.deviceName}/history");

    /// โหลดข้อมูล
    loadHistory();
  }

  /// โหลดข้อมูล history จาก firebase
  void loadHistory() {

    ref.onValue.listen((event) {

      final data = event.snapshot.value;
      if (data == null) return;

      Map historyData = data as Map;

      /// เก็บข้อมูลสรุปต่อวัน
      Map<String, Map<String, dynamic>> tempDaily = {};

      historyData.forEach((date, dateValue) {

        int correct = 0;
        int incorrect = 0;
        int unknown = 0;

        Map<String, int> detailCount = {};

        Map times = dateValue as Map;

        times.forEach((time, value) {

          String posture = value["posture"] ?? "unknown";

          if (posture == "correct") {

            correct++;

          } else if (posture == "incorrect") {

            incorrect++;

            /// นับปัญหา postureDetail
            if (value["postureDetail"] != null) {

              String detail = value["postureDetail"];

              List<String> parts = detail.split(",");

              for (var p in parts) {

                String trimmed = p.trim();

                if (trimmed.isEmpty) continue;

                detailCount[trimmed] =
                    (detailCount[trimmed] ?? 0) + 1;

              }

            }

          } else {

            unknown++;

          }

        });

        /// คำนวณ % posture ถูกต้อง
        int totalValid = correct + incorrect;

        double percent =
            totalValid == 0 ? 0 : (correct / totalValid) * 100;

        tempDaily[date] = {
          "correct": correct,
          "incorrect": incorrect,
          "unknown": unknown,
          "percent": percent,
          "detailCount": detailCount,
        };

      });

      /// เรียงวันที่ใหม่ -> เก่า
      List<String> dates = tempDaily.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      setState(() {

        dailyData = tempDaily;
        sortedDates = dates;

        /// ถ้ามีวันที่ส่งมาจาก Dashboard
        if (widget.selectedDate != null &&
            dates.contains(widget.selectedDate)) {

          selectedDate = widget.selectedDate;

        } else {

          /// ถ้าไม่ได้ส่งมา ใช้วันล่าสุด
          selectedDate = dates.isNotEmpty ? dates.first : null;

        }

      });

    });

  }

  @override
  /// ฟังชั่น initState จะถูกเรียกเมื่อหน้า HistoryPage ถูกสร้างขึ้นครั้งแรก โดยจะทำการเชื่อมต่อกับ Realtime Database ที่ path "deviceName/history" และเริ่มฟังข้อมูลท่านั่งที่ถูกอัพเดตใน Realtime Database เพื่ออัพเดตข้อมูลในหน้า HistoryPage ให้เป็นปัจจุบันอยู่เสมอ
  Widget build(BuildContext context) {

    if (sortedDates.isEmpty || selectedDate == null) {

      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F6),
        body: Center(child: CircularProgressIndicator()),
      );

    }

    final data = dailyData[selectedDate]!;
    /// ดึงข้อมูลสรุปของวันที่เลือกมาแสดงในหน้า HistoryPage โดยจะมีการคำนวณอัตราท่านั่งถูกต้องและแสดงผลในรูปแบบกราฟวงกลม (Pie Chart) และสรุปข้อมูลต่างๆ เช่น จำนวนท่านั่งถูกต้อง, ท่านั่งผิด, และท่านั่งไม่ทราบ รวมถึงการแสดงรายละเอียดของปัญหาที่พบบ่อยในท่านั่งผิด
    double correct = data["correct"].toDouble();
    double incorrect = data["incorrect"].toDouble();
    double unknown = data["unknown"].toDouble();
    double percent = data["percent"];

    Map<String, int> detailCount =
        Map<String, int>.from(data["detailCount"]);

    bool noValidData = (correct + incorrect) == 0;

    return Scaffold(

      backgroundColor: const Color(0xFFF4F7F6),

      appBar: AppBar(

        backgroundColor: const Color(0xFFF4F7F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),

        title: Text(
          "History (${widget.deviceName})",
          style: const TextStyle(color: Colors.black),
        ),

      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            /// -----------------------
            /// DATE SELECTOR
            /// -----------------------
            Container(

              padding: const EdgeInsets.symmetric(horizontal: 16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),

              child: DropdownButton<String>(

                dropdownColor: Colors.white,
                value: selectedDate,
                isExpanded: true,
                underline: const SizedBox(),

                items: sortedDates.map((date) {

                  return DropdownMenuItem(
                    value: date,
                    child: Text(date),
                  );

                }).toList(),

                onChanged: (value) {

                  setState(() {
                    selectedDate = value!;
                  });

                },

              ),

            ),

            const SizedBox(height: 25),

            /// -----------------------
            /// PIE CHART
            /// -----------------------
            Container(

              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),

              child: Column(

                children: [

                  const Text(
                    "อัตราท่านั่งถูกต้อง",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(

                    height: 220,

                    child: noValidData
                        ? const Center(
                            child: Text(
                              "ยังไม่มีข้อมูลการนั่ง\n(ยังไม่ได้ปรับเทียบ)",
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Stack(

                            alignment: Alignment.center,

                            children: [

                              PieChart(

                                PieChartData(

                                  sectionsSpace: 4,
                                  centerSpaceRadius: 60,

                                  sections: [

                                    PieChartSectionData(
                                      value: correct,
                                      color: const Color(0xFF6E9F8D),
                                      radius: 50,
                                      showTitle: false,
                                    ),

                                    PieChartSectionData(
                                      value: incorrect,
                                      color: Colors.redAccent,
                                      radius: 50,
                                      showTitle: false,
                                    ),

                                  ],

                                ),

                              ),

                              Column(

                                mainAxisSize: MainAxisSize.min,

                                children: [

                                  Text(
                                    "${percent.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: percent >= 70
                                          ? const Color(0xFF6E9F8D)
                                          : percent >= 40
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),

                                  const Text("Correct"),

                                ],

                              )

                            ],

                          ),

                  ),

                  const SizedBox(height: 15),
                  /// สรุปจำนวนท่านั่งถูกต้อง, ผิด, ไม่ทราบ
                  if (!noValidData)
                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        _legendDot(const Color(0xFF6E9F8D)),
                        const SizedBox(width: 6),
                        Text("Correct: ${correct.toInt()}"),

                        const SizedBox(width: 25),

                        _legendDot(Colors.redAccent),
                        const SizedBox(width: 6),
                        Text("Incorrect: ${incorrect.toInt()}"),

                      ],

                    ),

                ],

              ),

            ),

            const SizedBox(height: 20),

            /// -----------------------
            /// SUMMARY CARD
            /// -----------------------
            Container(

              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),

              child: _buildSummaryUI(
                percent,
                correct.toInt(),
                incorrect.toInt(),
                unknown.toInt(),
                detailCount,
              ),

            ),

          ],

        ),

      ),

    );

  }

  /// จุด legend
  Widget _legendDot(Color color) {

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

  }

  /// UI summary
  Widget _buildSummaryUI(
    double percent,
    int correctTotal,
    int incorrectTotal,
    int unknownTotal,
    Map<String, int> detailCount,
  ) {

    if (correctTotal + incorrectTotal == 0) {

      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "ยังไม่มีข้อมูลการนั่ง",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          SizedBox(height: 6),

          Text("กรุณาปรับเทียบอุปกรณ์ก่อนใช้งาน"),

        ],
      );

    }

    String level;

    if (percent >= 80) {
      level = "ยอดเยี่ยมมาก";
    } else if (percent >= 60) {
      level = "ทำได้ดี";
    } else if (percent >= 40) {
      level = "ควรปรับปรุงเล็กน้อย";
    } else {
      level = "ควรปรับปรุง";
    }

    String problem = "-";

    if (detailCount.isNotEmpty) {

      var sorted = detailCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      problem = sorted.first.key;

    }

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(
          children: [

            const Icon(Icons.insights, color: Color(0xFF6E9F8D)),
            const SizedBox(width: 8),

            Text(
              "สรุปการนั่งวันนี้ ($level)",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [

            const Icon(Icons.percent, size: 18),
            const SizedBox(width: 6),

            Text("อัตราท่านั่งถูกต้อง ${percent.toStringAsFixed(1)}%"),

          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [

            const Icon(Icons.error_outline, size: 18),
            const SizedBox(width: 6),

            Text("นั่งผิดทั้งหมด $incorrectTotal ครั้ง"),

          ],
        ),

        if (problem != "-") ...[

          const SizedBox(height: 10),

          const Row(
            children: [
              Icon(Icons.search, size: 18),
              SizedBox(width: 6),
              Text("ปัญหาที่พบบ่อย"),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            problem,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

        ],

      ],

    );

  }
}

