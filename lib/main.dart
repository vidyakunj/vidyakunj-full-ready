import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'splash_check.dart';
import 'admin/reports/admin_reports_home.dart';
import 'admin/reports/primary/primary_reports_home.dart';
import 'admin/reports/primary/primary_student_attendance_report.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyakunj Attendance',
      debugShowCheckedModeBanner: false,
      home: const SplashCheck(),
      routes: {
        '/adminReportsHome': (context) => const AdminReportsHome(),
        '/primaryReportsHome': (context) => const PrimaryReportsHome(),
        '/primaryStudentAttendanceReport': (context) =>
            const PrimaryStudentAttendanceReport(),
      },
    );
  }
}
