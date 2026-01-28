import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';

class SecondaryStudentAttendanceReport extends StatefulWidget {
  const SecondaryStudentAttendanceReport({super.key});

  @override
  State<SecondaryStudentAttendanceReport> createState() =>
      _SecondaryStudentAttendanceReportState();
}

class _SecondaryStudentAttendanceReportState
    extends State<SecondaryStudentAttendanceReport> {

  static const Color navy = Color(0xFF0D1B2A);
  DateTime selectedDate = DateTime.now();

  /// cache key = "9-A"
  final Map<String, List<dynamic>> _cache = {};
  final Set<String> _loading = {};

  Future<void> loadStudents(String std, String div) async {
    final key = "$std-$div";
    if (_cache.containsKey(key)) return;

    setState(() => _loading.add(key));

    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final res = await http.get(
        Uri.parse(
          "$SERVER_URL/attendance/list?std=$std&div=$div&date=$dateStr",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cache[key] = data["students"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Load students error: $e");
    }

    setState(() => _loading.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secondary Student Attendance'),
        centerTitle: true,
        backgroundColor: navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _StdTile(std: '9'),
          _StdTile(std: '10'),
          _StdTile(std: '11'),
          _StdTile(std: '12'),
        ],
      ),
    );
  }

  /// ================= STD TILE =================

  Widget stdTile(String std) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          'STD $std',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: navy,
          ),
        ),
        children: ['A', 'B', 'C']
            .map(
              (div) => divisionBlock(std, div),
            )
            .toList(),
      ),
    );
  }

  /// ================= DIV BLOCK =================

  Widget divisionBlock(String std, String div) {
    final key = "$std-$div";
    final students = _cache[key];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => loadStudents(std, div),
            child: Text(
              "DIV $div",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),
          const SizedBox(height: 6),

          if (_loading.contains(key))
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

          if (students != null)
            ...students.map(
              (s) => StudentRow(
                roll: s["rollNo"],
                name: s["name"],
                status: s["status"],
              ),
            ),
        ],
      ),
    );
  }
}

/// ================= STUDENT ROW =================

class StudentRow extends StatelessWidget {
  final int roll;
  final String name;
  final String status;

  const StudentRow({
    super.key,
    required this.roll,
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case "present":
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case "late":
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      default:
        icon = Icons.cancel;
        color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              roll.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(name)),
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }
}
