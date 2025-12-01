import 'package:flutter/material.dart';
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyakunj',
      home: Scaffold(
        appBar: AppBar(title: const Text('Vidyakunj')),
        body: const Center(child: Text('Replace this with your lib/ code')),
      ),
    );
  }
}
