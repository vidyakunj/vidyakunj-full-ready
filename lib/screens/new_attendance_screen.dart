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

  bool isLoadingDivs = false;
  bool isLoadingStudents = false;

  List<String> divisions = [];
  List<_StudentRow> students = []; // real students

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

  // ---------------------- LOAD DIVISIONS ----------------------
  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
      students = []; // reset students
    });

    try {
      final uri =
          Uri.parse('$SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['divisions'] ?? [];
        setState(() {
          divisions = list.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      _showSnack('Error loading divisions: $e');
    }

    setState(() => isLoadingDivs = false);
  }

  // ---------------------- LOAD STUDENTS ----------------------
  Future<void> _loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      isLoadingStudents = true;
      students = [];
    });

    try {
      final uri = Uri.parse(
          '$SERVER_URL/students?std=$selectedStd&div=$selectedDiv');
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
                    isPresent: true,
                  ))
              .toList();
        });
      }
    } catch (e) {
      _showSnack('Error loading students: $e');
    }

    setState(() => isLoadingStudents = false);
  }

  // ---------------------- SMS ----------------------
  Future<void> _saveAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      _showSnack('Select STD & DIV');
      return;
    }

    if (students.isEmpty) {
      _showSnack('No students found');
      return;
    }

    final absentees = students.where((s) => !s.isPresent).toList();

    if (absentees.isEmpty) {
      _showSnack('No absentees');
      return;
    }

    int sent = 0;
    int failed = 0;

    for (final s in absentees) {
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
          if (data['success'] == true) {
            sent++;
          } else {
            failed++;
          }
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
      builder: (ctx) => AlertDialog(
        title: const Text("SMS Summary"),
        content: Text("$sent SMS sent\n$failed failed"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
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

  void _exitScreen() {
    Navigator.of(context).pop();
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Attendance")),

      body: Column(
        children: [
          const SizedBox(height: 8),

          // HEADER SECTION — STD, DIV, DATE, DAY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // STD DROPDOWN
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStd,
                            hint: const Text("Select STD"),
                            items: stdOptions
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedStd = val;
                              });
                              _loadDivisions();
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // DIV DROPDOWN
                        Expanded(
                          child: isLoadingDivs
                              ? const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : DropdownButtonFormField<String>(
                                  value: selectedDiv,
                                  hint: const Text("Select DIV"),
                                  items: divisions
                                      .map((d) => DropdownMenuItem(
                                            value: d,
                                            child: Text(d),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedDiv = val;
                                    });
                                    if (val != null) _loadStudents();
                                  },
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(child: Text("Date: $formattedDate")),
                        Expanded(
                          child: Text(
                            "Day: $dayName",
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // TABLE HEADER
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Expanded(flex: 5, child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Roll No", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Present / Absent", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // STUDENT LIST
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          color: index.isEven
                              ? Colors.grey.shade100
                              : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 5, child: Text(s.name)),
                            Expanded(
                                flex: 2,
                                child: Text("${s.roll}",
                                    textAlign: TextAlign.center)),
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        s.isPresent ? "Present" : "Absent",
                                        style: TextStyle(
                                          color: s.isPresent
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Checkbox(
                                        value: s.isPresent,
                                        onChanged: (v) {
                                          setState(() {
                                            s.isPresent = v ?? true;
                                          });
                                        },
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // SAVE + EXIT
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAttendance,
                    child: const Text("SAVE"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exitScreen,
                    child: const Text("EXIT"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
