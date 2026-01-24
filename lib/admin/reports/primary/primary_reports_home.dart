import 'package:flutter/material.dart';

class PrimaryReportsHome extends StatelessWidget {
  const PrimaryReportsHome({super.key});

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
