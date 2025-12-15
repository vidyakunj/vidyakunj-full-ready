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

  // Aggregated data
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

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      classSummaries.clear();
    });

    primaryTotal = primaryPresent = primaryAbsent = 0;
    secondaryTotal = secondaryPresent = secondaryAbsent = 0;
    schoolTotal = schoolPresent = schoolAbsent = 0;

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    // STD 1 → 12, DIV A → Z (auto-detect)
    for (int std = 1; std <= 12; std++) {
      final divRes = await http.get(
        Uri.parse("$SERVER_URL/divisions?std=$std"),
      );

      if (divRes.statusCode != 200) continue;

      final divs = jsonDecode(divRes.body)["divisions"] ?? [];

      for (final div in divs) {
        final res = await http.get(
          Uri.parse(
              "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div"),
        );

        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        if (data["success"] != true) continue;

        final summary = data["summary"];

        final total = summary["total"] as int;
        final present = summary["present"] as int;
        final absent = summary["absent"] as int;

        classSummaries.add({
          "std": std,
          "div": div,
          "total": total,
          "present": present,
          "absent": absent,
        });

        // Section totals
        if (std <= 8) {
          primaryTotal += total;
          primaryPresent += present;
          primaryAbsent += absent;
        } else {
          secondaryTotal += total;
          secondaryPresent += present;
          secondaryAbsent += absent;
        }

        // School totals
        schoolTotal += total;
        schoolPresent += present;
        schoolAbsent += absent;
      }
    }

    // Sort STD ascending, DIV ascending
    classSummaries.sort((a, b) {
      final s = a["std"].compareTo(b["std"]);
      if (s != 0) return s;
      return a["div"].compareTo(b["div"]);
    });

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
                  loadSummary();
                }
              },
              child: Text(
                  "Select Date (${selectedDate.toIso8601String().split("T")[0]})"),
            ),
            const SizedBox(height: 16),

            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView(
                  children: [
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
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      "CLASS WISE SUMMARY",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ...classSummaries.map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(
                              "STD ${e["std"]}  |  DIV ${e["div"]}"),
                          subtitle: Text(
                              "Total: ${e["total"]}  |  Present: ${e["present"]}  |  Absent: ${e["absent"]}"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      String title, int total, int present, int absent) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text("Total: $total  |  Present: $present  |  Absent: $absent"),
      ),
    );
  }
}
