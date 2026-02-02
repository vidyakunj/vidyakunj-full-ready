import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../screens/login_screen.dart';

class NewAttendanceScreen extends StatefulWidget {
  const NewAttendanceScreen({super.key});

  @override
  State<NewAttendanceScreen> createState() => _NewAttendanceScreenState();
}

class _NewAttendanceScreenState extends State<NewAttendanceScreen> {
  bool isSaved = false;

  String? selectedStd;
  String? selectedDiv;

  bool isLoadingDivs = false;
  bool isLoadingStudents = false;

  final List<String> stdOptions =
      List<String>.generate(12, (i) => '${i + 1}');

  List<String> divisions = [];
  List<_StudentRow> students = [];

  List<int> absentRollNumbers = [];
  List<int> lateRollNumbers = [];

  /* ================= LOGOUT ================= */
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /* ================= LOAD DIVISIONS ================= */
  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions.clear();
      selectedDiv = null;
      students.clear();
      absentRollNumbers.clear();
      lateRollNumbers.clear();
    });

    try {
      final res = await http.get(
        Uri.parse('$SERVER_URL/divisions?std=$selectedStd'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        divisions =
            (data['divisions'] ?? []).map<String>((e) => e.toString()).toList();
      }
    } catch (_) {
      _showSnack("Error loading divisions");
    }

    setState(() => isLoadingDivs = false);
  }

  /* ================= LOAD STUDENTS ================= */
  Future<void> _loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      isLoadingStudents = true;
      students.clear();
      absentRollNumbers.clear();
      lateRollNumbers.clear();
    });

    try {
      final res = await http.get(
        Uri.parse('$SERVER_URL/students?std=$selectedStd&div=$selectedDiv'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        students = (data['students'] ?? []).map<_StudentRow>((e) {
          return _StudentRow(
            id: e['_id'],
            name: e['name'],
            roll: e['roll'],
            mobile: e['mobile'],
          );
        }).toList();
      }
    } catch (_) {
      _showSnack("Error loading students");
    }

    await _checkAttendanceLock();
    setState(() => isLoadingStudents = false);
  }

  /* ================= CHECK LOCK ================= */
  Future<void> _checkAttendanceLock() async {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      final res = await http.get(
        Uri.parse(
          "$SERVER_URL/attendance/check-lock?std=$selectedStd&div=$selectedDiv&date=$date",
        ),
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final List absent = data['absent'] ?? [];
      final List late = data['late'] ?? [];

      absentRollNumbers.clear();
      lateRollNumbers.clear();

      for (final s in students) {
        s.locked = false;
        s.isPresent = true;
        s.late = false;

        if (absent.contains(s.roll)) {
          s.locked = true;
          s.isPresent = false;
          absentRollNumbers.add(s.roll);
        } else if (late.contains(s.roll)) {
          s.locked = true;
          s.late = true;
          lateRollNumbers.add(s.roll);
        }
      }
    } catch (_) {
      // silent
    }
  }

  /* ================= SAVE ATTENDANCE ================= */
  Future<void> _saveAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      _showSnack("Select STD & DIV first");
      return;
    }

    final dateStr = DateTime.now().toIso8601String();

    final payload = students.map((s) => {
          "studentId": s.id,
          "std": selectedStd,
          "div": selectedDiv,
          "roll": s.roll,
          "date": dateStr,
          "present": s.isPresent,
          "late": s.late,
        }).toList();

    try {
      final res = await http.post(
        Uri.parse("$SERVER_URL/attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": dateStr,
          "attendance": payload,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final int sentCount = data["sentCount"] ?? 0;

        setState(() => isSaved = true);
        _showMessageSentDialog(sentCount);
      } else {
        _showSnack("Attendance save failed");
      }
    } catch (_) {
      _showSnack("Network error");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedStd,
                    decoration: _inputDeco("Select STD"),
                    items: stdOptions
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedStd = v);
                      _loadDivisions();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedDiv,
                    decoration: _inputDeco("Select DIV"),
                    items: divisions
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedDiv = v);
                      _loadStudents();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: students.map(_studentTile).toList(),
                  ),
          ),
         Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        absentRollNumbers.isEmpty
            ? "Absent: None"
            : "Absent (${absentRollNumbers.length}): ${absentRollNumbers.join(', ')}",
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        lateRollNumbers.isEmpty
            ? "Late: None"
            : "Late (${lateRollNumbers.length}): ${lateRollNumbers.join(', ')}",
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
Center(
  child: ElevatedButton(
    onPressed: isSaved ? null : _saveAttendance,
    child: const Text("Save Attendance"),
  ),
),
],
),
),
],
),
);
}


  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Widget _studentTile(_StudentRow s) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          // 👤 STUDENT NAME (LEFT)
          Expanded(
            child: Text(
              s.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // 🔢 ROLL NUMBER (RIGHT SIDE – RED BOX AREA)
          SizedBox(
            width: 40,
            child: Text(
              s.roll.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ✅ PRESENT
          Column(
            children: [
              const Text("P", style: TextStyle(fontSize: 12)),
              Checkbox(
                value: s.isPresent,
                onChanged: (s.locked || isSaved)
                    ? null
                    : (v) {
                        setState(() {
                          s.isPresent = v ?? true;

                          if (!s.isPresent) {
                            s.late = false;
                            if (!absentRollNumbers.contains(s.roll)) {
                              absentRollNumbers.add(s.roll);
                            }
                            lateRollNumbers.remove(s.roll);
                          } else {
                            absentRollNumbers.remove(s.roll);
                          }

                          absentRollNumbers.sort();
                          lateRollNumbers.sort();
                        });
                      },
              ),
            ],
          ),

          const SizedBox(width: 4),

          // ⏰ LATE
          Column(
            children: [
              const Text("L", style: TextStyle(fontSize: 12)),
              Checkbox(
                value: s.late,
                onChanged: (s.isPresent && !s.locked && !isSaved)
                    ? (v) {
                        setState(() {
                          s.late = v ?? false;

                          if (s.late) {
                            if (!lateRollNumbers.contains(s.roll)) {
                              lateRollNumbers.add(s.roll);
                            }
                            absentRollNumbers.remove(s.roll);
                          } else {
                            lateRollNumbers.remove(s.roll);
                          }

                          absentRollNumbers.sort();
                          lateRollNumbers.sort();
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showMessageSentDialog(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Messages Sent"),
        content: Text("$count messages sent successfully"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

/* ================= MODEL ================= */
class _StudentRow {
  final String id;
  final String name;
  final int roll;
  final String mobile;

  bool isPresent;
  bool late;
  bool locked;

  _StudentRow({
    required this.id,
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
    this.late = false,
    this.locked = false,
  });
}
