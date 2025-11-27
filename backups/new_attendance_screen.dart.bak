import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

// *************************************************************
// NEW MODERN ATTENDANCE SCREEN (100% stable for Flutter Web)
// *************************************************************

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
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  final List<String> stdOptions = List<String>.generate(12, (i) => '${i + 1}');
  final DateTime today = DateTime.now();

  String get formattedDate =>
      '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

  String get dayName {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[today.weekday];
  }

  // ============================================================
  // LOAD DIVISIONS
  // ============================================================
  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
      students = [];
    });

    try {
      final uri = Uri.parse(
          '$SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['divisions'] ?? [];

        setState(() {
          divisions = list.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      _showSnack("Error loading divisions: $e");
    }

    setState(() => isLoadingDivs = false);
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================
  Future<void> _loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      isLoadingStudents = true;
      students = [];
    });

    try {
      final uri =
          Uri.parse('$SERVER_URL/students?std=$selectedStd&div=$selectedDiv');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['students'] ?? [];

        setState(() {
          students = list
              .map((e) => _StudentRow(
                    name: e['name'],
                    roll: e['roll'],
                    mobile: e['mobile'],
                  ))
              .toList();
        });
      }
    } catch (e) {
      _showSnack("Error loading students: $e");
    }

    setState(() => isLoadingStudents = false);
  }

  // ============================================================
  // SEND SMS API
  // ============================================================
  Future<void> _saveAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      _showSnack("Select STD & DIV");
      return;
    }

    if (students.isEmpty) {
      _showSnack("No students found");
      return;
    }

    final absentees = students.where((s) => !s.isPresent).toList();

    if (absentees.isEmpty) {
      _showSnack("No absentees today");
      return;
    }

    int sent = 0;
    int failed = 0;

    for (final s in absentees) {
      try {
        final res = await http.post(
          Uri.parse("$SERVER_URL/send-sms"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "mobile": s.mobile.trim(),
            "studentName": s.name.trim(),
          }),
        );

        if (res.statusCode == 200 &&
            jsonDecode(res.body)['success'] == true) {
          sent++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("SMS Summary"),
        content: Text("$sent SMS sent\n$failed failed"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _exitScreen() => Navigator.pop(context);

  // ============================================================
  // MAIN UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Attendance"),
        elevation: 3,
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // ******************************************************
          // HEADER CARD
          // ******************************************************
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStd,
                            decoration: _inputStyle("Select STD"),
                            items: stdOptions
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
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
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: selectedDiv,
                                  decoration: _inputStyle("Select DIV"),
                                  items: divisions
                                      .map((d) => DropdownMenuItem(
                                          value: d, child: Text(d)))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => selectedDiv = v);
                                    if (v != null) _loadStudents();
                                  },
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Text("Date: $formattedDate",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Text("Day: $dayName",
                              textAlign: TextAlign.right,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ============================================================
          // COUNTER ROW — TOTAL / PRESENT / ABSENT
          // ============================================================
          if (!isLoadingStudents && students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _countCard("Total", students.length,
                      Colors.blue.shade50, Colors.blue.shade700),
                  const SizedBox(width: 10),
                  _countCard(
                      "Present",
                      students.where((s) => s.isPresent).length,
                      Colors.green.shade50,
                      Colors.green.shade700),
                  const SizedBox(width: 10),
                  _countCard(
                      "Absent",
                      students.where((s) => !s.isPresent).length,
                      Colors.red.shade50,
                      Colors.red.shade700),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ============================================================
          // SEARCH BAR
          // ============================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: _searchStyle(),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),

          const SizedBox(height: 10),

          // ============================================================
          // TABLE HEADER
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.deepPurple.shade50,
            child: Row(
              children: const [
                Expanded(flex: 5, child: Text("Student Name")),
                Expanded(flex: 2, child: Text("Roll No", textAlign: TextAlign.center)),
                Expanded(
                    flex: 3,
                    child: Text("Present / Absent",
                        textAlign: TextAlign.center)),
              ],
            ),
          ),

          // ============================================================
          // STUDENT LIST
          // ============================================================
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _buildStudentList(),
          ),

          // ============================================================
          // SAVE + EXIT
          // ============================================================
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: _saveAttendance,
                        child: const Text("SAVE"))),
                const SizedBox(width: 12),
                Expanded(
                    child: OutlinedButton(
                        onPressed: _exitScreen,
                        child: const Text("EXIT"))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  InputDecoration _searchStyle() {
    return InputDecoration(
      hintText: "Search student...",
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _countCard(
      String title, int value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text("$value",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Text(title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filtered = students.where((s) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.roll.toString().contains(q);
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final s = filtered[i];

        return MouseRegion(
          onEnter: (_) => setState(() => s.hover = true),
          onExit: (_) => setState(() => s.hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: s.hover
                  ? [
                      BoxShadow(
                          color: Colors.deepPurple.shade200.withOpacity(0.33),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : [
                      BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
              border: Border.all(
                color: s.isPresent
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Text(s.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Text("${s.roll}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15)),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(
                        s.isPresent ? "Present" : "Absent",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: s.isPresent ? Colors.green : Colors.red),
                      ),
                      Checkbox(
                          value: s.isPresent,
                          onChanged: (v) {
                            setState(() => s.isPresent = v ?? true);
                          }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// *************************************************************
// STUDENT MODEL
// *************************************************************
class _StudentRow {
  final String name;
  final int roll;
  final String mobile;
  bool isPresent;
  bool hover = false;

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
  });
}
