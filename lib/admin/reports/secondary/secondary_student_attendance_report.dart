import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import 'package:fl_chart/fl_chart.dart';


class SecondaryStudentAttendanceReport extends StatefulWidget {
  const SecondaryStudentAttendanceReport({super.key});

  @override
  State<SecondaryStudentAttendanceReport> createState() =>
      _SecondaryStudentAttendanceReportState();
}

class _SecondaryStudentAttendanceReportState
    extends State<SecondaryStudentAttendanceReport> {
  static const Color navy = Color(0xFF0D1B2A);

  DateTime selectedDate = DateTime.now();
  bool isMonthly = false; // false = Daily, true = Monthly
  DateTime? fromDate;
  DateTime? toDate;

  final Map<String, List<dynamic>> _cache = {};
  final Set<String> _loading = {};
 

/* ================= LOAD STUDENTS (DAILY + MONTHLY) ================= */

Future<void> loadStudents(String std, String div) async {
  final key = "$std-$div";

  // Block monthly until date range selected
  if (isMonthly && (fromDate == null || toDate == null)) {
    return;
  }

  if (_cache.containsKey(key)) return;

  setState(() => _loading.add(key));

  try {
    late Uri url;

    if (isMonthly) {
      // ✅ MONTHLY API
      final from =
          "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}";

      final to =
          "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";

      url = Uri.parse(
        "$SERVER_URL/attendance/monthly-list?std=$std&div=$div&from=$from&to=$to",
      );

    } else {
      // ✅ DAILY API
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      url = Uri.parse(
        "$SERVER_URL/attendance/list?std=$std&div=$div&date=$dateStr",
      );
    }

    print("API CALL → $url"); // ⭐ DEBUG (important)

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      print("API RESPONSE → ${data["students"]?.first}"); // ⭐ DEBUG

      setState(() {
        _cache[key] = data["students"] ?? [];
      });
    }
  } catch (e) {
    debugPrint("Load students error: $e");
  }

  setState(() => _loading.remove(key));
}

  /* ================= DATE PICKER (DAILY) ================= */

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _cache.clear();
        _loading.clear();
      });
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text('Secondary Student Attendance'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: isMonthly ? null : pickDate,
            tooltip: "Select Date",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _reportTypeToggle(),
          isMonthly ? _fromToBanner() : _dateBanner(),
          stdTile('9'),
          stdTile('10'),
          stdTile('11'),
          stdTile('12'),
        ],
      ),
    );
  }

  /* ================= DAILY / MONTHLY TOGGLE ================= */

  Widget _reportTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<bool>(
              title: const Text("Daily"),
              value: false,
              groupValue: isMonthly,
              onChanged: (v) {
                setState(() {
                  isMonthly = false;
                  _cache.clear();
                  _loading.clear();
                });
              },
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              title: const Text("Monthly"),
              value: true,
              groupValue: isMonthly,
              onChanged: (v) {
                setState(() {
                  isMonthly = true;
                  _cache.clear();
                  _loading.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /* ================= DAILY DATE BANNER ================= */

  Widget _dateBanner() {
    final dateStr =
        "${selectedDate.day.toString().padLeft(2, '0')}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.year}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        "Date: $dateStr",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
    );
  }

  /* ================= MONTHLY FROM–TO BANNER ================= */

  Widget _fromToBanner() {
    String format(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                fromDate == null ? "From Date" : format(fromDate!),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fromDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    fromDate = picked;
                    _cache.clear();
                    _loading.clear();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                toDate == null ? "To Date" : format(toDate!),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: toDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    toDate = picked;
                    _cache.clear();
                    _loading.clear();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /* ================= STD TILE ================= */

  Widget stdTile(String std) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          'STD $std',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: navy,
          ),
        ),
        children: ['A', 'B', 'C']
            .map((div) => divisionBlock(std, div))
            .toList(),
      ),
    );
  }

/* ================= DIV BLOCK ================= */

Widget divisionBlock(String std, String div) {

  List<String> dateLabels = [];

  if (fromDate != null && toDate != null) {
    DateTime temp = fromDate!;

    while (!temp.isAfter(toDate!)) {
      dateLabels.add("${temp.day}/${temp.month}");
      temp = temp.add(const Duration(days: 1));
    }
  }

  final key = "$std-$div";
  final students = _cache[key];

  int totalStudents = students?.length ?? 0;

  double avgAttendance = 0;
  int lowAttendanceCount = 0;

  if (students != null && isMonthly) {
    double totalPercent = 0;

    for (var s in students) {
      double percent =
          double.tryParse(s["percentage"] ?? "0") ?? 0;

      totalPercent += percent;

      if (percent < 75) {
        lowAttendanceCount++;
      }
    }

    if (students.isNotEmpty) {
      avgAttendance = totalPercent / students.length;
    }
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        InkWell(
          onTap: () => loadStudents(std, div),
          child: Text(
            "DIV $div",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ),

        const SizedBox(height: 6),

        if (students != null && isMonthly)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Class Monthly Summary",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Total Students: $totalStudents"),
                Text("Avg Attendance: ${avgAttendance.toStringAsFixed(2)}%"),
                Text("Below 75%: $lowAttendanceCount Students"),
              ],
            ),
          ),

        // ⭐ PIE CHART
        if (students != null && isMonthly)
          Builder(
            builder: (context) {

              int totalPresent = students.fold<int>(
                0,
                (sum, s) => sum + ((s["presentDays"] ?? 0) as int),
              );

              int totalAbsent = students.fold<int>(
                0,
                (sum, s) => sum + ((s["absentDays"] ?? 0) as int),
              );

              int totalLate = students.fold<int>(
                0,
                (sum, s) => sum + ((s["lateDays"] ?? 0) as int),
              );

              return Container(
                height: 220,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: totalPresent.toDouble(),
                        title: "Present",
                        color: Colors.green,
                      ),
                      PieChartSectionData(
                        value: totalAbsent.toDouble(),
                        title: "Absent",
                        color: Colors.red,
                      ),
                      PieChartSectionData(
                        value: totalLate.toDouble(),
                        title: "Late",
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // ⭐ TREND GRAPH
        if (students != null && isMonthly)
          Container(
            height: 220,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt() - 1;

                        if (index >= 0 && index < dateLabels.length) {
                          return Text(
                            dateLabels[index],
                            style: const TextStyle(fontSize: 10),
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      students.length,
                      (index) {
                        final percent =
                            double.tryParse(students[index]["percentage"] ?? "0") ?? 0;

                        return FlSpot(
                          (index + 1).toDouble(),
                          percent,
                        );
                      },
                    ),
                    isCurved: true,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),

        if (_loading.contains(key))
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

        if (students != null)
          ...students.map(
            (s) => StudentRow(
              roll: s["rollNo"],
              name: s["name"],
              status: isMonthly ? null : s["status"],
              presentDays: isMonthly ? s["presentDays"] : null,
              absentDays: isMonthly ? s["absentDays"] : null,
              lateDays: isMonthly ? s["lateDays"] : null,
              percentage: isMonthly ? s["percentage"] : null,
            ),
          ),
      ],
    ),
  );
}

/* ================= STUDENT ROW ================= */

class StudentRow extends StatelessWidget {
  final int roll;
  final String name;

  // DAILY
  final String? status;

  // MONTHLY
  final int? presentDays;
  final int? absentDays;
  final int? lateDays;
  final String? percentage;

  const StudentRow({
    super.key,
    required this.roll,
    required this.name,
    this.status,
    this.presentDays,
    this.absentDays,
    this.lateDays,
    this.percentage,
  });

 @override
Widget build(BuildContext context) {
  final bool isMonthlyView = presentDays != null;

  // ⭐ Attendance check
  double percentValue =
      double.tryParse(percentage ?? "0") ?? 0;

  bool isLowAttendance = percentValue < 75;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: isLowAttendance
        ? BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          )
        : null,
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            roll.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name),


                // ✅ MONTHLY DATA DISPLAY
                if (isMonthlyView)
                  Text(
                   "Present: $presentDays   Absent: $absentDays   Late: $lateDays   Attendance: ${percentage ?? "0"}%",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                // ✅ DAILY STATUS ICON
                if (!isMonthlyView && status != null)
                  _statusIcon(status!),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _statusIcon(String status) {
    switch (status) {
      case "present":
        return const Icon(Icons.check_circle, color: Colors.green);
      case "absent":
        return const Icon(Icons.cancel, color: Colors.red);
      case "late":
        return const Icon(Icons.access_time, color: Colors.orange);
      default:
        return const SizedBox();
    }
  }
}
