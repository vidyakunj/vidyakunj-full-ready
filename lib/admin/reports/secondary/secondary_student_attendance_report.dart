import 'package:flutter/material.dart';

class SecondaryStudentAttendanceReport extends StatelessWidget {
  const SecondaryStudentAttendanceReport({super.key});

  static const Color navyBlue = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secondary Student Attendance'),
        centerTitle: true,
        backgroundColor: navyBlue,
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

  static const Color navyBlue = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          'STD $std',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: navyBlue,
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

/* ================= DIV BLOCK ================= */

class _DivisionBlock extends StatelessWidget {
  final String div;
  const _DivisionBlock({required this.div});

  static const Color navyBlue = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DIV HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: navyBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'DIV $div',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: navyBlue,
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
    return ListTile(
      dense: true,
      leading: Text(
        roll.toString(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      title: Text(name),
      trailing: Icon(icon, color: color, size: 20),
    );
  }
}
