import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class PrimaryStudentAttendanceReport extends StatefulWidget {
  const PrimaryStudentAttendanceReport({super.key});

  @override
  State<PrimaryStudentAttendanceReport> createState() =>
      _PrimaryStudentAttendanceReportState();
}

class _PrimaryStudentAttendanceReportState
    extends State<PrimaryStudentAttendanceReport> {
  String? selectedStd;
  String? selectedDiv;
  DateTime selectedDate = DateTime.now();

  List<String> divisions = [];
  List<dynamic> students = [];

  bool loading = false;

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
     LOAD ATTENDANCE (READ ONLY)
     ============================== */
  Future<void> loadAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select STD and DIV")),
      );
      return;
    }

    setState(() {
      loading = true;
      students.clear();
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final url =
        "$SERVER_URL/attendance/list?date=$dateStr&std=$selectedStd&div=$selectedDiv";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        students = data["students"] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load attendance")),
      );
    }

    setState(() => loading = false);
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Primary Student Attendance"),
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
              onPressed: loadAttendance,
              child: const Text("Load Attendance"),
            ),

            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            if (!loading)
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final status = s["status"] ?? "unknown";

                    return Card(
                      child: ListTile(
                        title: Text(
                          "${s["rollNo"]}. ${s["name"]}",
                        ),
                        trailing: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor(status),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
