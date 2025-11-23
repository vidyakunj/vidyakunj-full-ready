import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/test_sms.dart';   // <-- Add this import

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

      // ROUTES FOR NAVIGATION
      routes: {
        '/test-sms': (context) => const TestSMS(),
      },

      // DEFAULT HOME SCREEN (YOUR ORIGINAL SCREEN)
      home: const AttendanceScreen(className: 'default'),

      debugShowCheckedModeBanner: false,
    );
  }
}


