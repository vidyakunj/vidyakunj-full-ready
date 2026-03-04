import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

class StudentAttendanceReportEngine extends StatefulWidget {
  final String title;
  final List<String> stdList;

  const StudentAttendanceReportEngine({
    super.key,
    required this.title,
    required this.stdList,
  });

  @override
  State<StudentAttendanceReportEngine> createState() =>
      _StudentAttendanceReportEngineState();
}

class _StudentAttendanceReportEngineState
    extends State<StudentAttendanceReportEngine> {
  static const Color navy = Color(0xFF0D1B2A);

  DateTime selectedDate = DateTime.now();
  bool isMonthly = false;
  DateTime? fromDate;
  DateTime? toDate;

  final Map<String, List<dynamic>> _cache = {};
  final Set<String> _loading = {};

  /* ================= API ================= */

  Future<void> loadStudents(String std, String div) async {
    final key = "$std-$div";
    if (isMonthly && (fromDate == null || toDate == null)) return;
    if (_cache.containsKey(key)) return;

    setState(() => _loading.add(key));

    try {
      late Uri url;

      if (isMonthly) {
        final from =
            "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}";
        final to =
            "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";

        url = Uri.parse(
            "$SERVER_URL/attendance/monthly-list?std=$std&div=$div&from=$from&to=$to");
      } else {
        final dateStr =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

        url = Uri.parse(
            "$SERVER_URL/attendance/list?std=$std&div=$div&date=$dateStr");
      }

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cache[key] = data["students"] ?? [];
        });
      }
    } catch (_) {}

    setState(() => _loading.remove(key));
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _toggle(),
          isMonthly ? _fromToBanner() : _dateBanner(),
          ...widget.stdList.map((std) => _stdTile(std)),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<bool>(
            title: const Text("Daily"),
            value: false,
            groupValue: isMonthly,
            onChanged: (_) {
              setState(() {
                isMonthly = false;
                _cache.clear();
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: const Text("Monthly"),
            value: true,
            groupValue: isMonthly,
            onChanged: (_) {
              setState(() {
                isMonthly = true;
                _cache.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _dateBanner() {
    final d =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";
    return Text("Date: $d",
        style: const TextStyle(fontWeight: FontWeight.bold));
  }

  Widget _fromToBanner() {
    String f(DateTime d) => "${d.day}-${d.month}-${d.year}";
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: fromDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now());
              if (picked != null) {
                setState(() {
                  fromDate = picked;
                  _cache.clear();
                });
              }
            },
            child: Text(fromDate == null ? "From Date" : f(fromDate!)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: toDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now());
              if (picked != null) {
                setState(() {
                  toDate = picked;
                  _cache.clear();
                });
              }
            },
            child: Text(toDate == null ? "To Date" : f(toDate!)),
          ),
        ),
      ],
    );
  }

  Widget _stdTile(String std) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text("STD $std",
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: navy)),
        children: ["A", "B", "C","D"]
            .map((div) => _divisionBlock(std, div))
            .toList(),
      ),
    );
  }

  /* ================= DIVISION BLOCK ================= */

  Widget _divisionBlock(String std, String div) {
    final key = "$std-$div";
    final students = _cache[key];

    if (students != null && !isMonthly) {
      students.sort((a, b) {
        int order(String s) {
          switch (s) {
            case "absent":
              return 0;
            case "late":
              return 1;
            case "present":
              return 2;
            default:
              return 3;
          }
        }

        return order(a["status"]).compareTo(order(b["status"]));
      });
    }

    return Padding(
  padding: const EdgeInsets.all(8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => loadStudents(std, div),
        child: Text("DIV $div",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),

      const SizedBox(height: 6),

      if (_loading.contains(key))
        const CircularProgressIndicator(strokeWidth: 2),

      if (students != null) ...[
        isMonthly
            ? _monthlySummary(students)
            : _dailySummary(students),

        if (isMonthly) _monthlyCharts(students),

        if (!isMonthly) _smartEntryPanel(students),

        // 🔴 BELOW 75% PANEL
        if (isMonthly)
          Builder(
            builder: (_) {
              final lowStudents = students.where((s) {
                final percent =
                    double.tryParse(s["percentage"]?.toString() ?? "0") ?? 0;
                return percent < 75;
              }).toList();

              if (lowStudents.isEmpty) {
                return const SizedBox();
              }

              return Card(
                color: Colors.red.withOpacity(0.08),
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                    "⚠ Students Below 75% (${lowStudents.length})",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  children: lowStudents.map((s) {
                    final p = double.tryParse(
                            s["percentage"]?.toString() ?? "0") ??
                        0;

                    return ListTile(
                      title: Text(s["name"]),
                      trailing: Text("${p.toStringAsFixed(1)}%"),
                    );
                  }).toList(),
                ),
              );
            },
          ),

        ...students.map((s) => _studentRow(s)),
      ],
    ],
  ),
);
}
  /* ================= DAILY SUMMARY ================= */

  Widget _dailySummary(List students) {
    int total = students.length;
    int present =
        students.where((s) => s["status"] == "present").length;
    int absent =
        students.where((s) => s["status"] == "absent").length;
    int late =
        students.where((s) => s["status"] == "late").length;

    double percent =
        total == 0 ? 0 : (present / total) * 100;

    return _summaryBox(
        "Class Daily Summary",
        [
          "Total: $total",
          "Present: $present",
          "Absent: $absent",
          "Late: $late",
          "Attendance: ${percent.toStringAsFixed(2)}%"
        ],
        Colors.green);
  }

  /* ================= MONTHLY SUMMARY ================= */

  Widget _monthlySummary(List students) {
    double avg = 0;
    int below75 = 0;

    for (var s in students) {
      double p =
          double.tryParse(s["percentage"]?.toString() ?? "0") ?? 0;
      avg += p;
      if (p < 75) below75++;
    }

    if (students.isNotEmpty) avg /= students.length;

    return _summaryBox(
        "Class Monthly Summary",
        [
          "Total Students: ${students.length}",
          "Average Attendance: ${avg.toStringAsFixed(2)}%",
          "Below 75%: $below75 Students"
        ],
        Colors.blue);
  }

  Widget _summaryBox(
      String title, List<String> lines, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...lines.map((e) => Text(e)),
        ],
      ),
    );
  }

  /* ================= MONTHLY CHARTS ================= */

  Widget _monthlyCharts(List students) {
int totalPresent = students.fold<int>(
  0,
  (sum, s) => sum + ((s["presentDays"] ?? 0) as num).toInt(),
);

int totalAbsent = students.fold<int>(
  0,
  (sum, s) => sum + ((s["absentDays"] ?? 0) as num).toInt(),
);

int totalLate = students.fold<int>(
  0,
  (sum, s) => sum + ((s["lateDays"] ?? 0) as num).toInt(),
);
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(PieChartData(sections: [
            PieChartSectionData(
                value: totalPresent.toDouble(),
                color: Colors.green,
                title: "Present"),
            PieChartSectionData(
                value: totalAbsent.toDouble(),
                color: Colors.red,
                title: "Absent"),
            PieChartSectionData(
                value: totalLate.toDouble(),
                color: Colors.orange,
                title: "Late"),
          ])),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(LineChartData(
              lineBarsData: [
                LineChartBarData(
                    spots: List.generate(students.length,
                        (i) {
                      final p =
                          double.tryParse(students[i]
                                  ["percentage"]
                                  ?.toString() ??
                              "0") ??
                              0;
                      return FlSpot(
                          (i + 1).toDouble(), p);
                    }),
                    isCurved: true,
                    dotData:
                        FlDotData(show: true))
              ])),
        )
      ],
    );
  }

  /* ================= SMART ENTRY ================= */

  Widget _smartEntryPanel(List students) {
    final absentees = students
        .where((s) => s["status"] == "absent")
        .toList();

    if (absentees.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text("Absent Students",
              style: TextStyle(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...absentees.map((s) {
            final name = s["name"];
            return Row(
              children: [
                Expanded(child: Text(name)),
                IconButton(
                  icon: const Icon(
                      Icons.copy_outlined,
                      size: 16),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: name));
                  },
                )
              ],
            );
          })
        ],
      ),
    );
  }

/* ================= STUDENT ROW ================= */

Widget _studentRow(Map s) {
  final percent =
      double.tryParse(s["percentage"]?.toString() ?? "0") ?? 0;

  Color? bgColor;

  if (isMonthly) {
    if (percent < 50) {
      bgColor = Colors.red.withOpacity(0.25);
    } else if (percent < 60) {
      bgColor = Colors.red.withOpacity(0.18);
    } else if (percent < 75) {
      bgColor = Colors.red.withOpacity(0.10);
    }
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(8),
    decoration: bgColor != null
        ? BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          )
        : null,
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(s["rollNo"].toString()),
        ),
        Expanded(child: Text(s["name"])),

        if (!isMonthly)
          _statusIcon(s["status"]),

        if (isMonthly)
          Text("${percent.toStringAsFixed(1)}%"),
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

}  // <-- ADD THIS LINE
