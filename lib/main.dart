import 'package:flutter/material.dart';
import 'screens/class_selection_screen.dart'; // NEW import

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

      // ✅ Start app with Class Selection Screen
      home: const ClassSelectionScreen(),

      debugShowCheckedModeBanner: false,
    );
  }
}
