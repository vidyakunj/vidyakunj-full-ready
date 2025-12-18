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

  int total = 0;
  int present = 0;
  int absent = 0;

  bool loading = false;

  final List<String> stdOptions =
      List.generate(12, (index) => (index + 1).toString());

  /* =========================
     LOAD DIVISIONS
     ========================= */
  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final res = await http.get(
      Uri.parse("$SERVER_URL/divisions?std=$selectedStd"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        divisions =
            (data["divisions"] ?? []).map<String>((e) => e.toString()).toList();
        selectedDiv = null;
      });
    }
  }

  /* =========================
     LOAD SUMMARY (SINGLE CLASS)
     ========================= */
  Future<void> loadSummary() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() => loading = true);

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "$SERVER_URL/attendance/summary"
      "?date=$dateStr&std=$selectedStd&div=$selectedDiv",
    );

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final summary = data["summary"];

      setState(() {
        total = (summary["total"] ?? 0) as int;
        present = (summary["present"] ?? 0) as int;
        absent = (summary["absent"] ?? 0) as int;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }

    setState(() => loading = false);
  }

  /* =========================
     UI
     ========================= */
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STD SELECT
            DropdownButtonFormField<String>(
              value: selectedStd,
              hint: const Text("Select STD"),
              items: stdOptions
                  .map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedStd = v;
                  divisions.clear();
                  selectedDiv = null;
                });
                loadDivisions();
              },
            ),

            const SizedBox(height: 12),

            /// DIV SELECT
            DropdownButtonFormField<String>(
              value: selectedDiv,
              hint: const Text("Select DIV"),
              items: divisions
                  .map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => selectedDiv = v);
              },
            ),

            const SizedBox(height: 12),

            /// DATE PICKER
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
                }
              },
              child: Text(
                "Select Date (${selectedDate.toString().split(' ')[0]})",
              ),
            ),

            const SizedBox(height: 12),

            /// LOAD BUTTON
            ElevatedButton(
              onPressed: loadSummary,
              child: const Text("Load Summary"),
            ),

            const SizedBox(height: 20),

            /// RESULT
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (total == 0)
              const Text("No data available")
            else
              Card(
                color: Colors.yellow[100],
                child: ListTile(
                  title: Text(
                    "STD $selectedStd | DIV $selectedDiv",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Total: $total  |  Present: $present  |  Absent: $absent",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
