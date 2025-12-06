import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'new_attendance_screen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff003366);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Teacher Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewAttendanceScreen()),
                );
              },
              child: const Text("Take Attendance"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: (){},
              child: const Text("Today’s Attendance (Coming Soon)"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: (){},
              child: const Text("Previous Attendance (Coming Soon)"),
            ),

          ],
        ),
      ),
    );
  }
}
