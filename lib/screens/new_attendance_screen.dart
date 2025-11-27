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
      '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

  String get dayName {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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
        setState(() => divisions = list.map((e) => e.toString()).toList());
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
                    name: e['name'],
                    roll: e['roll'],
                    mobile: e['mobile'],
                  ))
              .toList();
        });
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
          body: jsonEncode({"mobile": s.mobile.trim(), "studentName": s.name.trim()}),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          data['success'] == true ? sent++ : failed++;
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

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // --------------------- HEADER ---------------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: AppBar(
            title: const Text("Daily Attendance"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
        ),
      ),

      // --------------------- BODY ---------------------
      body: Column(
        children: [
          const SizedBox(height: 10),

          // --------------------- COUNTERS ---------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoCard("Total", students.length.toString(), Colors.blue.shade50, Colors.blue),
              _infoCard(
                  "Present",
                  students.where((s) => s.isPresent).length.toString(),
                  Colors.green.shade50,
                  Colors.green),
              _infoCard(
                  "Absent",
                  students.where((s) => !s.isPresent).length.toString(),
                  Colors.red.shade50,
                  Colors.red),
            ],
          ),

          const SizedBox(height: 10),

          // --------------------- SEARCH ---------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search student...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),

          // --------------------- LIST ---------------------
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _buildStudentList(),
          ),

          // --------------------- BUTTONS ---------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAttendance,
                    child: const Text("SAVE"),
                  ),
                ),
                const SizedBox(width: 12),
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

  // ----------------- STUDENT LIST -----------------
  Widget _buildStudentList() {
    final filtered = students.where((s) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.roll.toString().contains(q);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final s = filtered[index];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: s.isPresent ? Colors.green : Colors.red,
                      ),
                    ),
                    Checkbox(
                      value: s.isPresent,
                      onChanged: (v) => setState(() => s.isPresent = v ?? true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------- COUNTER CARD -----------------
  Widget _infoCard(String title, String value, Color bg, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------------- STUDENT MODEL ----------------------
class _StudentRow {
  final String name;
  final int roll;
  final String mobile;
  bool isPresent = true;

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
  });
}
