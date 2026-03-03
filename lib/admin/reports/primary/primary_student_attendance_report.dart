import 'package:flutter/material.dart';
import '../common/student_attendance_report_engine.dart';

class PrimaryStudentAttendanceReport extends StatelessWidget {
  const PrimaryStudentAttendanceReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentAttendanceReportEngine(
      title: "Primary Student Attendance",
      stdList: [
        '1','2','3','4','5','6','7','8'
      ],
    );
  }
}
