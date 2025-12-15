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

  Map<String, dynamic>? summary;

  final List<String> stdOptions = List.generate(12, (i) => "${i + 1}");
  List<String> divisions = [];

  /* ================= LOAD DIVISIONS ================= */
  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final res = await http.get(
      Uri.parse("$SERVER_URL/divisions?std=$selectedStd"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        divisions = List<String>.from(data["divisions"] ?? []);
      });
    }
  }

  /* ================= LOAD SUMMARY ================= */
  Future<void> loadAttendanceSummary() async {
    if (selectedStd == null || selectedDiv == null) return;

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "$SERVER_URL/attendance/summary"
      "?date=$dateStr&std=$selectedStd&div=$selectedDiv",
    );

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        summary = data["summary"];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /* ===== STD ===== */
            DropdownButtonFormField<String>(
              value: selectedStd,
              hint: const Text("Select STD"),
              items: stdOptions
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedStd = v;
                  selectedDiv = null;
                  summary = null;
                });
                loadDivisions();
              },
            ),
            const SizedBox(height: 10),

            /* ===== DIV ===== */
            DropdownButtonFormField<String>(
              value: selectedDiv,
              hint: const Text("Select DIV"),
              items: divisions
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedDiv = v;
                  summary = null;
                });
              },
            ),
            const SizedBox(height: 20),

            /* ===== DATE ===== */
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
                  await loadAttendanceSummary();
                }
              },
              child: const Text("Select Date"),
            ),
            const SizedBox(height: 20),

            /* ===== SUMMARY ===== */
            summary == null
                ? const Text("No summary available.")
                : Card(
                    child: ListTile(
                      title: Text(
                        "STD ${summary!['std']} | DIV ${summary!['div']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Total: ${summary!['total']}  |  "
                        "Present: ${summary!['present']}  |  "
                        "Absent: ${summary!['absent']}",
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
