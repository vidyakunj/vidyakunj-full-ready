import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      home: const AttendanceScreen(className: 'default'),
      debugShowCheckedModeBanner: false,
    );
  }
}
