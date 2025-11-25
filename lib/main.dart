import 'package:flutter/material.dart';
import 'screens/new_attendance_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyakunj Attendance',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NewAttendanceScreen(),  // ⬅ directly open new screen
      debugShowCheckedModeBanner: false,
    );
  }
}
