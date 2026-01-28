import 'package:flutter/material.dart';

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
}

/* ================= STD TILE ================= */

class _StdTile extends StatelessWidget {
  final String std;
  const _StdTile({required this.std});

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
        children: const [
          _DivisionBlock(div: 'A'),
          _DivisionBlock(div: 'B'),
        ],
      ),
    );
  }
}

/* ================= DIVISION BLOCK ================= */

class _DivisionBlock extends StatelessWidget {
  final String div;
  const _DivisionBlock({required this.div});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIV $div',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),

          const _StudentRow(
            roll: 1,
            name: 'Ramesh Patel',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const _StudentRow(
            roll: 2,
            name: 'Sita Mehta',
            icon: Icons.cancel,
            color: Colors.red,
          ),
          const _StudentRow(
            roll: 3,
            name: 'Mohan Das',
            icon: Icons.access_time,
            color: Colors.orange,
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
  final IconData icon;
  final Color color;

  const _StudentRow({
    required this.roll,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Text(name),
          ),
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }
}
