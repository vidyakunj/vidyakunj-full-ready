import 'package:flutter/material.dart';
import '../../../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PrimaryReportsHome extends StatefulWidget {
  const PrimaryReportsHome({super.key});

  @override
  State<PrimaryReportsHome> createState() => _PrimaryReportsHomeState();
}

class _PrimaryReportsHomeState extends State<PrimaryReportsHome> {

  bool loading = false;
  bool hasData = false;

  List<dynamic> classes = [];
  Map<String, dynamic>? totals;

    Future<void> loadPrimarySectionSummary() async {
    setState(() {
      loading = true;
      hasData = false;
    });

    try {
      final today = DateTime.now();
      final dateStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final res = await http.get(
        Uri.parse(
          "$SERVER_URL/attendance/primary-section-summary?date=$dateStr",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          classes = data["classes"] ?? [];
          totals = data["totals"];
          hasData = true;
        });
      }
    } catch (e) {
      debugPrint("Primary summary error: $e");
    }

    setState(() => loading = false);
  }
  @override
  void initState() {
    super.initState();
    loadPrimarySectionSummary(); // 🔁 auto-load summary
  }


  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Primary Reports (Std 1–8)'),
        backgroundColor: green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _reportCard(
              context: context,
              title: 'Student Attendance Report',
              subtitle: 'Date-wise attendance (Read Only)',
              icon: Icons.people,
              onTap: () {
                Navigator.pushNamed(
                    context, '/primaryStudentAttendanceReport');
              },
            ),
            const SizedBox(height: 20),
            _reportCard(
              context: context,
              title: 'Attendance Summary',
              subtitle: 'Daily / Monthly summary',
              icon: Icons.bar_chart,
              onTap: () {
                Navigator.pushNamed(
                    context, '/primaryAttendanceSummaryReport');
              },
            ),
                  const SizedBox(height: 30),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: const Text(
          "Primary Section Summary will appear here",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),

          ],
        ),
      ),
    );
  }

  Widget _reportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 1.5),
          color: Colors.green.withOpacity(0.08),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
