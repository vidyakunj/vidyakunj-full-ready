import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class SchoolDailyDashboard extends StatefulWidget {
  const SchoolDailyDashboard({super.key});

  @override
  State<SchoolDailyDashboard> createState() =>
      _SchoolDailyDashboardState();
}

class _SchoolDailyDashboardState
    extends State<SchoolDailyDashboard> {

  static const Color navy = Color(0xFF0D1B2A);

  DateTime selectedDate = DateTime.now();

  Map<String, dynamic>? primaryData;
  Map<String, dynamic>? secondaryData;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final primaryRes = await http.get(
        Uri.parse("$SERVER_URL/attendance/primary-section-summary?date=$dateStr"),
      );

      final secondaryRes = await http.get(
        Uri.parse("$SERVER_URL/attendance/secondary-section-summary?date=$dateStr"),
      );

      if (primaryRes.statusCode == 200 &&
          secondaryRes.statusCode == 200) {
        setState(() {
          primaryData = jsonDecode(primaryRes.body);
          secondaryData = jsonDecode(secondaryRes.body);
        });
      }
    } catch (e) {
      debugPrint("Dashboard Load Error: $e");
    }

    setState(() => loading = false);
  }

  Color getColor(double percent) {
    if (percent >= 85) return Colors.green;
    if (percent >= 75) return Colors.orange;
    return Colors.red;
  }

  Widget summaryCard(String title, Map<String, dynamic> totals) {
    final total = totals["total"] ?? 0;
    final present = totals["present"] ?? 0;
    final absent = totals["absent"] ?? 0;
    final late = totals["late"] ?? 0;
    final percent = double.tryParse(totals["percentage"] ?? "0") ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navy)),
            const SizedBox(height: 10),
            Text("Total Students: $total"),
            Text("Present: $present"),
            Text("Absent: $absent"),
            Text("Late (Info): $late"),
            const SizedBox(height: 8),
            Text(
              "Attendance: ${percent.toStringAsFixed(2)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getColor(percent),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("School Daily Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("Date: $dateStr",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (primaryData != null)
                  summaryCard(
                    "Primary Section (STD 1–8)",
                    primaryData!["totals"],
                  ),

                if (secondaryData != null)
                  summaryCard(
                    "Secondary Section (STD 9–12)",
                    secondaryData!["totals"],
                  ),

                if (primaryData != null &&
                    secondaryData != null)
                  summaryCard(
                    "Whole School",
                    {
                      "total": primaryData!["totals"]["total"] +
                          secondaryData!["totals"]["total"],
                      "present": primaryData!["totals"]["present"] +
                          secondaryData!["totals"]["present"],
                      "absent": primaryData!["totals"]["absent"] +
                          secondaryData!["totals"]["absent"],
                      "late": primaryData!["totals"]["late"] +
                          secondaryData!["totals"]["late"],
                      "percentage": (
                              (primaryData!["totals"]["present"] +
                                      secondaryData!["totals"]["present"]) /
                                  (primaryData!["totals"]["total"] +
                                      secondaryData!["totals"]["total"])) *
                          100
                    },
                  ),
              ],
            ),
    );
  }
}
