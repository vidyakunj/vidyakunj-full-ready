import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // ADD THIS
import 'screens/new_attendance_screen.dart'; // keep this for navigation

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

        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),

        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Colors.deepPurple),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // -----------------------------------------
      // SHOW LOGIN SCREEN FIRST
      // -----------------------------------------
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
