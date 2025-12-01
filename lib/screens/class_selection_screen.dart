import 'package:flutter/material.dart';
import 'new_attendance_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  // STD 1 to 12 only
  final List<String> classes = const [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12",
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
                  // 👉 Open the NEW attendance screen
                  builder: (_) => const NewAttendanceScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
