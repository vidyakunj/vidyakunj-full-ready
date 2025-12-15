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

  bool loading = false;

  Future<void> loadSummary() async {
    setState(() => loading = true);

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      // 🔹 Backend already returns class-wise summary
      final res = await http.get(
        Uri.parse("$SERVER_URL/attendance/summary?date=$dateStr"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Expecting list of { std, div, total, present, absent }
        final List list = data["summary"] ?? [];

        setState(() {
          classSummary = list
              .map<Map<String, dynamic>>((e) => {
                    "std": int.parse(e["std"].toString()),
                    "div": e["div"].toString(),
                    "total": (e["total"] as num).toInt(),
                    "present": (e["present"] as num).toInt(),
                    "absent": (e["absent"] as num).toInt(),
                  })
              .toList()
            ..sort((a, b) => a["std"].compareTo(b["std"]));
        });
      } else {
        _showError();
      }
    } catch (_) {
      _showError();
    }

    setState(() => loading = false);
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to load summary")),
    );
  }

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    int primaryTotal = 0, primaryPresent = 0, primaryAbsent = 0;
    int secondaryTotal = 0, secondaryPresent = 0, secondaryAbsent = 0;

    for (final row in classSummary) {
      final int std = row["std"];
      final int total = row["total"];
      final int present = row["present"];
      final int absent = row["absent"];

      if (std >= 1 && std <= 8) {
        primaryTotal += total;
        primaryPresent += present;
        primaryAbsent += absent;
      } else if (std >= 9 && std <= 12) {
        secondaryTotal += total;
        secondaryPresent += present;
        secondaryAbsent += absent;
      }
    }

    final int schoolTotal = primaryTotal + secondaryTotal;
    final int schoolPresent = primaryPresent + secondaryPresent;
    final int schoolAbsent = primaryAbsent + secondaryAbsent;

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Attendance Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
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
                          loadSummary();
                        }
                      },
                      child: Text(
                        "Select Date (${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')})",
                      ),
                    ),

                    const SizedBox(height: 20),

                    _sectionCard(
                      "PRIMARY SECTION (STD 1–8)",
                      primaryTotal,
                      primaryPresent,
                      primaryAbsent,
                    ),

                    _sectionCard(
                      "SECONDARY & HIGHER SECONDARY (STD 9–12)",
                      secondaryTotal,
                      secondaryPresent,
                      secondaryAbsent,
                    ),

                    _sectionCard(
                      "WHOLE SCHOOL SUMMARY",
                      schoolTotal,
                      schoolPresent,
                      schoolAbsent,
                    ),

                    const Divider(height: 40),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "CLASS WISE SUMMARY",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...classSummary.map((e) {
                      return Card(
                        child: ListTile(
                          title:
                              Text("STD ${e['std']}  |  DIV ${e['div']}"),
                          subtitle: Text(
                            "Total: ${e['total']}  |  Present: ${e['present']}  |  Absent: ${e['absent']}",
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

  Widget _sectionCard(
      String title, int total, int present, int absent) {
    return Card(
      color: Colors.yellow[100],
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Total: $total  |  Present: $present  |  Absent: $absent",
        ),
      ),
    );
  }
}
