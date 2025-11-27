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
  List<_StudentRow> students = [];

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  final List<String> stdOptions = List<String>.generate(12, (i) => '${i + 1}');

  final DateTime today = DateTime.now();

  String get formattedDate =>
      "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";

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

  // -----------------------------------------------------------
  // LOAD DIVISIONS
  // -----------------------------------------------------------
  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
      students = [];
    });

    try {
      final uri =
          Uri.parse("$SERVER_URL/divisions?std=${Uri.encodeComponent(selectedStd!)}");
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data["divisions"] ?? [];
        setState(() {
          divisions = list.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      _showSnack("Error loading divisions: $e");
    }

    setState(() => isLoadingDivs = false);
  }

  // -----------------------------------------------------------
  // LOAD STUDENTS
  // -----------------------------------------------------------
  Future<void> _loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      isLoadingStudents = true;
      students = [];
    });

    try {
      final uri =
          Uri.parse("$SERVER_URL/students?std=$selectedStd&div=$selectedDiv");
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data["students"] ?? [];

        setState(() {
          students = list
              .map(
                (e) => _StudentRow(
                  name: e["name"],
                  roll: e["roll"],
                  mobile: e["mobile"],
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      _showSnack("Error loading students: $e");
    }

    setState(() => isLoadingStudents = false);
  }

  // -----------------------------------------------------------
  // SEND SMS
  // -----------------------------------------------------------
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
      _showSnack("No absentees");
      return;
    }

    int sent = 0, failed = 0;

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
            jsonDecode(res.body)["success"] == true) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _exitScreen() {
    Navigator.of(context).pop();
  }

  // -----------------------------------------------------------
  // UI STARTS HERE
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),

      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeaderCard(),
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 6),
          _buildTableHeader(),
          Expanded(child: _buildStudentList()),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Gradient AppBar
  // -----------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(92),
      child: AppBar(
        automaticallyImplyLeading: false,
        elevation: 6,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF5B21B6),
                Color(0xFF7C3AED),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.school, size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vidyakunj Attendance",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Daily Attendance",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // HEADER CARD
  // -----------------------------------------------------------
  Widget _buildHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStdDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDivDropdown()),
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
    );
  }

  Widget _buildStdDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedStd,
      decoration: _inputDeco("Select STD"),
      items: stdOptions
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        setState(() => selectedStd = v);
        _loadDivisions();
      },
    );
  }

  Widget _buildDivDropdown() {
    if (isLoadingDivs) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: selectedDiv,
      decoration: _inputDeco("Select DIV"),
      items: divisions
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        setState(() => selectedDiv = v);
        if (v != null) _loadStudents();
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // -----------------------------------------------------------
  // SEARCH BAR
  // -----------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: searchController,
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: "Search student...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // TABLE HEADER
  // -----------------------------------------------------------
  Widget _buildTableHeader() {
    return Container(
      color: Colors.deepPurple.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: const [
          Expanded(
            flex: 5,
            child: Text("Student Name",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          Expanded(
            flex: 2,
            child: Text("Roll No",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          Expanded(
            flex: 3,
            child: Text("Present / Absent",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // STUDENT LIST
  // -----------------------------------------------------------
  Widget _buildStudentList() {
    if (isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = students.where((s) {
      final q = searchQuery.toLowerCase();
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.roll.toString().contains(q);
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, index) => _buildStudentCard(filtered[index], index),
    );
  }

  //------------------------------------------------------------
  // STUDENT CARD (HOVER EFFECT)
  //------------------------------------------------------------
  Widget _buildStudentCard(_StudentRow s, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => s.hover = true),
      onExit: (_) => setState(() => s.hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: s.hover
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.shade200.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
          border: Border.all(
            color:
                s.isPresent ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                s.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${s.roll}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Text(
                    s.isPresent ? "Present" : "Absent",
                    style: TextStyle(
                      color: s.isPresent ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Checkbox(
                    value: s.isPresent,
                    onChanged: (v) {
                      setState(() => s.isPresent = v ?? true);
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // BOTTOM BUTTONS
  // -----------------------------------------------------------
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _saveAttendance,
              child: const Text("SAVE"),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: OutlinedButton(
              onPressed: _exitScreen,
              child: const Text("EXIT"),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// STUDENT MODEL
// -----------------------------------------------------------
class _StudentRow {
  final String name;
  final int roll;
  final String mobile;

  bool isPresent;
  bool hover;

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
    this.hover = false,
  });
}
