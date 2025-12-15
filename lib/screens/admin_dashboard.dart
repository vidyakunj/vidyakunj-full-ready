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

  List<dynamic> classWiseSummary = [];

  int primaryTotal = 0;
  int primaryPresent = 0;
  int primaryAbsent = 0;

  int secondaryTotal = 0;
  int secondaryPresent = 0;
  int secondaryAbsent = 0;

  int schoolTotal = 0;
  int schoolPresent = 0;
  int schoolAbsent = 0;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  String get dateStr =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> loadSummary() async {
    final uri = Uri.parse("$SERVER_URL/attendance-summary-all?date=$dateStr");
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
      return;
    }

    final data = jsonDecode(res.body);
    final List<dynamic> rows = data["data"] ?? [];

    int pT = 0, pP = 0, pA = 0;
    int sT = 0, sP = 0, sA = 0;

    for (var r in rows) {
      int std = int.tryParse(r["std"].toString()) ?? 0;
      int total = r["total"];
      int present = r["present"];
      int absent = r["absent"];

      if (std >= 1 && std <= 8) {
        pT += total;
        pP += present;
        pA += absent;
      } else if (std >= 9 && std <= 12) {
        sT += total;
        sP += present;
        sA += absent;
      }
    }

    setState(() {
      classWiseSummary = rows;
      primaryTotal = pT;
      primaryPresent = pP;
      primaryAbsent = pA;
      secondaryTotal = sT;
      secondaryPresent = sP;
      secondaryAbsent = sA;
      schoolTotal = pT + sT;
      schoolPresent = pP + sP;
      schoolAbsent = pA + sA;
    });
  }

  Widget summaryCard(String title, int total, int present, int absent) {
    return Card(
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Total: $total  |  Present: $present  |  Absent: $absent",
        ),
      ),
    );
  }

  Widget classList(bool primary) {
    final filtered = classWiseSummary.where((r) {
      int std = int.tryParse(r["std"].toString()) ?? 0;
      return primary ? std <= 8 : std >= 9;
    }).toList();

    filtered.sort((a, b) {
      int s1 = int.parse(a["std"]);
      int s2 = int.parse(b["std"]);
      if (s1 != s2) return s1.compareTo(s2);
      return a["div"].compareTo(b["div"]);
    });

    return Column(
      children: filtered.map((e) {
        return Card(
          child: ListTile(
            title: Text("STD ${e['std']} | DIV ${e['div']}"),
            subtitle: Text(
              "Total: ${e['total']}  |  Present: ${e['present']}  |  Absent: ${e['absent']}",
            ),
          ),
        );
      }).toList(),
    );
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
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    loadSummary();
                  }
                },
                child: Text("Select Date ($dateStr)"),
              ),

              const SizedBox(height: 16),

              summaryCard(
                "PRIMARY SECTION (STD 1–8)",
                primaryTotal,
                primaryPresent,
                primaryAbsent,
              ),
              classList(true),

              const SizedBox(height: 16),

              summaryCard(
                "SECONDARY & HIGH SECONDARY (STD 9–12)",
                secondaryTotal,
                secondaryPresent,
                secondaryAbsent,
              ),
              classList(false),

              const SizedBox(height: 16),

              summaryCard(
                "WHOLE SCHOOL SUMMARY",
                schoolTotal,
                schoolPresent,
                schoolAbsent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
