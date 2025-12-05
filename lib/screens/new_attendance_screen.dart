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

  // Absent student roll numbers
  List<int> absentRollNumbers = [];

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

  // ------------------------------ LOAD DIVISIONS ------------------------------
  Future<void> _loadDivisions() async {
    if (selectedStd == null) return;

    setState(() {
      isLoadingDivs = true;
      divisions = [];
      selectedDiv = null;
      students = [];
      absentRollNumbers = [];
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

  // ------------------------------ LOAD STUDENTS ------------------------------
  Future<void> _loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    setState(() {
      isLoadingStudents = true;
      students = [];
      absentRollNumbers = [];
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

  // ------------------------------ SAVE & SMS ------------------------------
  Future<void> _saveAttendance() async {
    if (selectedStd == null || selectedDiv == null) {
      _showSnack('Select STD & DIV');
      return;
    }

    final absentees =
        students.where((s) => !s.isPresent).toList();

    if (absentees.isEmpty) {
      _showSnack("No absentees");
      return;
    }

    int sent = 0;
    int failed = 0;

    for (final s in absentees) {
      try {
        final res = await http.post(
          Uri.parse("$SERVER_URL/send-sms"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"mobile": s.mobile, "studentName": s.name}),
        );

        if (res.statusCode == 200 && jsonDecode(res.body)['success'] == true) {
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
        content: Text("$sent SMS Sent\n$failed Failed"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------ UI BUILD ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3ff), // Light navy background
      appBar: AppBar(
        backgroundColor: const Color(0xff003366), // NAVY BLUE
        elevation: 4,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 10),

            // SCHOOL LOGO
            Image.asset(
              "assets/logo.png",
              height: 40,
            ),

            const SizedBox(width: 12),

            const Text(
              "VIDYAKUNJ SCHOOL",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),

          // ------------------------------ DROPDOWNS ------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStd,
                    decoration: _inputDeco("Select STD"),
                    items: stdOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                      : DropdownButtonFormField<String>(
                          value: selectedDiv,
                          decoration: _inputDeco("Select DIV"),
                          items: divisions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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

          const SizedBox(height: 10),

          // ------------------------------ COUNTERS ------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildCounter(
                    "Total",
                    students.length,
                    Colors.blue.shade100,
                    Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCounter(
                    "Present",
                    students.where((e) => e.isPresent).length,
                    Colors.green.shade100,
                    Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCounter(
                    "Absent",
                    students.where((e) => !e.isPresent).length,
                    Colors.red.shade100,
                    Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ------------------------------ RESPONSIVE SEARCH BAR + ABSENT LIST ------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: _inputDeco("Search student...")
                            .copyWith(prefixIcon: const Icon(Icons.search)),
                        onChanged: (v) =>
                            setState(() => searchQuery = v.toLowerCase()),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Absent:",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          absentRollNumbers.isEmpty
                              ? "-"
                              : absentRollNumbers.join(","),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      SizedBox(
                        width: 230,
                        child: TextField(
                          controller: searchController,
                          decoration: _inputDeco("Search student...")
                              .copyWith(prefixIcon: const Icon(Icons.search)),
                          onChanged: (v) =>
                              setState(() => searchQuery = v.toLowerCase()),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Absent:",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                absentRollNumbers.isEmpty
                                    ? "-"
                                    : absentRollNumbers.join(","),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 10),

          // ------------------------------ HEADER ------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.blue.shade50,
            child: Row(
              children: const [
                Expanded(flex: 5, child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Roll No", textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text("Present / Absent", textAlign: TextAlign.center)),
              ],
            ),
          ),

          // ------------------------------ STUDENT LIST ------------------------------
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: students
                        .where((s) =>
                            searchQuery.isEmpty ||
                            s.name.toLowerCase().contains(searchQuery) ||
                            s.roll.toString().contains(searchQuery))
                        .map((s) => _studentTile(s))
                        .toList(),
                  ),
          ),

          // ------------------------------ SAVE / EXIT ------------------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                    onPressed: _saveAttendance,
                    child: const Text("SAVE"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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

  // ------------------------------ HELPERS ------------------------------

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildCounter(
      String title, int value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(
            "$value",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(title, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _studentTile(_StudentRow s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: s.isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              s.isPresent ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(s.name)),
          Expanded(
              flex: 2,
              child:
                  Text("${s.roll}", textAlign: TextAlign.center)),
          Expanded(
            flex: 3,
            child: Checkbox(
              value: s.isPresent,
              onChanged: (v) {
                setState(() {
                  s.isPresent = v ?? true;

                  if (!s.isPresent) {
                    if (!absentRollNumbers.contains(s.roll)) {
                      absentRollNumbers.add(s.roll);
                      absentRollNumbers.sort();
                    }
                  } else {
                    absentRollNumbers.remove(s.roll);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// MODEL -----------------------------------------------------------------

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
