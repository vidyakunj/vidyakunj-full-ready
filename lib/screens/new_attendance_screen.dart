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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _exitScreen() {
    Navigator.of(context).pop();
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: PreferredSize(
  preferredSize: const Size.fromHeight(92),
  child: AppBar(
    automaticallyImplyLeading: false,
    elevation: 6,
    centerTitle: false,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5B21B6), // deep purple
            Color(0xFF7C3AED), // lighter purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 3),
            blurRadius: 8,
          )
        ],
      ),
    ),
    backgroundColor: Colors.transparent,
    title: Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          // small circular logo placeholder (replace with asset if you have one)
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Vidyakunj Attendance",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Daily Attendance",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12.0, top: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications, color: Colors.white),
            SizedBox(height: 2),
            Text("Admin", style: TextStyle(color: Colors.white70, fontSize: 10))
          ],
        ),
      )
    ],
  ),
),


      body: Column(
        children: [
          const SizedBox(height: 8),

          // HEADER CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStd,
                            decoration: InputDecoration(
                              labelText: "Select STD",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: stdOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
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
                                  child: CircularProgressIndicator(),
                                )
                              : DropdownButtonFormField<String>(
                                  value: selectedDiv,
                                  decoration: InputDecoration(
                                    labelText: "Select DIV",
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: divisions
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => selectedDiv = v);
                                    if (v != null) _loadStudents();
                                  },
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // DATE + DAY
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: $formattedDate",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Day: $dayName",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // SEARCH BAR
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search student...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          // TABLE HEADER
          Container(
            color: Colors.deepPurple.shade50,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 5,
                  child: Text(
                    "Student Name",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Roll No",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Present / Absent",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // STUDENT LIST
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
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
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.white
                                  : Colors.grey.shade100,
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 5, child: Text(s.name)),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "${s.roll}",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Text(
                                        s.isPresent
                                            ? "Present"
                                            : "Absent",
                                        style: TextStyle(
                                          color: s.isPresent
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Checkbox(
                                        value: s.isPresent,
                                        onChanged: (v) {
                                          setState(() =>
                                              s.isPresent = v ?? true);
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

          // SAVE + EXIT BUTTONS
          Padding(
            padding: const EdgeInsets.all(14.0),
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
          ),
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
  bool isPresent;

  _StudentRow({
    required this.name,
    required this.roll,
    required this.mobile,
    this.isPresent = true,
  });
}
