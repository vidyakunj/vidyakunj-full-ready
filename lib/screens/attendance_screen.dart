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

  // Load CSV
  Future<void> uploadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final csvData = utf8.decode(result.files.single.bytes!);
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

      setState(() {
  students = rows.sublist(1)
      .where((row) => row.isNotEmpty && row[1].toString().trim().isNotEmpty)
      .toList();
});

    }
  }

  // Send SMS using 1-variable DLT template
  Future<void> sendSMS(String studentName, String phone) async {
    final res = await http.post(
      Uri.parse('$SERVER_URL/send-sms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "mobile": phone.trim(),
        "studentName": studentName.trim(),
      }),
    );

    debugPrint("SMS Response: ${res.body}");
  }

  void sendAllAbsentees() {
    for (int i = 0; i < students.length; i++) {
      bool isPresent = attendance[i] ?? true;

      if (!isPresent) {
        // CSV COLUMNS → [0=roll, 1=name, 2=division, 3=parent_phone, ...]
        String name = students[i][1].toString();   // student name
        String phone = students[i][3].toString();  // parent_phone

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
          IconButton(
            onPressed: sendAllAbsentees,
            icon: const Icon(Icons.send, size: 28),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: uploadCSV,
        child: const Icon(Icons.upload_file),
      ),

      body: students.isEmpty
          ? const Center(child: Text("Upload student CSV to start"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (context, i) {
                String name = students[i][1].toString();
                String phone = students[i][3].toString();

                return Card(
                  elevation: 1,
                  child: CheckboxListTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text("Phone: $phone"),
                    value: attendance[i] ?? true,
                    onChanged: (v) => setState(() => attendance[i] = v!),
                  ),
                );
              },
            ),
    );
  }
}

