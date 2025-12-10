import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../screens/login_screen.dart';

class NewAttendanceScreen extends StatefulWidget {
  const NewAttendanceScreen({super.key});

  @override
  State<NewAttendanceScreen> createState() => _NewAttendanceScreenState();
}

class _NewAttendanceScreenState extends State<NewAttendanceScreen> {
  String? selectedStd;
  String? selectedDiv;

  bool isLoadingDivs = false;
  bool isLoadingStudents = false;
  bool hasExistingAttendance = false;

  List<String> divisions = [];
  List<_StudentRow> students = [];
  List<int> absentRollNumbers = [];

  final List<String> stdOptions = List<String>.generate(12, (i) => '${i + 1}');

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
      students = [];
      absentRollNumbers = [];
    });

    try {
      final uri = Uri.parse('$SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        divisions = (data['divisions'] ?? []).map<String>((e) => e.toString()).toList();
      }
    } catch (e) {
      _showSnack('Error loading divisions: $e');
    }

    setState(() => isLoadingDivs = false);
  }

  Future<void> _loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      isLoadingStudents = true;
      students = [];
      absentRollNumbers = [];
      hasExistingAttendance = false;
    });

    try {
      final uri = Uri.parse('$SERVER_URL/students?std=$selectedStd&div=$selectedDiv');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        students = (data['students'] ?? [])
            .map<_StudentRow>((e) => _StudentRow(
                  name: e['name'],
                  roll: e['roll'],
                  mobile: e['mobile'],
                ))
            .toList();
      }
    } catch (e) {
      _showSnack('Error loading students: $e');
    }

    await _checkExistingAttendance();
    setState(() => isLoadingStudents = false);
  }

  Future<void> _checkExistingAttendance() async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse("$SERVER_URL/attendance-check?std=$selectedStd&div=$selectedDiv&date=$dateStr");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['exists'] == true) {
        hasExistingAttendance = true;
        _showSnack("Attendance already submitted for today");
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      _showSnack('Select STD & DIV');
      return;
    }

    if (hasExistingAttendance) {
      _showSnack("Attendance already exists for today");
      return;
    }

    final absentees = students.where((s) => !s.isPresent).toList();
    int sent = 0, failed = 0;

    for (final s in absentees) {
      try {
        final res = await http.post(
          Uri.parse("$SERVER_URL/send-sms"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"mobile": s.mobile, "studentName": s.name}),
        );

        final success = (res.statusCode == 200 && jsonDecode(res.body)['success'] == true);
        success ? sent++ : failed++;
      } catch (e) {
        failed++;
      }
    }

    try {
      final now = DateTime.now();
      final attendanceData = students.map((s) => {
        "studentId": null,
        "std": selectedStd,
        "div": selectedDiv,
        "roll": s.roll,
        "date": now.toIso8601String(),
        "present": s.isPresent,
      }).toList();

      final response = await http.post(
        Uri.parse("$SERVER_URL/attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": now.toIso8601String(),
          "attendance": attendanceData,
        }),
      );

      if (response.statusCode != 200) {
        _showSnack("Attendance save failed");
      } else {
        hasExistingAttendance = true;
      }
    } catch (e) {
      _showSnack("Error saving attendance: $e");
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("SMS Summary"),
        content: Text("$sent Sent\n$failed Failed"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class _StudentRow {
  final String name;
  final int roll;
  final String mobile;
  bool isPresent;

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
  });
}
