import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? selectedStd;
  String? selectedDiv;
  List<String> divisions = [];

  int totalStudents = 0;
  int presentStudents = 0;
  int absentStudents = 0;

  final List<String> stdOptions = List.generate(12, (i) => "${i + 1}");

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final uri = Uri.parse("$SERVER_URL/divisions?std=$selectedStd");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        divisions =
            (data["divisions"] ?? []).map<String>((e) => e.toString()).toList();
      });
    }
  }

  Future<void> loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    final uri = Uri.parse(
        "$SERVER_URL/students?std=$selectedStd&div=$selectedDiv");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final list = data["students"] ?? [];

      setState(() {
        totalStudents = list.length;
        presentStudents = list.where((s) => s["isPresent"] == true).length;
        absentStudents = list.where((s) => s["isPresent"] == false).length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedStd,
                    hint: const Text("Select STD"),
                    items: stdOptions
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedStd = v);
                      loadDivisions();
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedDiv,
                    hint: const Text("Select DIV"),
                    items: divisions
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedDiv = v);
                      loadStudents();
                    },
                  ),
                )
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _box("Total", totalStudents, Colors.blue),
                _box("Present", presentStudents, Colors.green),
                _box("Absent", absentStudents, Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }
const SizedBox(height: 30),

Expanded(
  child: FutureBuilder(
    future: selectedStd != null && selectedDiv != null
        ? http.get(Uri.parse("$SERVER_URL/students?std=$selectedStd&div=$selectedDiv"))
        : null,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snap.hasData) {
        return const Center(child: Text("Select class"));
      }

      final data = jsonDecode(snap.data!.body);
      final list = data["students"] ?? [];

      if (list.isEmpty) {
        return const Center(child: Text("No students found"));
      }

      return ListView(
        children: list.map<Widget>((s) {
          return ListTile(
            leading: Text(s["roll"].toString()),
            title: Text(s["name"]),
            subtitle: Text(s["mobile"]),
          );
        }).toList(),
      );
    },
  ),
),

  Widget _box(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      width: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            "$value",
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
