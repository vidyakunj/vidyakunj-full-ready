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
                  id: e['_id'],
                  name: e['name'],
                  roll: e['roll'],
                  mobile: e['mobile'],
                ))
            .toList();
      }
    } catch (e) {
      _showSnack('Error loading students: $e');
    }

    await _checkAttendanceLock();
    setState(() => isLoadingStudents = false);
  }

  Future<void> _checkAttendanceLock() async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse("$SERVER_URL/attendance/check-lock?std=$selectedStd&div=$selectedDiv&date=$dateStr");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      List lockedRolls = data['locked'] ?? [];
      for (var s in students) {
        if (lockedRolls.contains(s.roll)) {
          s.locked = true;
          s.isPresent = false;
          absentRollNumbers.add(s.roll);
        }
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      _showSnack('Select STD & DIV');
      return;
    }

    final absentees = students.where((s) => !s.isPresent && !s.locked).toList();
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
        "studentId": s.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: const Color(0xff003366),
        elevation: 4,
        titleSpacing: 0,
        title: const Text(
          "Vidyakunj School",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStd,
                    decoration: _inputDeco("Select STD"),
                    items: stdOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      setState(() => selectedStd = v);
                      _loadDivisions();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isLoadingDivs
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: selectedDiv,
                          decoration: _inputDeco("Select DIV"),
                          items: divisions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) {
                            setState(() => selectedDiv = v);
                            _loadStudents();
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: students.map((s) => _studentTile(s)).toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Absent: ${absentRollNumbers.join(', ')}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                    onPressed: _saveAttendance,
                    child: const Text("Send SMS", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) =>
      InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));

  Widget _studentTile(_StudentRow s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: s.isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.isPresent ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(s.name)),
          Expanded(flex: 2, child: Text("${s.roll}", textAlign: TextAlign.center)),
          Expanded(
            flex: 3,
            child: Checkbox(
              value: s.isPresent,
              onChanged: s.locked ? null : (v) {
                setState(() {
                  s.isPresent = v ?? true;
                  if (!s.isPresent) {
                    if (!absentRollNumbers.contains(s.roll)) {
                      absentRollNumbers.add(s.roll);
                      absentRollNumbers.sort();
                    }
                  } else {
                    absentRollNumbers.remove(s.roll);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRow {
  final String id;
  final String name;
  final int roll;
  final String mobile;
  bool isPresent;
  bool locked;

  _StudentRow({
    required this.id,
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
    this.locked = false,
  });
}
