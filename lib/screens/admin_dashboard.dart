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
  DateTime selectedDate = DateTime.now();
  List<dynamic> summary = [];

  final List<String> stdOptions = List.generate(12, (i) => "${i + 1}");

  Future<void> loadDivisions() async {
    if (selectedStd == null) return;

    final uri = Uri.parse("$SERVER_URL/divisions?std=$selectedStd");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        divisions = (data["divisions"] ?? []).map<String>((e) => e.toString()).toList();
      });
    }
  }

  Future<void> loadStudents() async {
    if (selectedStd == null || selectedDiv == null) return;

    final uri = Uri.parse("$SERVER_URL/students?std=$selectedStd&div=$selectedDiv");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data["students"] ?? [];

      setState(() {
        totalStudents = list.length;
      });
    }
  }

  Future<void> uploadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    String csvContent = utf8.decode(result.files.first.bytes!);
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

    List<Map<String, dynamic>> students = [];

    for (int i = 1; i < rows.length; i++) {
      var row = rows[i];
      students.add({
        "std": row[0].toString(),
        "div": row[1].toString(),
        "roll": int.tryParse(row[2].toString()) ?? 0,
        "name": row[3].toString(),
        "mobile": row[4].toString(),
      });
    }

    final res = await http.post(
      Uri.parse('$SERVER_URL/students/bulk'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"students": students}),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Students uploaded successfully")),
      );
      loadStudents(); // Refresh count
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${res.body}")),
      );
    }
  }

  Future<void> loadAttendanceSummary() async {
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse("$SERVER_URL/attendance-summary?date=$dateStr");

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      setState(() {
        summary = jsonDecode(res.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedStd,
                      hint: const Text("Select STD"),
                      items: stdOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedStd = v;
                          selectedDiv = null;
                        });
                        loadDivisions();
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedDiv,
                      hint: const Text("Select DIV"),
                      items: divisions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        setState(() => selectedDiv = v);
                        loadStudents();
                      },
                    ),
                  ),
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
              ),
              const SizedBox(height: 30),
              Text("📅 Daily Attendance Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() => selectedDate = picked);
                        loadAttendanceSummary();
                      }
                    },
                    child: const Text("Select Date"),
                  ),
                  const SizedBox(width: 12),
                  Text("${selectedDate.day}-${selectedDate.month}-${selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              summary.isEmpty
                  ? const Text("No summary available.")
                  : Column(
                      children: summary.map((e) {
                        return Card(
                          child: ListTile(
                            title: Text("STD: ${e['std']}  |  DIV: ${e['div']}"),
                            subtitle: Text("Total: ${e['total']}  |  Present: ${e['present']}  |  Absent: ${e['absent']}"),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
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
