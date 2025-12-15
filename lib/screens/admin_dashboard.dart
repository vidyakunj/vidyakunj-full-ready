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
  List<String> divisions = [];

  DateTime selectedDate = DateTime.now();

  int total = 0;
  int present = 0;
  int absent = 0;

  bool loading = false;
  String message = "No summary available.";

  final List<String> stdOptions = List.generate(12, (i) => "${i + 1}");

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
        selectedDiv = null;
      });
    }
  }

  /* ================= LOAD SUMMARY ================= */
  Future<void> loadAttendanceSummary() async {
    if (selectedStd == null || selectedDiv == null) {
      setState(() {
        message = "Please select STD and DIV";
      });
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "$SERVER_URL/attendance/summary?date=$dateStr&std=$selectedStd&div=$selectedDiv",
    );

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() {
          total = data["summary"]["total"];
          present = data["summary"]["present"];
          absent = data["summary"]["absent"];
          loading = false;
        });
      } else {
        setState(() {
          message = "No summary available.";
          loading = false;
        });
      }
    } else {
      setState(() {
        message = "Failed to load summary";
        loading = false;
      });
    }
  }

  /* ================= UI ================= */
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
              decoration: const InputDecoration(labelText: "Select STD"),
              value: selectedStd,
              items: stdOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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

            /* ===== DIV ===== */
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select DIV"),
              value: selectedDiv,
              items: divisions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() => selectedDiv = v);
              },
            ),

            const SizedBox(height: 15),

            /* ===== DATE ===== */
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
                  loadAttendanceSummary();
                }
              },
              child: const Text("Select Date"),
            ),

            const SizedBox(height: 20),

            /* ===== SUMMARY ===== */
            if (loading)
              const CircularProgressIndicator()
            else if (message.isNotEmpty)
              Text(message)
            else
              Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    "STD $selectedStd  |  DIV $selectedDiv",
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
