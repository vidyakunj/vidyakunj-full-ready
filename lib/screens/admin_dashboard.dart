import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // MODE: true = Date Range, false = Single Day
  bool isRangeMode = false;

  DateTime selectedDate = DateTime.now();
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();

  bool loading = false;
  String? errorMessage;

  List<Map<String, dynamic>> primary = [];
  List<Map<String, dynamic>> secondary = [];

  Map<String, dynamic> schoolTotal = {
    "total": 0,
    "present": 0,
    "absent": 0,
    "late": 0,
    "attendancePercent": 0
  };

  /* =============================
     LOAD SUMMARY (AUTO MODE)
     ============================= */
  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      late String url;

      if (isRangeMode) {
        final from =
            "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
        final to =
            "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";

        url =
            "$SERVER_URL/attendance/summary-school-range?from=$from&to=$to";
      } else {
        final date =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

        url = "$SERVER_URL/attendance/summary-school?date=$date";
      }

      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        throw "Server error";
      }

      final data = jsonDecode(res.body);

      setState(() {
        primary = List<Map<String, dynamic>>.from(data["primary"] ?? []);
        secondary = List<Map<String, dynamic>>.from(data["secondary"] ?? []);
        schoolTotal = data["schoolTotal"] ??
            {
              "total": 0,
              "present": 0,
              "absent": 0,
              "late": 0,
              "attendancePercent": 0
            };
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load summary";
      });
    }

    setState(() => loading = false);
  }

  /* =============================
     UI
     ============================= */
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Attendance Summary"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// MODE BUTTONS
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRangeMode ? Colors.grey : navy,
                  ),
                  onPressed: () {
                    setState(() => isRangeMode = false);
                  },
                  child: const Text("Single Day"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRangeMode ? navy : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => isRangeMode = true);
                  },
                  child: const Text("Date Range"),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// DATE PICKERS
            if (!isRangeMode)
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Text(
                  "Select Date (${selectedDate.toIso8601String().split('T')[0]})",
                ),
              ),

            if (isRangeMode) ...[
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fromDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => fromDate = picked);
                  }
                },
                child: Text(
                  "From (${fromDate.toIso8601String().split('T')[0]})",
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: toDate,
                    firstDate: fromDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => toDate = picked);
                  }
                },
                child: Text(
                  "To (${toDate.toIso8601String().split('T')[0]})",
                ),
              ),
            ],

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loadSummary,
              child: const Text("Load Summary"),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Center(child: CircularProgressIndicator()),

            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            if (!loading && errorMessage == null) ...[
              _schoolTotalCard(),
              const SizedBox(height: 30),

              _sectionTitle("Primary (STD 1–8)"),
              _summaryTable(primary),

              const SizedBox(height: 40),

              _sectionTitle("Secondary (STD 9–12)"),
              _summaryTable(secondary),
            ],
          ],
        ),
      ),
    );
  }

  /* =============================
     UI HELPERS
     ============================= */

  Widget _schoolTotalCard() {
    return Card(
      color: Colors.green[100],
      child: ListTile(
        title: const Text(
          "School Total",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Total: ${schoolTotal["total"]} | "
          "Present: ${schoolTotal["present"]} | "
          "Absent: ${schoolTotal["absent"]} | "
          "Late: ${schoolTotal["late"]} | "
          "%: ${schoolTotal["attendancePercent"]}%",
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _summaryTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text("No data available"),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            MaterialStateProperty.all(Colors.blueGrey.shade50),
        columns: const [
          DataColumn(label: Text("STD")),
          DataColumn(label: Text("DIV")),
          DataColumn(label: Text("Students")),
          DataColumn(label: Text("Present")),
          DataColumn(label: Text("Absent")),
          DataColumn(label: Text("Late")),
          DataColumn(label: Text("%")),
        ],
        rows: data.map((r) {
          return DataRow(cells: [
            DataCell(Text(r["std"].toString())),
            DataCell(Text(r["div"].toString())),
            DataCell(Text(r["totalStudents"]?.toString() ??
                r["total"].toString())),
            DataCell(Text(r["present"].toString())),
            DataCell(Text(r["absent"].toString())),
            DataCell(
              Text(
                r["late"].toString(),
                style: TextStyle(
                  color: r["late"] > 0 ? Colors.red : Colors.black,
                  fontWeight:
                      r["late"] > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            DataCell(Text("${r["attendancePercent"]}%")),
          ]);
        }).toList(),
      ),
    );
  }
}
