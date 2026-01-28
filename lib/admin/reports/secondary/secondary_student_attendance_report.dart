import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class SecondaryStudentAttendanceReport extends StatefulWidget {
  const SecondaryStudentAttendanceReport({super.key});

  @override
  State<SecondaryStudentAttendanceReport> createState() =>
      _SecondaryStudentAttendanceReportState();
}

class _SecondaryStudentAttendanceReportState
    extends State<SecondaryStudentAttendanceReport> {

  DateTime selectedDate = DateTime.now();
  static const Color navy = Color(0xFF0D1B2A);

  // cache: key = "std_div_date"
  final Map<String, List<dynamic>> _cache = {};
  final Map<String, bool> _loading = {};

  String get _dateStr =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> loadStudents(String std, String div) async {
    final key = "$std-$div-$_dateStr";

    if (_cache.containsKey(key) || _loading[key] == true) return;

    setState(() => _loading[key] = true);

    try {
      final res = await http.get(
        Uri.parse(
          "$SERVER_URL/attendance/list?std=$std&div=$div&date=$_dateStr",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cache[key] = data["students"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Attendance load error: $e");
    }

    setState(() => _loading[key] = false);
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
        children: [
          _StdTile(std: '9', load: loadStudents, cache: _cache, loading: _loading),
          _StdTile(std: '10', load: loadStudents, cache: _cache, loading: _loading),
          _StdTile(std: '11', load: loadStudents, cache: _cache, loading: _loading),
          _StdTile(std: '12', load: loadStudents, cache: _cache, loading: _loading),
        ],
      ),
    );
  }
}

/* ================= STD TILE ================= */

class _StdTile extends StatelessWidget {
  final String std;
  final Function(String, String) load;
  final Map<String, List<dynamic>> cache;
  final Map<String, bool> loading;

  const _StdTile({
    required this.std,
    required this.load,
    required this.cache,
    required this.loading,
  });

  static const Color navy = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
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
        children: [
          _DivisionBlock(
            std: std,
            div: 'A',
            load: load,
            cache: cache,
            loading: loading,
          ),
          _DivisionBlock(
            std: std,
            div: 'B',
            load: load,
            cache: cache,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

/* ================= DIVISION BLOCK ================= */

class _DivisionBlock extends StatelessWidget {
  final String std;
  final String div;
  final Function(String, String) load;
  final Map<String, List<dynamic>> cache;
  final Map<String, bool> loading;

  const _DivisionBlock({
    required this.std,
    required this.div,
    required this.load,
    required this.cache,
    required this.loading,
  });

  String get key => "$std-$div";

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final cacheKey = "$std-$div-$dateStr";

    final students = cache[cacheKey] ?? [];
    final isLoading = loading[cacheKey] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => load(std, div),
            child: Text(
              'DIV $div',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
          ),
          const SizedBox(height: 6),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          for (final s in students)
            _StudentRow(
              roll: s["rollNo"],
              name: s["name"],
              status: s["status"],
            ),
        ],
      ),
    );
  }
}

/* ================= STUDENT ROW ================= */

class _StudentRow extends StatelessWidget {
  final int roll;
  final String name;
  final String status;

  const _StudentRow({
    required this.roll,
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case 'present':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'late':
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
