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

  final List<Map<String, dynamic>> classSummaries = [];

  final List<String> stdList = ["9", "10", "11", "12"];
  final List<String> divList = ["A", "B", "C", "D"];

  /* =======================================================
     LOAD SUMMARY (STD 9–12 ONLY)
     ======================================================= */
  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      classSummaries.clear();
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    for (final std in stdList) {
      for (final div in divList) {
        final uri = Uri.parse(
          "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div",
        );

        try {
          final res = await http.get(uri);

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);

            if (data["success"] == true) {
              final summary = data["summary"];

              classSummaries.add({
                "std": std,
                "div": div,
                "total": (summary["total"] as num).toInt(),
                "present": (summary["present"] as num).toInt(),
                "absent": (summary["absent"] as num).toInt(),
              });
            }
          }
        } catch (_) {
          // silently ignore failed class/div
        }
      }
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Attendance Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /* ================= DATE PICKER ================= */
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                  await loadSummary();
                }
              },
              child: Text(
                "Select Date (${selectedDate.toIso8601String().split("T")[0]})",
              ),
            ),

            const SizedBox(height: 20),

            /* ================= CONTENT ================= */
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : classSummaries.isEmpty
                      ? const Center(child: Text("No data available"))
                      : ListView(
                          children: [
                            const Text(
                              "SECONDARY & HIGHER SECONDARY (STD 9–12)",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            ...classSummaries.map((e) {
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    "STD ${e['std']}  |  DIV ${e['div']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Total: ${e['total']}   |   Present: ${e['present']}   |   Absent: ${e['absent']}",
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
