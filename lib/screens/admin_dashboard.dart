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
  String selectedStd = "9";
  String selectedDiv = "A";
  DateTime selectedDate = DateTime.now();

  int total = 0;
  int present = 0;
  int absent = 0;

  bool loading = false;
  bool hasData = false;

  final List<String> stdList =
      List.generate(12, (i) => (i + 1).toString());
  final List<String> divList = ["A", "B", "C", "D"];

  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      hasData = false;
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final url =
        "$SERVER_URL/attendance/summary?date=$dateStr&std=$selectedStd&div=$selectedDiv";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["success"] == true && data["summary"] != null) {
          final s = data["summary"];

          setState(() {
            total = (s["total"] ?? 0).toInt();
            present = (s["present"] ?? 0).toInt();
            absent = (s["absent"] ?? 0).toInt();
            hasData = true;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load summary")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
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
          children: [
            // STD
            DropdownButtonFormField<String>(
              value: selectedStd,
              decoration: const InputDecoration(labelText: "Select STD"),
              items: stdList
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedStd = v!),
            ),
            const SizedBox(height: 10),

            // DIV
            DropdownButtonFormField<String>(
              value: selectedDiv,
              decoration: const InputDecoration(labelText: "Select DIV"),
              items: divList
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedDiv = v!),
            ),
            const SizedBox(height: 15),

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
                "Select Date (${selectedDate.toString().split(" ")[0]})",
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
                color: Colors.yellow[100],
                child: ListTile(
                  title: Text(
                    "STD $selectedStd  |  DIV $selectedDiv",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Total: $total   |   Present: $present   |   Absent: $absent",
                  ),
                ),
              ),

            if (!loading && !hasData)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("No data available"),
              ),
          ],
        ),
      ),
    );
  }
}
