import 'package:flutter/material.dart';

class SecondaryReportsHome extends StatelessWidget {
  const SecondaryReportsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secondary & Higher Secondary'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Secondary Reports Home',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
