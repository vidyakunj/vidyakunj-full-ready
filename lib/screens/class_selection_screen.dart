import 'package:flutter/material.dart';
import 'daily_attendance_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  final List<String> classes = const [
    "Nursery",
    "LKG",
    "UKG",
    "1A",
    "1B",
    "2A",
    "2B",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Class")),
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final c = classes[index];
          return ListTile(
            title: Text("Class $c"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyAttendanceScreen(className: c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
