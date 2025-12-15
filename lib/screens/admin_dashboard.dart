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

  // DATA
  List<Map<String, dynamic>> primaryClasses = [];
  List<Map<String, dynamic>> secondaryClasses = [];

  int primaryTotal = 0, primaryPresent = 0, primaryAbsent = 0;
  int secondaryTotal = 0, secondaryPresent = 0, secondaryAbsent = 0;

  int schoolTotal = 0, schoolPresent = 0, schoolAbsent = 0;

  final List<String> divisions = ["A", "B", "C", "D"];

  String get dateStr =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  Future<Map<String, dynamic>?> fetchSummary(
      String std, String div) async {
    final uri = Uri.parse(
        "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div");

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    if (data["success"] != true) return null;

    return data["summary"];
  }

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      primaryClasses.clear();
      secondaryClasses.clear();

      primaryTotal = primaryPresent = primaryAbsent = 0;
      secondaryTotal = secondaryPresent = secondaryAbsent = 0;
      schoolTotal = schoolPresent = schoolAbsent = 0;
    });

    // PRIMARY STD 1–8
    for (int std = 1; std <= 8; std++) {
      for (final div in divisions) {
        final s = await fetchSummary("$std", div);
        if (s == null) continue;

        final int total = (s["total"] as num).toInt();
        final int present = (s["present"] as num).toInt();
        final int absent = (s["absent"] as num).toInt();

        primaryClasses.add(s);

        primaryTotal += total;
        primaryPresent += present;
        primaryAbsent += absent;
      }
    }

    // SECONDARY STD 9–12
    for (int std = 9; std <= 12; std++) {
      for (final div in divisions) {
        final s = await fetchSummary("$std", div);
        if (s == null) continue;

        final int total = (s["total"] as num).toInt();
        final int present = (s["present"] as num).toInt();
        final int absent = (s["absent"] as num).toInt();

        secondaryClasses.add(s);

        secondaryTotal += total;
        secondaryPresent += present;
        secondaryAbsent += absent;
      }
    }

    schoolTotal = primaryTotal + secondaryTotal;
    schoolPresent = primaryPresent + secondaryPresent;
    schoolAbsent = primaryAbsent + secondaryAbsent;

    setState(() => loading = false);
  }

  Widget summaryCard(String title, int t, int p, int a) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Total: $t  |  Present: $p  |  Absent: $a"),
      ),
    );
  }

  Widget classList(String title, List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...data.map((e) => Card(
              child: ListTile(
                title: Text("STD ${e['std']}  |  DIV ${e['div']}"),
                subtitle: Text(
                    "Total: ${e['total']} | Present: ${e['present']} | Absent: ${e['absent']}"),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Attendance Summary")),
      backgroundColor: const Color(0xffeef3ff),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
                child: Text("Select Date ($dateStr)"),
              ),

              const SizedBox(height: 20),

              if (loading) const CircularProgressIndicator(),

              if (!loading) ...[
                summaryCard(
                    "PRIMARY SECTION (STD 1–8)",
                    primaryTotal,
                    primaryPresent,
                    primaryAbsent),
                classList("Primary Class Wise Summary", primaryClasses),

                summaryCard(
                    "SECONDARY & HIGHER SECONDARY (STD 9–12)",
                    secondaryTotal,
                    secondaryPresent,
                    secondaryAbsent),
                classList(
                    "Secondary Class Wise Summary", secondaryClasses),

                summaryCard("WHOLE SCHOOL SUMMARY", schoolTotal,
                    schoolPresent, schoolAbsent),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
