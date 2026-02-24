import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

class PrimaryStudentAttendanceReport extends StatefulWidget {
  const PrimaryStudentAttendanceReport({super.key});

  @override
  State<PrimaryStudentAttendanceReport> createState() =>
      _PrimaryStudentAttendanceReportState();
}

class _PrimaryStudentAttendanceReportState
    extends State<PrimaryStudentAttendanceReport> {

  static const Color navy = Color(0xFF0D1B2A);

  DateTime selectedDate = DateTime.now();
  bool isMonthly = false;
  DateTime? fromDate;
  DateTime? toDate;

  final Map<String, List<dynamic>> _cache = {};
  final Set<String> _loading = {};

  String formatName(String fullName) {
    List<String> parts = fullName.trim().split(" ");
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0].toUpperCase();
    if (parts.length == 2) {
      return "${parts[0]} ${parts[1]}".toUpperCase();
    }
    String first = parts.first;
    String middleInitial = parts[1].isNotEmpty ? parts[1][0] : "";
    String last = parts.last;
    return "$first $middleInitial $last".toUpperCase();
  }

  Future<void> loadStudents(String std, String div) async {
    final key = "$std-$div";

    if (isMonthly && (fromDate == null || toDate == null)) return;
    if (_cache.containsKey(key)) return;

    setState(() => _loading.add(key));

    try {
      late Uri url;

      if (isMonthly) {
        final from =
            "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}";

        final to =
            "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";

        url = Uri.parse(
          "$SERVER_URL/attendance/monthly-list?std=$std&div=$div&from=$from&to=$to",
        );
      } else {
        final dateStr =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

        url = Uri.parse(
          "$SERVER_URL/attendance/list?std=$std&div=$div&date=$dateStr",
        );
      }

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cache[key] = data["students"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Load students error: $e");
    }

    setState(() => _loading.remove(key));
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _cache.clear();
        _loading.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text('Primary Student Attendance'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: isMonthly ? null : pickDate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _reportTypeToggle(),
          isMonthly ? _fromToBanner() : _dateBanner(),

          // ✅ STD 1–8
          stdTile('1'),
          stdTile('2'),
          stdTile('3'),
          stdTile('4'),
          stdTile('5'),
          stdTile('6'),
          stdTile('7'),
          stdTile('8'),
        ],
      ),
    );
  }

  Widget _reportTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<bool>(
            title: const Text("Daily"),
            value: false,
            groupValue: isMonthly,
            onChanged: (v) {
              setState(() {
                isMonthly = false;
                _cache.clear();
                _loading.clear();
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: const Text("Monthly"),
            value: true,
            groupValue: isMonthly,
            onChanged: (v) {
              setState(() {
                isMonthly = true;
                _cache.clear();
                _loading.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _dateBanner() {
    final dateStr =
        "${selectedDate.day.toString().padLeft(2, '0')}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.year}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        "Date: $dateStr",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
    );
  }

  Widget _fromToBanner() {
    String format(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: fromDate ?? DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  fromDate = picked;
                  _cache.clear();
                });
              }
            },
            child: Text(fromDate == null ? "From Date" : format(fromDate!)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: toDate ?? DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  toDate = picked;
                  _cache.clear();
                });
              }
            },
            child: Text(toDate == null ? "To Date" : format(toDate!)),
          ),
        ),
      ],
    );
  }

  Widget stdTile(String std) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          'STD $std',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: navy,
          ),
        ),
        children: ['A', 'B', 'C']
            .map((div) => divisionBlock(std, div))
            .toList(),
      ),
    );
  }

  // 🔥 IMPORTANT:
  // Copy the entire divisionBlock, StudentRow,
  // StudentAttendancePopup classes EXACTLY
  // from your Secondary file below this point.
  // No changes required.
}
