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
      loadStudents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${res.body}")),
      );
    }
  }

  Future<void> loadAttendanceSummary() async {
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse("$SERVER_URL/full-attendance-summary?date=$dateStr");

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

    int total = 0;
    int present = 0;
    int absent = 0;

    for (var s in summary) {
      total += (s['total'] ?? 0).toInt();
      present += (s['present'] ?? 0).toInt();
      absent += (s['absent'] ?? 0).toInt();
    }

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
                child: const Text("Select Date for Summary"),
              ),
              const SizedBox(height: 12),
              summary.isEmpty
                  ? const Text("No summary available.")
                  : Column(
                      children: [
                        ...summary.map((e) {
                          return Card(
                            child: ListTile(
                              title: Text("STD: ${e['std']}  |  DIV: ${e['div']}"),
                              subtitle: Text("Total: ${e['total']}  |  Present: ${e['present']}  |  Absent: ${e['absent']}")
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 15),
                        Card(
                          color: Colors.yellow[100],
                          child: ListTile(
                            title: const Text(
                              "All Classes Summary",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Total: $total  |  Present: $present  |  Absent: $absent"),
                          ),
                        )
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 
