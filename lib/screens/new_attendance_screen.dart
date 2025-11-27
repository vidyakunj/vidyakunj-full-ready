// lib/screens/new_attendance_screen.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  bool isSendingSms = false;

  List<String> divisions = [];
  List<_StudentRow> students = [];
  final TextEditingController searchController = TextEditingController();
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

  // ---------------------- LOAD DIVISIONS ----------------------
  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
      students = [];
    });

    try {
      final uri = Uri.parse('$SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['divisions'] ?? [];
        setState(() {
          divisions = list.map((e) => e.toString()).toList();
        });
      } else {
        _showSnack('Error loading divisions (${res.statusCode})');
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
      final uri = Uri.parse('$SERVER_URL/students?std=$selectedStd&div=$selectedDiv');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['students'] ?? [];

        setState(() {
          students = list
              .map((e) => _StudentRow(
                    name: e['name'] ?? '',
                    roll: (e['roll'] is int) ? e['roll'] : int.tryParse('${e['roll']}') ?? 0,
                    mobile: e['mobile'] ?? '',
                    isPresent: true,
                  ))
              .toList();
        });
      } else {
        _showSnack('Error loading students (${res.statusCode})');
      }
    } catch (e) {
      _showSnack('Error loading students: $e');
    }

    setState(() => isLoadingStudents = false);
  }

  // ---------------------- SEND SMS ----------------------
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
      _showSnack('No absentees to notify');
      return;
    }

    setState(() => isSendingSms = true);
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

    setState(() => isSendingSms = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("SMS Summary"),
        content: Text("$sent SMS sent\n$failed failed"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _exitScreen() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // Quick actions
  void _markAllPresent() {
    setState(() {
      for (var s in students) s.isPresent = true;
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var s in students) s.isPresent = false;
    });
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    // filtered list according to search
    final filteredStudents = students.where((s) {
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.roll.toString().contains(q);
    }).toList();

    final total = students.length;
    final presentCount = students.where((s) => s.isPresent).length;
    final absentCount = total - presentCount;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- TOP HEADER with gradient ----------
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  // logo + title
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Vidyakunj Attendance", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text("Daily Attendance", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Date: $formattedDate", style: const TextStyle(color: Colors.white70)),
                      Text("Day: $dayName", style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ---------- Controls (STD / DIV) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedStd,
                              decoration: InputDecoration(
                                labelText: "Select STD",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                isDense: true,
                              ),
                              items: stdOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedStd = val;
                                });
                                _loadDivisions();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isLoadingDivs
                                ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                                : DropdownButtonFormField<String>(
                                    value: selectedDiv,
                                    decoration: InputDecoration(
                                      labelText: "Select DIV",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      isDense: true,
                                    ),
                                    items: divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                    onChanged: (val) {
                                      setState(() => selectedDiv = val);
                                      if (val != null) _loadStudents();
                                    },
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // quick action buttons
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: students.isEmpty ? null : _markAllPresent,
                            icon: const Icon(Icons.check),
                            label: const Text("Mark all Present"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: students.isEmpty ? null : _markAllAbsent,
                            icon: const Icon(Icons.close),
                            label: const Text("Mark all Absent"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                          ),
                          const Spacer(),
                          Text("Total: $total   Present: $presentCount   Absent: $absentCount", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---------- Search ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search student by name or roll...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => searchQuery = v),
              ),
            ),

            const SizedBox(height: 12),

            // ---------- List header ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 5, child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.w700))),
                    Expanded(flex: 2, child: Center(child: Text("Roll No", style: TextStyle(fontWeight: FontWeight.w700)))),
                    Expanded(flex: 3, child: Center(child: Text("Present / Absent", style: TextStyle(fontWeight: FontWeight.w700)))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ---------- Student list ----------
            Expanded(
              child: isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                      ? Center(child: Text(students.isEmpty ? "Select STD & DIV to load students" : "No students found", style: const TextStyle(color: Colors.black54)))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final s = filteredStudents[index];

                              return _StudentCard(
                                student: s,
                                onChanged: (val) {
                                  setState(() => s.isPresent = val);
                                },
                              );
                            },
                          ),
                        ),
            ),

            // ---------- Bottom action bar ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSendingSms ? null : _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSendingSms
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SAVE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _exitScreen,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      child: const Text("EXIT", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Student card widget (Style B: strong modern shadow) ----------
class _StudentCard extends StatefulWidget {
  final _StudentRow student;
  final ValueChanged<bool> onChanged;

  const _StudentCard({
    required this.student,
    required this.onChanged,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final present = s.isPresent;

    // gradient border colors
    final borderGradient = present
        ? [Colors.green.shade400, Colors.green.shade200]
        : [Colors.red.shade400, Colors.red.shade200];

    return MouseRegion(
      onEnter: (_) {
        if (kIsWeb || defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
          setState(() => hovering = true);
        }
      },
      onExit: (_) {
        if (kIsWeb || defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
          setState(() => hovering = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: present ? Colors.green.shade100 : Colors.red.shade100, width: 1.6),
          boxShadow: hovering
              ? [
                  BoxShadow(
                    color: present ? Colors.green.shade200.withOpacity(0.22) : Colors.red.shade200.withOpacity(0.22),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  )
                ]
              : [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                s.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text("${s.roll}", style: const TextStyle(fontSize: 15))),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Text(
                    present ? "Present" : "Absent",
                    style: TextStyle(
                      color: present ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Checkbox(
                    value: present,
                    onChanged: (v) {
                      final val = v ?? true;
                      widget.onChanged(val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- STUDENT MODEL ----------------------
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
