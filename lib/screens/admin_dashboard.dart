import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

leadingZeros(int n) => n.toString().padLeft(2, '0');

class _AdminDashboardState extends State<AdminDashboard> {
  DateTime selectedDate = DateTime.now();

  int primaryTotal = 0, primaryPresent = 0, primaryAbsent = 0;
  int secondaryTotal = 0, secondaryPresent = 0, secondaryAbsent = 0;
  int schoolTotal = 0, schoolPresent = 0, schoolAbsent = 0;

  List<Map<String, dynamic>> classWise = [];

  Future<void> loadSummary() async {
    final dateStr =
        "${selectedDate.year}-${leadingZeros(selectedDate.month)}-${leadingZeros(selectedDate.day)}";

    primaryTotal = primaryPresent = primaryAbsent = 0;
    secondaryTotal = secondaryPresent = secondaryAbsent = 0;
    schoolTotal = schoolPresent = schoolAbsent = 0;
    classWise.clear();

    try {
      for (int std = 1; std <= 12; std++) {
        final divRes =
            await http.get(Uri.parse("$SERVER_URL/divisions?std=$std"));
        if (divRes.statusCode != 200) continue;

        final divisions =
            (jsonDecode(divRes.body)["divisions"] as List<dynamic>);

        for (final div in divisions) {
          final res = await http.get(Uri.parse(
              "$SERVER_URL/attendance/summary?date=$dateStr&std=$std&div=$div"));

          if (res.statusCode != 200) continue;

          final data = jsonDecode(res.body)["summary"];

          final total = (data["total"] as num).toInt();
          final present = (data["present"] as num).toInt();
          final absent = (data["absent"] as num).toInt();

          classWise.add({
            "std": std,
            "div": div,
            "total": total,
            "present": present,
            "absent": absent,
          });

          if (std <= 8) {
            primaryTotal += total;
            primaryPresent += present;
            primaryAbsent += absent;
          } else {
            secondaryTotal += total;
            secondaryPresent += present;
            secondaryAbsent += absent;
          }

          schoolTotal += total;
          schoolPresent += present;
          schoolAbsent += absent;
        }
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }
  }

  Widget summaryCard(String title, int t, int p, int a) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Total: $t | Present: $p | Absent: $a"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        title: const Text("Admin Attendance Summary"),
        backgroundColor: const Color(0xFF110E38),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      await loadSummary();
                    }
                  },
                  child: Text(
                      "Select Date (${selectedDate.toString().split(' ')[0]})"),
                ),
              ),
              const SizedBox(height: 16),

              summaryCard("PRIMARY SECTION (STD 1–8)",
                  primaryTotal, primaryPresent, primaryAbsent),

              summaryCard("SECONDARY & HIGH SECONDARY (STD 9–12)",
                  secondaryTotal, secondaryPresent, secondaryAbsent),

              summaryCard("WHOLE SCHOOL SUMMARY",
                  schoolTotal, schoolPresent, schoolAbsent),

              const SizedBox(height: 20),
              const Divider(),
              const Text("CLASS WISE SUMMARY",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              ...classWise.map((e) => Card(
                    child: ListTile(
                      title: Text("STD ${e["std"]} | DIV ${e["div"]}"),
                      subtitle: Text(
                          "Total: ${e["total"]} | Present: ${e["present"]} | Absent: ${e["absent"]}"),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
