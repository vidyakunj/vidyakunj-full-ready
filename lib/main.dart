import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'splash_check.dart';

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
    );
  }
}
