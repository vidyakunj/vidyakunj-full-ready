import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class PrimaryAttendanceSummaryReport extends StatefulWidget {
  const PrimaryAttendanceSummaryReport({super.key});

  @override
  State<PrimaryAttendanceSummaryReport> createState() =>
      _PrimaryAttendanceSummaryReportState();
}

class _PrimaryAttendanceSummaryReportState
    extends State<PrimaryAttendanceSummaryReport> {
  String? selectedStd;
  String? selectedDiv;
  DateTime selectedDate = DateTime.now();

  List<String> divisions = [];

  int total = 0;
  int present = 0;
  int absent = 0;
  int late = 0;

  bool loading = false;
  bool hasData = false;

  final List<String> stdOptions =
      List.generate(8, (i) => (i + 1).toString());

  /* ==============================
     LOAD DIVISIONS
     ============================== */
  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final res = await http.get(
      Uri.parse("$SERVER_URL/divisions?std=$selectedStd"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        divisions =
            (data["divisions"] as List).map((e) => e.toString()).toList();
        selectedDiv = null;
      });
    }
  }

  /* ==============================
     LOAD SUMMARY (READ ONLY)
     ============================== */
  Future<void> loadSummary() async {
    if (selectedStd == null || selectedDiv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select STD and DIV")),
      );
      return;
    }

    setState(() {
      loading = true;
      hasData = false;
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final url =
        "$SERVER_URL/attendance/summary?date=$dateStr&std=$selectedStd&div=$selectedDiv";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        total = data["summary"]["total"] ?? 0;
        present = data["summary"]["present"] ?? 0;
        absent = data["summary"]["absent"] ?? 0;
        late = data["summary"]["late"] ?? 0;
        hasData = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Primary Attendance Summary"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // STD
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select STD"),
              value: selectedStd,
              items: stdOptions
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
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
            const SizedBox(height: 10),

            // DIV
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select DIV"),
              value: selectedDiv,
              items: divisions
                  .map((d) =>
                      DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => selectedDiv = v),
            ),
            const SizedBox(height: 10),

            // DATE
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
                "Select Date (${selectedDate.toIso8601String().split('T')[0]})",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loadSummary,
              child: const Text("Load Summary"),
            ),

            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            if (!loading && hasData)
              Card(
                color: Colors.green[50],
                child: ListTile(
                  title: Text(
                    "STD $selectedStd | DIV $selectedDiv",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Total: $total | Present: $present | Absent: $absent | Late: $late",
                  ),
                ),
              ),

            if (!loading && !hasData)
              const Text("No data available"),
          ],
        ),
      ),
    );
  }
}
