import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../config.dart';

class AttendanceScreen extends StatefulWidget {
  final String className;
  const AttendanceScreen({super.key, required this.className});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<List<dynamic>> students = [];
  Map<int, bool> attendance = {};

  Future<void> uploadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final csvData = utf8.decode(result.files.single.bytes!);
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
      setState(() => students = rows.sublist(1)); // Skip header row
    }
  }

  Future<void> sendSMS(String name, String phone) async {
    final res = await http.post(
      Uri.parse('$SERVER_URL/send-sms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': phone,
        'studentName': name,
      }),
    );

    debugPrint("SMS Response: ${res.body}");
  }

  void sendAllAbsentees() {
    for (int i = 0; i < students.length; i++) {
      if (attendance[i] == false) {
        String name = students[i][1].toString();
        String phone = students[i][3].toString();
        sendSMS(name, phone);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Messages sent for all absentees!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance - ${widget.className.toUpperCase()}"),
        actions: [
          IconButton(onPressed: sendAllAbsentees, icon: const Icon(Icons.send))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadCSV,
        child: const Icon(Icons.upload_file),
      ),
      body: students.isEmpty
          ? const Center(child: Text("Upload student CSV to start"))
          : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, i) {
                String name = students[i][1].toString();
                return CheckboxListTile(
                  title: Text(name),
                  subtitle: Text("Phone: ${students[i][3]}"),
                  value: attendance[i] ?? true,
                  onChanged: (v) => setState(() => attendance[i] = v!),
                );
              },
            ),
    );
  }
}
