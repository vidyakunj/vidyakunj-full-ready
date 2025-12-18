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
      List.generate(12, (i) => (i + 1).toString());

  /* ===============================
     LOAD DIVISIONS
     =============================== */
  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final uri = Uri.parse(
        "$SERVER_URL/divisions?std=$selectedStd");

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        divisions = List<String>.from(data["divisions"] ?? []);
        selectedDiv = null;
      });
    }
  }

  /* ===============================
     LOAD SUMMARY (SINGLE CLASS)
     =============================== */
  Future<void> loadSummary() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      loading = true;
      total = present = absent = 0;
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "$SERVER_URL/attendance/summary"
      "?date=$dateStr&std=$selectedStd&div=$selectedDiv",
    );

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        final s = data["summary"];
        setState(() {
          total = (s["total"] ?? 0) as int;
          present = (s["present"] ?? 0) as int;
          absent = (s["absent"] ?? 0) as int;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* STD */
            DropdownButtonFormField<String>(
              value: selectedStd,
              decoration: const InputDecoration(labelText: "Select STD"),
              items: stdOptions
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedStd = v;
                  divisions = [];
                  selectedDiv = null;
                });
                loadDivisions();
              },
            ),

            const SizedBox(height: 12),

            /* DIV */
            DropdownButtonFormField<String>(
              value: selectedDiv,
              decoration: const InputDecoration(labelText: "Select DIV"),
              items: divisions
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() => selectedDiv = v);
              },
            ),

            const SizedBox(height: 12),

            /* DATE */
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

            /* LOAD */
            ElevatedButton(
              onPressed: loadSummary,
              child: const Text("Load Summary"),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (selectedStd != null &&
                selectedDiv != null &&
                total > 0)
              Card(
                color: Colors.yellow[100],
                child: ListTile(
                  title: Text(
                    "STD $selectedStd | DIV $selectedDiv",
                    style:
                        const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "TOTAL: $total | PRESENT: $present | ABSENT: $absent",
                  ),
                ),
              )
            else
              const Text("No data available"),
          ],
        ),
      ),
    );
  }
}
