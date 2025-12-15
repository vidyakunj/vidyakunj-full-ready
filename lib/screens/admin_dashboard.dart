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
  DateTime selectedDate = DateTime.now();

  bool loading = false;
  List<Map<String, dynamic>> classSummaries = [];

  int primaryTotal = 0;
  int primaryPresent = 0;
  int primaryAbsent = 0;

  int secondaryTotal = 0;
  int secondaryPresent = 0;
  int secondaryAbsent = 0;

  int schoolTotal = 0;
  int schoolPresent = 0;
  int schoolAbsent = 0;

  /// STD–DIV structure used in your school
  final Map<String, List<String>> stdDivMap = {
    "1": ["A", "B", "C", "D"],
    "2": ["A", "B", "C", "D"],
    "3": ["A", "B", "C", "D"],
    "4": ["A", "B", "C", "D"],
    "5": ["A", "B", "C", "D"],
    "6": ["A", "B", "C", "D"],
    "7": ["A", "B", "C", "D"],
    "8": ["A", "B", "C", "D"],
    "9": ["A", "B", "C", "D"],
    "10": ["A", "B", "C", "D"],
    "11": ["A", "B", "C", "D"],
    "12": ["A", "B", "C", "D"],
  };

  String get dateStr =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      classSummaries.clear();

      primaryTotal = 0;
      primaryPresent = 0;
      primaryAbsent = 0;
      secondaryTotal = 0;
      secondaryPresent = 0;
      secondaryAbsent = 0;
      schoolTotal = 0;
      schoolPresent = 0;
      schoolAbsent = 0;
    });

    for (final std in stdDivMap.keys) {
      for (final div in stdDivMap[std]!) {
        final uri = Uri.parse(
          "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div",
        );

        try {
          final res = await http.get(uri);
          if (res.statusCode != 200) continue;

          final data = jsonDecode(res.body);
          if (data["success"] != true) continue;

          final s = data["summary"];

          final int total = (s["total"] as num).toInt();
          final int present = (s["present"] as num).toInt();
          final int absent = (s["absent"] as num).toInt();

          if (total == 0) continue;

          classSummaries.add({
            "std": std,
            "div": div,
            "total": total,
            "present": present,
            "absent": absent,
          });

          schoolTotal += total;
          schoolPresent += present;
          schoolAbsent += absent;

          final stdNo = int.parse(std);
          if (stdNo <= 8) {
            primaryTotal += total;
            primaryPresent += present;
            primaryAbsent += absent;
          } else {
            secondaryTotal += total;
            secondaryPresent += present;
            secondaryAbsent += absent;
          }
        } catch (_) {}
      }
    }

    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Widget summaryCard(String title, int total, int present, int absent) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Total: $total  |  Present: $present  |  Absent: $absent"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Attendance Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ElevatedButton(
                        child: Text("Select Date ($dateStr)"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                            loadSummary();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    summaryCard(
                      "PRIMARY SECTION (STD 1–8)",
                      primaryTotal,
                      primaryPresent,
                      primaryAbsent,
                    ),
                    const SizedBox(height: 10),

                    summaryCard(
                      "SECONDARY & HIGHER SECONDARY (STD 9–12)",
                      secondaryTotal,
                      secondaryPresent,
                      secondaryAbsent,
                    ),
                    const SizedBox(height: 10),

                    summaryCard(
                      "WHOLE SCHOOL SUMMARY",
                      schoolTotal,
                      schoolPresent,
                      schoolAbsent,
                    ),

                    const Divider(height: 30),
                    const Text(
                      "CLASS WISE SUMMARY",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    ...classSummaries.map((e) => Card(
                          child: ListTile(
                            title: Text(
                                "STD ${e['std']}  |  DIV ${e['div']}"),
                            subtitle: Text(
                                "Total: ${e['total']}  |  Present: ${e['present']}  |  Absent: ${e['absent']}"),
                          ),
                        )),
                  ],
                ),
              ),
      ),
    );
  }
}
