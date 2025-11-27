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

  List<String> divisions = [];
  List<_StudentRow> students = [];

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  final List<String> stdOptions = List<String>.generate(12, (i) => '${i + 1}');
  final DateTime today = DateTime.now();

  String get formattedDate {
    final d = today.day.toString().padLeft(2, "0");
    final m = today.month.toString().padLeft(2, "0");
    final y = today.year.toString();
    return "$d/$m/$y";
  }

  String get dayName {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
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
        _showSnack('Failed to load divisions (status ${res.statusCode})');
      }
    } catch (e) {
      _showSnack('Error loading divisions: $e');
    } finally {
      setState(() => isLoadingDivs = false);
    }
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
          '$SERVER_URL/students?std=${Uri.encodeComponent(selectedStd!)}&div=${Uri.encodeComponent(selectedDiv!)}');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['students'] ?? [];

        setState(() {
          students = list
              .map((e) => _StudentRow(
                    name: (e['name'] ?? '').toString(),
                    roll: (e['roll'] is int) ? e['roll'] as int : int.tryParse('${e['roll']}') ?? 0,
                    mobile: (e['mobile'] ?? '').toString(),
                  ))
              .toList();
        });
      } else {
        _showSnack('Failed to load students (status ${res.statusCode})');
      }
    } catch (e) {
      _showSnack('Error loading students: $e');
    } finally {
      setState(() => isLoadingStudents = false);
    }
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
      _showSnack('No absentees');
      return;
    }

    int sent = 0;
    int failed = 0;

    // Optionally you can set a sending flag here to disable the UI while sending
    for (final s in absentees) {
      try {
        final res = await http.post(
          Uri.parse('$SERVER_URL/send-sms'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"mobile": s.mobile.trim(), "studentName": s.name.trim()}),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _exitScreen() {
    Navigator.of(context).pop();
  }

  // MARK ALL PRESENT / ABSENT
  void _markAllPresent() {
    setState(() {
      for (var s in students) {
        s.isPresent = true;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var s in students) {
        s.isPresent = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // filtered list for search
    final filteredStudents = students.where((s) {
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.roll.toString().contains(q);
    }).toList();

    final total = students.length;
    final presentCount = students.where((s) => s.isPresent).length;
    final absentCount = students.where((s) => !s.isPresent).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // Header
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.school, color: Colors.white, size: 26),
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
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.notifications, color: Colors.white),
                    SizedBox(height: 2),
                    Text("Admin", style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // STD + DIV card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // STD dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStd,
                            decoration: InputDecoration(
                              labelText: "Select STD",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            items: stdOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedStd = val;
                                selectedDiv = null;
                              });
                              _loadDivisions();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // DIV dropdown
                        Expanded(
                          child: isLoadingDivs
                              ? SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                              : DropdownButtonFormField<String>(
                                  value: selectedDiv,
                                  decoration: InputDecoration(
                                    labelText: "Select DIV",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    Row(
                      children: [
                        Expanded(child: Text("Date: $formattedDate", style: const TextStyle(fontWeight: FontWeight.w600))),
                        Expanded(child: Text("Day: $dayName", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // COUNTERS (pastel style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _counterCard("Total", total, Colors.blue.shade50, Colors.blue.shade800),
                const SizedBox(width: 10),
                _counterCard("Present", presentCount, Colors.green.shade50, Colors.green.shade800),
                const SizedBox(width: 10),
                _counterCard("Absent", absentCount, Colors.red.shade50, Colors.red.shade800),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // SEARCH + MARK ALL buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Search expanded
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search student by name or roll...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),

                const SizedBox(width: 10),

                // Mark all buttons
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                          onPressed: students.isEmpty ? null : _markAllPresent,
                          child: const Text("Mark All Present"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                          onPressed: students.isEmpty ? null : _markAllAbsent,
                          child: const Text("Mark All Absent"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // TABLE HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.deepPurple.shade50, border: Border(bottom: BorderSide(color: Colors.deepPurple.shade200))),
            child: Row(
              children: const [
                Expanded(flex: 5, child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Roll No", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Present / Absent", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // STUDENT LIST
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : filteredStudents.isEmpty
                    ? Center(child: Text(selectedStd == null || selectedDiv == null ? "Select STD & DIV to load students" : "No students found"))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final s = filteredStudents[index];

                          return MouseRegion(
                            onEnter: (_) {
                              if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
                                setState(() => s.hover = true);
                              }
                            },
                            onExit: (_) {
                              if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
                                setState(() => s.hover = false);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: s.isPresent ? Colors.green.withOpacity(0.18) : Colors.red.withOpacity(0.18)),
                                boxShadow: s.hover
                                    ? [
                                        BoxShadow(
                                          color: Colors.deepPurple.shade100.withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        )
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black12.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text("${s.roll}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        Text(s.isPresent ? "Present" : "Absent", style: TextStyle(fontWeight: FontWeight.bold, color: s.isPresent ? Colors.green : Colors.red)),
                                        Checkbox(value: s.isPresent, onChanged: (v) => setState(() => s.isPresent = v ?? true)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // SAVE + EXIT
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    onPressed: _saveAttendance,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text("SAVE", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.deepPurple.shade300), padding: const EdgeInsets.symmetric(vertical: 14)),
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

  // ---------------------- COUNTER CARD ----------------------
  Widget _counterCard(String title, int value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9))),
        ]),
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
  bool hover = false;

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
  });
}
