import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class Student {
  final int roll;
  final String name;
  final String mobile;
  bool isPresent;

  Student({
    required this.roll,
    required this.name,
    required this.mobile,
    this.isPresent = true, // default = Present (checked)
  });
}

class DailyAttendanceScreen extends StatefulWidget {
  const DailyAttendanceScreen({super.key});

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  // TEMP STUDENT LIST (later we will make this editable)
  final List<Student> students = [
    Student(roll: 1, name: "Patil Manohar", mobile: "8980994984"),
    Student(roll: 2, name: "Diya Patil", mobile: "919265635968"),
  ];

  bool isSending = false;

  Future<bool> _sendSmsForStudent(Student s) async {
    try {
      final res = await http.post(
        Uri.parse('$SERVER_URL/send-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "mobile": s.mobile.trim(),
          "studentName": s.name.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["success"] == true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("SMS error for ${s.name}: $e");
      return false;
    }
  }

  Future<void> _sendSmsToAbsentees() async {
    setState(() => isSending = true);

    int sent = 0;
    int failed = 0;

    final absentees = students.where((s) => !s.isPresent).toList();

    for (final s in absentees) {
      final ok = await _sendSmsForStudent(s);
      if (ok) {
        sent++;
      } else {
        failed++;
      }
    }

    setState(() => isSending = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("SMS Summary"),
        content: Text(
          "$sent SMS sent successfully\n$failed failed",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Attendance"),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isSending ? null : _sendSmsToAbsentees,
            child: Text(
              isSending ? "Sending SMS..." : "SEND SMS",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];

          return Card(
            elevation: 1,
            child: ListTile(
              title: Text(
                s.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Roll No: ${s.roll}"),
                  Text("Mobile: ${s.mobile}"),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Present",
                    style: TextStyle(fontSize: 12),
                  ),
                  Checkbox(
                    value: s.isPresent,
                    onChanged: (v) {
                      setState(() {
                        s.isPresent = v ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
