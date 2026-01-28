import 'package:flutter/material.dart';

class SecondaryStudentAttendanceReport extends StatelessWidget {
  const SecondaryStudentAttendanceReport({super.key});

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
          _StdSection(std: '9'),
          _StdSection(std: '10'),
          _StdSection(std: '11'),
          _StdSection(std: '12'),
        ],
      ),
    );
  }
}

/* ================= STD SECTION ================= */

class _StdSection extends StatelessWidget {
  final String std;
  const _StdSection({required this.std});

  static const Color navy = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        collapsedBackgroundColor: navy.withOpacity(0.06),
        backgroundColor: navy.withOpacity(0.04),
        title: Text(
          'STD $std',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        children: const [
          _DivisionSection(div: 'A'),
          _DivisionSection(div: 'B'),
        ],
      ),
    );
  }
}

/* ================= DIV SECTION ================= */

class _DivisionSection extends StatelessWidget {
  final String div;
  const _DivisionSection({required this.div});

  static const Color navy = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DIV HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: navy.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'DIV $div',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // STUDENTS
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
    return Container(
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
