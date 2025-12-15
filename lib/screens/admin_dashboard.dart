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

  List<Map<String, dynamic>> classSummary = [];

  int primaryTotal = 0, primaryPresent = 0, primaryAbsent = 0;
  int secondaryTotal = 0, secondaryPresent = 0, secondaryAbsent = 0;

  bool loading = false;

  final List<String> stds = [
    "1","2","3","4","5","6","7","8",
    "9","10","11","12"
  ];

  final List<String> divs = ["A","B","C","D"];

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      classSummary.clear();
      primaryTotal = primaryPresent = primaryAbsent = 0;
      secondaryTotal = secondaryPresent = secondaryAbsent = 0;
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    for (final std in stds) {
      for (final div in divs) {
        try {
          final uri = Uri.parse(
            "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div",
          );

          final res = await http.get(uri);

          if (res.statusCode != 200) continue;

          final data = jsonDecode(res.body);
          if (data["success"] != true) continue;

          final summary = data["summary"];
          if (summary["total"] == 0) continue;

          final total = summary["total"] ?? 0;
          final present = summary["present"] ?? 0;
          final absent = summary["absent"] ?? 0;

          classSummary.add({
            "std": std,
            "div": div,
            "total": total,
            "present": present,
            "absent": absent,
          });

          final stdNum = int.parse(std);
          if (stdNum <= 8) {
            primaryTotal += total;
            primaryPresent += present;
            primaryAbsent += absent;
          } else {
            secondaryTotal += total;
            secondaryPresent += present;
            secondaryAbsent += absent;
          }
        } catch (_) {
          // safely ignore
        }
      }
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        title: const Text("Admin Attendance Summary"),
        backgroundColor: const Color(0xFF110E38),
      ),
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
                        child: Text(
                          "Select Date (${selectedDate.toString().split(' ')[0]})",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _summaryCard(
                      "PRIMARY SECTION (STD 1–8)",
                      primaryTotal,
                      primaryPresent,
                      primaryAbsent,
                    ),

                    _summaryCard(
                      "SECONDARY & HIGHER SECONDARY (STD 9–12)",
                      secondaryTotal,
                      secondaryPresent,
                      secondaryAbsent,
                    ),

                    _summaryCard(
                      "WHOLE SCHOOL SUMMARY",
                      primaryTotal + secondaryTotal,
                      primaryPresent + secondaryPresent,
                      primaryAbsent + secondaryAbsent,
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const Text(
                      "CLASS WISE SUMMARY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...classSummary.map((e) {
                      return Card(
                        child: ListTile(
                          title: Text("STD ${e['std']}  |  DIV ${e['div']}"),
                          subtitle: Text(
                            "Total: ${e['total']} | Present: ${e['present']} | Absent: ${e['absent']}",
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summaryCard(
      String title, int total, int present, int absent) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Total: $total | Present: $present | Absent: $absent",
        ),
      ),
    );
  }
}
