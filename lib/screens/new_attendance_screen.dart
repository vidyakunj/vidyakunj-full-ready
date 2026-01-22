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

  List<String> divisions = [];
  List<_StudentRow> students = [];
  List<int> absentRollNumbers = [];
  List<int> lateRollNumbers = [];

  final List<String> stdOptions =
      List<String>.generate(12, (i) => '${i + 1}');

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
    } catch (e) {
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
    } catch (e) {
      _showSnack("Error loading students");
    }

    await _checkAttendanceLock();
    setState(() => isLoadingStudents = false);
  }

  /* ================= LOCK CHECK ================= */
Future<void> _checkAttendanceLock() async {
  final today = DateTime.now();
  final date =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  final res = await http.get(
    Uri.parse(
      "$SERVER_URL/attendance/check-lock?std=$selectedStd&div=$selectedDiv&date=$date",
    ),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    final List absent = data['absent'] ?? [];
    final List late = data['late'] ?? [];

    absentRollNumbers.clear();
    lateRollNumbers.clear();

    for (final s in students) {
      // ABSENT
      if (absent.contains(s.roll)) {
        s.locked = true;
        s.isPresent = false;
        s.late = false;

        absentRollNumbers.add(s.roll);
      }

      // LATE
      else if (late.contains(s.roll)) {
        s.locked = true;
        s.isPresent = true;
        s.late = true;

        lateRollNumbers.add(s.roll);
      }
    }
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
        _showSnack("Attendance saved & SMS sent successfully");
      } else {
        _showSnack("Attendance save failed");
      }
    } catch (e) {
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
      appBar: AppBar(
        backgroundColor: const Color(0xff003366),
        title: const Text("Vidyakunj School"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
                  child: isLoadingDivs
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField(
                          value: selectedDiv,
                          decoration: _inputDeco("Select DIV"),
                          items: divisions
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e)))
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
                : ListView(children: students.map(_studentTile).toList()),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absentRollNumbers.isEmpty
                            ? "Absent: None"
                            : "Absent (${absentRollNumbers.length}): ${absentRollNumbers.join(', ')}",
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        lateRollNumbers.isEmpty
                            ? "Late: None"
                            : "Late (${lateRollNumbers.length}): ${lateRollNumbers.join(', ')}",
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveAttendance,
                  child: const Text("Save Attendance"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ================= HELPERS ================= */
  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

 Widget _studentTile(_StudentRow s) {
  return Container(
    margin: const EdgeInsets.all(6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: !s.isPresent
          ? Colors.red.shade50
          : s.late
              ? Colors.amber.shade50
              : Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(flex: 5, child: Text(s.name)),
        Expanded(flex: 2, child: Text("${s.roll}")),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              // ✅ PRESENT
              Checkbox(
                value: s.isPresent,
                onChanged: s.locked
                    ? null
                    : (v) {
                        setState(() {
                          s.isPresent = v ?? true;

                          if (!s.isPresent) {
                            s.late = false;
                            lateRollNumbers.remove(s.roll);
                            if (!absentRollNumbers.contains(s.roll)) {
                              absentRollNumbers.add(s.roll);
                            }
                          } else {
                            absentRollNumbers.remove(s.roll);
                          }
                        });
                      },
              ),

              // ✅ LATE (NEVER ABSENT)
              Checkbox(
                value: s.late,
                onChanged: (s.isPresent && !s.locked)
                    ? (v) {
                        setState(() {
                          s.late = v ?? false;

                          if (s.late) {
                            s.isPresent = true;
                            absentRollNumbers.remove(s.roll);
                            if (!lateRollNumbers.contains(s.roll)) {
                              lateRollNumbers.add(s.roll);
                            }
                          } else {
                            lateRollNumbers.remove(s.roll);
                          }
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
