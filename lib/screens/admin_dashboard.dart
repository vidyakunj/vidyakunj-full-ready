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
  String? errorMessage;

  List<Map<String, dynamic>> primary = [];
  List<Map<String, dynamic>> secondary = [];
  Map<String, dynamic> schoolTotal = {
    "total": 0,
    "present": 0,
    "absent": 0
  };

  /* =============================
     LOAD SCHOOL SUMMARY
     ============================= */
  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final res = await http.get(
        Uri.parse("$SERVER_URL/attendance/summary-school?date=$dateStr"),
      );

      if (res.statusCode != 200) {
        throw "Server error";
      }

      final data = jsonDecode(res.body);

      setState(() {
        primary = List<Map<String, dynamic>>.from(data["primary"]);
        secondary = List<Map<String, dynamic>>.from(data["secondary"]);
        schoolTotal = data["schoolTotal"];
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load summary";
      });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            if (loading)
              const Center(child: CircularProgressIndicator()),

            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            if (!loading && errorMessage == null) ...[
              _schoolTotalCard(),
              const SizedBox(height: 20),

              _sectionTitle("Primary (STD 1–8)"),
              _summaryTable(primary),

              const SizedBox(height: 30),

              _sectionTitle("Secondary (STD 9–12)"),
              _summaryTable(secondary),
            ],
          ],
        ),
      ),
    );
  }

  /* =============================
     UI HELPERS (OUTSIDE build)
     ============================= */

  Widget _schoolTotalCard() {
    return Card(
      color: Colors.green[100],
      child: ListTile(
        title: const Text(
          "School Total",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Total: ${schoolTotal["total"]} | "
          "Present: ${schoolTotal["present"]} | "
          "Absent: ${schoolTotal["absent"]}",
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _summaryTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Text("No data available");
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("STD")),
          DataColumn(label: Text("DIV")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Present")),
          DataColumn(label: Text("Absent")),
        ],
        rows: data
            .map(
              (r) => DataRow(cells: [
                DataCell(Text(r["std"].toString())),
                DataCell(Text(r["div"].toString())),
                DataCell(Text(r["total"].toString())),
                DataCell(Text(r["present"].toString())),
                DataCell(Text(r["absent"].toString())),
              ]),
            )
            .toList(),
      ),
    );
  }
}
