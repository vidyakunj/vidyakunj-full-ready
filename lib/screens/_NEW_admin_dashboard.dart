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
  String? selectedStd;
  String? selectedDiv;
  DateTime selectedDate = DateTime.now();

  List<String> divisions = [];
  Map<String, dynamic>? summary;

  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final uri = Uri.parse(
      "$DATA_SERVER_URL/divisions?std=$selectedStd",
    );

    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    setState(() {
      divisions = List<String>.from(data['divisions'] ?? []);
      selectedDiv = null;
    });
  }

  Future<void> loadSummary() async {
    if (selectedStd == null || selectedDiv == null) return;

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "$DATA_SERVER_URL/attendance/summary"
      "?date=$dateStr&std=$selectedStd&div=$selectedDiv",
    );

    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    setState(() {
      summary = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Attendance Summary"),
        backgroundColor: const Color(0xFF003366),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedStd,
              hint: const Text("Select STD"),
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: "${i + 1}",
                  child: Text("${i + 1}"),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  selectedStd = v;
                  divisions = [];
                  summary = null;
                });
                loadDivisions();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedDiv,
              hint: const Text("Select DIV"),
              items: divisions
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(d),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedDiv = v;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadSummary,
              child: const Text("Load Summary"),
            ),
            const SizedBox(height: 20),
            if (summary != null)
              Text(
                "PRESENT: ${summary!['present']}  "
                "ABSENT: ${summary!['absent']}  "
                "TOTAL: ${summary!['total']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
