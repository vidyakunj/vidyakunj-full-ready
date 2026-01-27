import 'package:flutter/material.dart';

class SecondaryStudentAttendanceReport extends StatelessWidget {
  const SecondaryStudentAttendanceReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secondary Student Attendance'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _stdTile('9'),
          _stdTile('10'),
          _stdTile('11'),
          _stdTile('12'),
        ],
      ),
    );
  }

  Widget _stdTile(String std) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          'STD $std',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        children: [
          _divisionBlock('A'),
          _divisionBlock('B'),
        ],
      ),
    );
  }

  Widget _divisionBlock(String div) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIV $div',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _studentRow(1, 'Ramesh Patel', Icons.check_circle, Colors.green),
          _studentRow(2, 'Sita Mehta', Icons.cancel, Colors.red),
          _studentRow(3, 'Mohan Das', Icons.access_time, Colors.orange),
        ],
      ),
    );
  }

  Widget _studentRow(
      int roll, String name, IconData icon, Color color) {
    return ListTile(
      dense: true,
      leading: Text(roll.toString()),
      title: Text(name),
      trailing: Icon(icon, color: color),
    );
  }
}
