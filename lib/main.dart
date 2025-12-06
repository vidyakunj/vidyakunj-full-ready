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

  primaryColor: primaryNavy,

  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryNavy,
    brightness: Brightness.light,
  ),

  scaffoldBackgroundColor: const Color(0xfff6f8ff),

  appBarTheme: const AppBarTheme(
    backgroundColor: primaryNavy,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 3,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryNavy,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
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

