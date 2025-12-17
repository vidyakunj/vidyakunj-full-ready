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

  int primaryTotal = 0, primaryPresent = 0, primaryAbsent = 0;
  int secondaryTotal = 0, secondaryPresent = 0, secondaryAbsent = 0;

  int schoolTotal = 0, schoolPresent = 0, schoolAbsent = 0;

  final List<String> divisions = ["A", "B", "C", "D"];

  String _dateStr() =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      classSummaries.clear();
      primaryTotal = primaryPresent = primaryAbsent = 0;
      secondaryTotal = secondaryPresent = secondaryAbsent = 0;
      schoolTotal = schoolPresent = schoolAbsent = 0;
    });

    final date = _dateStr();

    for (int std = 1; std <= 12; std++) {
      for (final div in divisions) {
        final uri = Uri.parse(
          "$SERVER_URL/attendance/summary?date=$date&std=$std&div=$div",
        );

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

        if (std <= 8) {
          primaryTotal += total;
          primaryPresent += present;
          primaryAbsent += absent;
        } else {
          secondaryTotal += total;
          secondaryPresent += present;
          secondaryAbsent += absent;
        }

        schoolTotal += total;
        schoolPresent += present;
        schoolAbsent += absent;
      }
    }

    setState(() => loading = false);
  }

  Widget summaryCard(String title, int t, int p, int a) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Total: $t | Present: $p | Absent: $a"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Attendance Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  selectedDate = d;
                  loadSummary();
                }
              },
              child: Text("Select Date (${_dateStr()})"),
            ),
            const SizedBox(height: 10),

            if (loading) const CircularProgressIndicator(),

            summaryCard(
              "PRIMARY SECTION (STD 1–8)",
              primaryTotal,
              primaryPresent,
              primaryAbsent,
            ),
            summaryCard(
              "SECONDARY & HIGHER SECONDARY (STD 9–12)",
              secondaryTotal,
              secondaryPresent,
              secondaryAbsent,
            ),
            summaryCard(
              "WHOLE SCHOOL SUMMARY",
              schoolTotal,
              schoolPresent,
              schoolAbsent,
            ),

            const Divider(),
            const Text("CLASS WISE SUMMARY",
                style: TextStyle(fontWeight: FontWeight.bold)),

            Expanded(
              child: ListView(
                children: classSummaries.map((e) {
                  return Card(
                    child: ListTile(
                      title: Text("STD ${e['std']} | DIV ${e['div']}"),
                      subtitle: Text(
                        "Total: ${e['total']} | Present: ${e['present']} | Absent: ${e['absent']}",
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
