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
  String? selectedStd; // 1–12
  String? selectedDiv; // A, B, C, D
  bool isLoadingDivs = false;
  List<String> divisions = [];

  // Today’s date
  final DateTime today = DateTime.now();

  // Demo students for now (later we will load from backend)
  final List<_StudentRow> students = [
    _StudentRow(
      name: 'Patil Manohar',
      roll: 1,
      mobile: '8980994984',
      isPresent: true,
    ),
    _StudentRow(
      name: 'Diya Patil',
      roll: 2,
      mobile: '919265635968',
      isPresent: true,
    ),
  ];

  // List of STD options 1–12
  final List<String> stdOptions = List<String>.generate(12, (i) => '${i + 1}');

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

  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
    });

    try {
      final uri = Uri.parse(
        '$SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}',
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['divisions'] ?? [];
        setState(() {
          divisions = list.map((e) => e.toString()).toList();
          if (divisions.isNotEmpty) {
            selectedDiv = divisions.first;
          }
        });
      } else {
        _showSnack('Error loading divisions (${res.statusCode})');
      }
    } catch (e) {
      _showSnack('Error loading divisions: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingDivs = false;
        });
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _saveAttendance() async {
    // Check STD & DIV selected
    if (selectedStd == null || selectedDiv == null) {
      _showSnack('Please select STD and DIV');
      return;
    }

    // Collect absentees
    final absentees = students.where((s) => !s.isPresent).toList();
    if (absentees.isEmpty) {
      _showSnack('No absentees marked');
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
          final ok = data["success"] == true;
          if (ok) {
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

    // Show summary dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SMS Summary'),
        content: Text('$sent SMS sent\n$failed failed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exitScreen() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Attendance'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // HEADER: STD, DIV, DATE, DAY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // STD Dropdown
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                'STD : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedStd,
                                  hint: const Text('Select STD'),
                                  items: stdOptions
                                      .map(
                                        (s) => DropdownMenuItem<String>(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedStd = val;
                                    });
                                    _loadDivisions();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // DIV Dropdown
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                'DIV : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: isLoadingDivs
                                    ? const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : DropdownButtonFormField<String>(
                                        value: selectedDiv,
                                        hint: const Text('Select DIV'),
                                        items: divisions
                                            .map(
                                              (d) => DropdownMenuItem<String>(
                                                value: d,
                                                child: Text(d),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: divisions.isEmpty
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  selectedDiv = val;
                                                });
                                              },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date : $formattedDate',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Day : $dayName',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // TABLE HEADER
          Padding
            (padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: Colors.grey.shade300,
              child: Row(
                children: const [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Student Name',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Roll No',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Present / Absent',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // TABLE ROWS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color:
                        index.isEven ? Colors.grey.shade100 : Colors.grey[50],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      // Student name
                      Expanded(
                        flex: 5,
                        child: Text(
                          s.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      // Roll no
                      Expanded(
                        flex: 2,
                        child: Text(
                          s.roll.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      // Present / Absent with checkbox
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  s.isPresent ? 'Present' : 'Absent',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // SAVE / EXIT buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveAttendance();
                    },
                    child: const Text('SAVE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exitScreen,
                    child: const Text('EXIT'),
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
