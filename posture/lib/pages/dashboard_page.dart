import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'history_page.dart';

class DashboardPage extends StatefulWidget {
  final String deviceName;

  const DashboardPage({
    super.key,
    required this.deviceName,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  /// Firebase reference
  late final DatabaseReference ref;

  /// list history สำหรับ dashboard
  List<Map<String, dynamic>> historyList = [];

  /// posture ล่าสุด
  double currentPitch = 0;
  double currentRoll = 0;
  String currentPosture = "unknown";
  String currentPostureDetail = "";

  @override
  void initState() {
    super.initState();

    /// path firebase
    ref = FirebaseDatabase.instance.ref("${widget.deviceName}/history");

    /// เริ่มฟังข้อมูล realtime
    listenHistory();
  }

  /// ฟังข้อมูล realtime จาก firebase
  void listenHistory() {

    ref.onValue.listen((event) {

      final data = event.snapshot.value;

      if (data == null || data is! Map) return;

      final Map<dynamic, dynamic> historyData = data;

      List<Map<String, dynamic>> tempList = [];

      /// loop โครงสร้าง firebase
      historyData.forEach((date, dateValue) {

        if (dateValue is Map) {

          dateValue.forEach((time, value) {

            if (value is Map) {

              tempList.add({

                /// วันที่
                "date": date,

                /// firebase เก็บเวลาแบบ 00-22-32
                "time": time.toString().replaceAll("-", ":"),

                "pitch": (value["pitch"] ?? 0).toDouble(),
                "roll": (value["roll"] ?? 0).toDouble(),

                "posture": value["posture"] ?? "unknown",
                "postureDetail": value["postureDetail"]?.toString() ?? "",

              });

            }

          });

        }

      });

      /// เรียงข้อมูลใหม่ -> เก่า
      tempList.sort(
        (a, b) =>
            "${b["date"]} ${b["time"]}".compareTo("${a["date"]} ${a["time"]}"),
      );

      setState(() {

        /// สร้าง list สำหรับ dashboard
        historyList = buildDashboardList(tempList);

        /// record แรกคือข้อมูลล่าสุด
        if (historyList.isNotEmpty) {

          currentPitch = historyList.first["pitch"];
          currentRoll = historyList.first["roll"];

          currentPosture = historyList.first["posture"];
          currentPostureDetail = historyList.first["postureDetail"];

        }

      });

    });

  }

  /// สร้าง list สำหรับ dashboard
  /// วันล่าสุด = 2 record
  /// วันก่อนหน้า = 1 record
  /// แสดงสูงสุด 3 วัน
  List<Map<String, dynamic>> buildDashboardList(List<Map<String, dynamic>> history) {

    Map<String, List<Map<String, dynamic>>> grouped = {};

    /// group ตาม date
    for (var item in history) {

      String date = item["date"];

      grouped.putIfAbsent(date, () => []);

      grouped[date]!.add(item);

    }

    /// เรียงวันใหม่ -> เก่า
    List<String> sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    List<Map<String, dynamic>> result = [];

    for (int i = 0; i < sortedDates.length && i < 3; i++) {

      String date = sortedDates[i];
      var items = grouped[date]!;

      /// เรียงเวลา
      items.sort((a, b) => b["time"].compareTo(a["time"]));

      if (i == 0) {

        /// วันล่าสุดโชว์ 2 record
        result.addAll(items.take(2));

      } else {

        /// วันก่อนหน้าโชว์ 1 record
        result.add(items.first);

      }

    }

    return result;

  }

  /// format วันที่
  String formatDateOnly(String date) {

    final dateTime = DateTime.parse(date);

    return DateFormat("d MMM yyyy").format(dateTime);

  }

  /// สี posture
  Color postureColor(String posture) {

    switch (posture) {

      case "correct":
        return const Color(0xFF6E9F8D);

      case "incorrect":
        return Colors.redAccent;

      case "unknown":
        return Colors.orange;

      default:
        return Colors.grey;

    }

  }

  /// ข้อความ posture
  String postureText(String posture) {

    switch (posture) {

      case "correct":
        return "Sitting Correct";

      case "incorrect":
        return "Sitting Incorrect";

      case "unknown":
        return "Not Calibrated";

      default:
        return "Unknown";

    }

  }

  /// detail posture
  String postureDetailText(String posture, String detail) {

    switch (posture) {

      case "correct":
        return "ท่านั่งปกติ";

      case "incorrect":
        return detail.isNotEmpty ? detail : "ท่านั่งไม่ถูกต้อง";

      case "unknown":
        return "กรุณาปรับเทียบอุปกรณ์ก่อนใช้งาน";

      default:
        return "";

    }

  }

  /// card pitch / roll
  Widget buildStatCard(String title, String value, IconData icon) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF6E9F8D),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(icon, color: Colors.white),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

        ],

      ),

    );

  }

  /// ไปหน้า history (default)
  void goToHistory() {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(deviceName: widget.deviceName),
      ),
    );

  }

  /// ไปหน้า history ของวันนั้น
  void goToHistoryWithDate(String date) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          deviceName: widget.deviceName,
          selectedDate: date,
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F7F6),

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(20),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dashboard - ${widget.deviceName}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: goToHistory,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// pitch roll
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        "Pitch",
                        "${currentPitch.toStringAsFixed(2)}°",
                        Icons.swap_vert,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: buildStatCard(
                        "Roll",
                        "${currentRoll.toStringAsFixed(2)}°",
                        Icons.swap_horiz,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// current posture
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Current Posture",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      postureText(currentPosture),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: postureColor(currentPosture),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      postureDetailText(
                          currentPosture, currentPostureDetail),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Latest History + ลูกศร
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Latest History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: goToHistory,
                  ),

                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: historyList.isEmpty
                    ? const Center(child: Text("No Data"))
                    : ListView.builder(
                        itemCount: historyList.length,
                        itemBuilder: (context, index) {

                          final item = historyList[index];

                          bool showDateHeader = true;

                          if (index > 0) {
                            final prev = historyList[index - 1];
                            showDateHeader =
                                prev["date"] != item["date"];
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// DATE HEADER (กดไป history ของวันนั้นได้)
                              if (showDateHeader)
                                InkWell(
                                  onTap: () {
                                    goToHistoryWithDate(item["date"]);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [

                                        Text(
                                          formatDateOnly(item["date"]),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),

                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.black38,
                                        ),

                                      ],
                                    ),
                                  ),
                                ),

                              /// card
                              InkWell(
                                onTap: () {
                                  goToHistoryWithDate(item["date"]);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [

                                          Text(
                                            item["time"],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),

                                          Text(
                                            "Pitch: ${item["pitch"].toStringAsFixed(2)}° | Roll: ${item["roll"].toStringAsFixed(2)}°",
                                          ),

                                          if ((item["postureDetail"] ?? "")
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              item["postureDetail"],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),

                                        ],
                                      ),

                                      Text(
                                        item["posture"].toString().toUpperCase(),
                                        style: TextStyle(
                                          color: postureColor(item["posture"]),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

