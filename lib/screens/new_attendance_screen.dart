import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class NewAttendanceScreen extends StatefulWidget {
  const NewAttendanceScreen({super.key});

  @override
  State<NewAttendanceScreen> createState() => _NewAttendanceScreenState();
}

class _NewAttendanceScreenState extends State<NewAttendanceScreen> {
  String? selectedStd;
  String? selectedDiv;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> students = [];
  Map<int, bool> attendance = {};

  Future<void> loadDivisions() async {
    final uri = Uri.parse(
      '$DATA_SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}',
    );

    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    setState(() {
      selectedDiv = null;
    });
  }

  Future<void> loadStudents() async {
    final uri = Uri.parse(
      '$DATA_SERVER_URL/students?std=$selectedStd&div=$selectedDiv',
    );

    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    setState(() {
      students = List<Map<String, dynamic>>.from(data['students']);
      attendance.clear();
    });
  }

  Future<void> submitAttendance() async {
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final payload = students.map((s) {
      return {
        "studentId": s["_id"],
        "std": selectedStd,
        "div": selectedDiv,
        "roll": s["roll"],
        "name": s["name"],
        "mobile": s["mobile"],
        "present": attendance[s["roll"]] ?? false,
      };
    }).toList();

    await http.post(
      Uri.parse('$DATA_SERVER_URL/attendance'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "date": dateStr,
        "attendance": payload,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Attendance"),
        backgroundColor: const Color(0xFF003366),
      ),
      body: Center(
        child: Column(
          children: const [
            Text("Attendance Screen Loaded"),
          ],
        ),
      ),
    );
  }
}
