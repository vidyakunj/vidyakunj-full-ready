import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

class StudentAttendanceReportEngine extends StatefulWidget {
  final String title;
  final List<String> stdList;

  const StudentAttendanceReportEngine({
    super.key,
    required this.title,
    required this.stdList,
  });

  @override
  State<StudentAttendanceReportEngine> createState() =>
      _StudentAttendanceReportEngineState();
}

class _StudentAttendanceReportEngineState
    extends State<StudentAttendanceReportEngine> {

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
    if (parts.length == 2) return "${parts[0]} ${parts[1]}".toUpperCase();
    return "${parts.first} ${parts[1][0]} ${parts.last}".toUpperCase();
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

    if (picked != null) {
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
        title: Text(widget.title),
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
          ...widget.stdList.map((std) => stdTile(std)),
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
            color: navy,
          ),
        ),
        children: ['A', 'B', 'C']
            .map<Widget>((div) => _divisionBlock(std, div))
            .toList(),
      ),
    );
  }

  Widget _divisionBlock(String std, String div) {
    final key = "$std-$div";
    final students = _cache[key];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => loadStudents(std, div),
            child: Text(
              "DIV $div",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (_loading.contains(key))
            const CircularProgressIndicator(),
          if (students != null)
            ...students.map<Widget>(
              (s) => ListTile(
                title: Text(s["name"]),
                subtitle: isMonthly
                    ? Text("Attendance: ${s["percentage"] ?? "0"}%")
                    : Text("Status: ${s["status"]}"),
              ),
            ),
        ],
      ),
    );
  }
}
