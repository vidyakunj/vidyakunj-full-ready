// PART 1 of 3
// new_attendance_screen.dart
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
  // --- selection state
  String? selectedStd;
  String? selectedDiv;

  // --- loading flags
  bool isLoadingDivs = false;
  bool isLoadingStudents = false;

  // --- data
  List<String> divisions = [];
  List<_StudentRow> students = [];

  // --- search
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // --- other
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
      students = []; // clear students when std changes
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
      final uri =
          Uri.parse('$SERVER_URL/students?std=${Uri.encodeComponent(selectedStd!)}&div=${Uri.encodeComponent(selectedDiv!)}');
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

    setState(() {}); // ensure UI reflects sending state if you add a flag later

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

  // ---------------------- UI (start) ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // --- Gradient header
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Color(0xFF5B21B6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          child: AppBar(
            title: const Text("Daily Attendance"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // ----------------- STD + DIV card (Option A: Modern White Rounded Card) -----------------
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
                              });
                              _loadDivisions();
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // DIV dropdown
                        Expanded(
                          child: isLoadingDivs
                              ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                              : DropdownButtonFormField<String>(
                                  value: selectedDiv,
                                  decoration: InputDecoration(
                                    labelText: "Select DIV",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  items: divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
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

                    // Date + Day
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

          // PART 1 ends here; PART 2 will continue with counters, search, and student list...
        ],
      ),
    );
  }
}

// Note: PART 2 will include the counters (Total / Present / Absent), search bar, student list UI and hover cards.
// Reply "SEND PART 2" and I'll send the next chunk.
// -------- PART 2 of 3 (Attendance Counters + Search + Student List) --------

          // ----------------- ATTENDANCE COUNTERS -----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildCounterCard(
                  title: "Total",
                  value: students.length,
                  color: Colors.blue.shade50,
                  textColor: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  title: "Present",
                  value: students.where((s) => s.isPresent).length,
                  color: Colors.green.shade50,
                  textColor: Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  title: "Absent",
                  value: students.where((s) => !s.isPresent).length,
                  color: Colors.red.shade50,
                  textColor: Colors.red.shade700,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ----------------- SEARCH BAR -----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search student...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          // ----------------- TABLE HEADER -----------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.deepPurple.shade200),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 5, child: Text("Student Name",
                    style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Roll No",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Present / Absent",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // ----------------- STUDENT LIST -----------------
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      // APPLY SEARCH FILTER
                      final filteredStudents = students.where((s) {
                        if (searchQuery.isEmpty) return true;

                        final q = searchQuery.toLowerCase();
                        return s.name.toLowerCase().contains(q) ||
                            s.roll.toString().contains(q);
                      }).toList();

                      return ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final s = filteredStudents[index];

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: s.isPresent
                                    ? Colors.green.withOpacity(0.25)
                                    : Colors.red.withOpacity(0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "${s.roll}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                  ),
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
                                          color: s.isPresent
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Checkbox(
                                        value: s.isPresent,
                                        onChanged: (v) {
                                          setState(() => s.isPresent = v ?? true);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // ----------------- SAVE + EXIT BUTTONS -----------------
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saveAttendance,
                    child: const Text("SAVE",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.deepPurple.shade300),
                    ),
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

  // ---------------------- COUNTER CARD WIDGET ----------------------
  Widget _buildCounterCard({
    required String title,
    required int value,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
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
  bool hover = false;  // Required for hover animation

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
  });
}
