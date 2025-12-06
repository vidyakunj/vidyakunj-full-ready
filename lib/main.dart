import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/new_attendance_screen.dart';
import 'splash_check.dart';  // <--- add this

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyakunj Attendance',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F2FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),
      ),

      // -----------------------------------------------------
      // First time → Login Screen
      // Next time → Auto Login
      // -----------------------------------------------------
      home: const SplashCheck(),

      debugShowCheckedModeBanner: false,
    );
  }
}
