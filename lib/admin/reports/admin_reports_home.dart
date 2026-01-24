import 'package:flutter/material.dart';

class AdminReportsHome extends StatelessWidget {
  const AdminReportsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              context: context,
              title: 'PRIMARY SECTION',
              subtitle: 'Standards 1 to 8',
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(context, '/primaryReportsHome');
              },
            ),
            const SizedBox(height: 20),
            _sectionCard(
              context: context,
              title: 'SECONDARY & HIGHER SECONDARY',
              subtitle: 'Standards 9 to 12',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/secondaryReportsHome');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
