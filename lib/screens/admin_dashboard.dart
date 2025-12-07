import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../config.dart';

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
      });
    }
  }

  // CSV UPLOAD button
  Future<void> uploadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    String csvContent = utf8.decode(result.files.first.bytes!);

    List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

    print("Uploaded CSV rows = ${rows.length}");
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Dashboard"),
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
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: uploadCSV,
              icon: const Icon(Icons.upload),
              label: const Text("Upload CSV"),
            )
          ],
        ),
      ),
    );
  }

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
