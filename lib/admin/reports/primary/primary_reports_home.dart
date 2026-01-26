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
  DateTime selectedDate = DateTime.now(); // 📅 selected date

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
      final dateStr =
        
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

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
  
/* ================= SORT CLASSES (STD 1–8, DIV A–D) ================= */
  
List<dynamic> getSortedClasses() {
  final List<dynamic> sorted = List.from(classes);

  sorted.sort((a, b) {
    final stdA = int.parse(a["std"]);
    final stdB = int.parse(b["std"]);

    if (stdA != stdB) {
      return stdA.compareTo(stdB); // STD 1 → 8
    }

    return a["div"].compareTo(b["div"]); // DIV A → D
  });

  return sorted;
}

  @override
Widget build(BuildContext context) {
  const green = Color(0xFF2E7D32);

  return Scaffold(
    appBar: AppBar(
      title: const Text('Primary Reports (Std 1–8)'),
      backgroundColor: green,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== REPORT CARDS =====
            _reportCard(
              context: context,
              title: 'Student Attendance Report',
              subtitle: 'Date-wise attendance (Read Only)',
              icon: Icons.people,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/primaryStudentAttendanceReport',
                );
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
                  context,
                  '/primaryAttendanceSummaryReport',
                );
              },
            ),

            const SizedBox(height: 20),

            // ===== DATE PICKER =====
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                "Select Date: ${selectedDate.year}-"
                "${selectedDate.month.toString().padLeft(2, '0')}-"
                "${selectedDate.day.toString().padLeft(2, '0')}",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() => selectedDate = picked);
                  loadPrimarySectionSummary();
                }
              },
            ),

            const SizedBox(height: 20),

            // ===== TOTAL SUMMARY =====
            if (!loading && totals != null)
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.green),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PRIMARY SECTION TOTAL (Std 1–8)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _totalRow("Total Students", totals!["total"]),
                      _totalRow("Present", totals!["present"]),
                      _totalRow("Absent", totals!["absent"]),
                      _totalRow("Late", totals!["late"]),
                      _totalRow(
                        "Attendance %",
                        "${totals!["percentage"]}%",
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ===== LOADING =====
            if (loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),

            // ===== CLASS-WISE LIST =====
            if (!loading && hasData)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: getSortedClasses().length,
                itemBuilder: (context, index) {
                  final c = getSortedClasses()[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        "STD ${c['std']}  DIV ${c['div']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Total: ${c['total']} | "
                        "Present: ${c['present']} | "
                        "Absent: ${c['absent']} | "
                        "Late: ${c['late']} | "
                        "Attendance: ${c['percentage']}%",
                      ),
                    ),
                  );
                },
              ),

            if (!loading && !hasData)
              const Text("No summary data available"),
          ],
        ),
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
  Widget _totalRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

}
