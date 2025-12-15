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

  List<Map<String, dynamic>> classSummaries = [];

  int primaryTotal = 0;
  int primaryPresent = 0;
  int primaryAbsent = 0;

  int secondaryTotal = 0;
  int secondaryPresent = 0;
  int secondaryAbsent = 0;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadAllSummaries();
  }

  String get dateStr =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  /* =======================================================
     LOAD ALL STD/DIV AUTOMATICALLY
     ======================================================= */
  Future<void> loadAllSummaries() async {
    setState(() {
      loading = true;
      classSummaries.clear();
      primaryTotal = primaryPresent = primaryAbsent = 0;
      secondaryTotal = secondaryPresent = secondaryAbsent = 0;
    });

    for (int std = 1; std <= 12; std++) {
      // fetch divisions for this std
      final divRes = await http.get(
        Uri.parse("$SERVER_URL/divisions?std=$std"),
      );

      if (divRes.statusCode != 200) continue;

      final divData = jsonDecode(divRes.body);
      final List divisions = divData["divisions"] ?? [];

      for (final div in divisions) {
        final res = await http.get(Uri.parse(
            "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div"));

        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        if (data["success"] != true) continue;

        final summary = data["summary"];

        classSummaries.add(summary);

        if (std <= 8) {
          primaryTotal += summary["total"] as int;
          primaryPresent += summary["present"] as int;
          primaryAbsent += summary["absent"] as int;
        } else {
          secondaryTotal += summary["total"] as int;
          secondaryPresent += summary["present"] as int;
          secondaryAbsent += summary["absent"] as int;
        }
      }
    }

    // sort ascending STD then DIV
    classSummaries.sort((a, b) {
      int s = int.parse(a["std"]).compareTo(int.parse(b["std"]));
      if (s != 0) return s;
      return a["div"].compareTo(b["div"]);
    });

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    final wholeTotal = primaryTotal + secondaryTotal;
    final wholePresent = primaryPresent + secondaryPresent;
    final wholeAbsent = primaryAbsent + secondaryAbsent;

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Attendance Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                        loadAllSummaries();
                      }
                    },
                    child: Text("Select Date ($dateStr)"),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        ...classSummaries.map((e) => Card(
                              child: ListTile(
                                title: Text(
                                    "STD ${e['std']}  DIV ${e['div']}"),
                                subtitle: Text(
                                    "Total: ${e['total']} | Present: ${e['present']} | Absent: ${e['absent']}"),
                              ),
                            )),

                        const SizedBox(height: 16),

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
                          wholeTotal,
                          wholePresent,
                          wholeAbsent,
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
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            "Total: $total | Present: $present | Absent: $absent"),
      ),
    );
  }
}
