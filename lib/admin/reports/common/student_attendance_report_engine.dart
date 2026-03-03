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
            "$SERVER_URL/attendance/monthly-list?std=$std&div=$div&from=$from&to=$to");
      } else {
        final dateStr =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

        url = Uri.parse(
            "$SERVER_URL/attendance/list?std=$std&div=$div&date=$dateStr");
      }

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cache[key] = data["students"] ?? [];
        });
      }
    } catch (_) {}

    setState(() => _loading.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _reportToggle(),
          isMonthly ? _fromToBanner() : _dateBanner(),
          ...widget.stdList.map((std) => _stdTile(std)),
        ],
      ),
    );
  }

  Widget _reportToggle() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<bool>(
            title: const Text("Daily"),
            value: false,
            groupValue: isMonthly,
            onChanged: (_) {
              setState(() {
                isMonthly = false;
                _cache.clear();
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: const Text("Monthly"),
            value: true,
            groupValue: isMonthly,
            onChanged: (_) {
              setState(() {
                isMonthly = true;
                _cache.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _dateBanner() {
    final d =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";
    return Text("Date: $d",
        style: const TextStyle(fontWeight: FontWeight.bold));
  }

  Widget _fromToBanner() {
    String f(DateTime d) => "${d.day}-${d.month}-${d.year}";
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: fromDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now());
              if (picked != null) {
                setState(() {
                  fromDate = picked;
                  _cache.clear();
                });
              }
            },
            child: Text(fromDate == null ? "From Date" : f(fromDate!)),
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
                  lastDate: DateTime.now());
              if (picked != null) {
                setState(() {
                  toDate = picked;
                  _cache.clear();
                });
              }
            },
            child: Text(toDate == null ? "To Date" : f(toDate!)),
          ),
        ),
      ],
    );
  }

  Widget _stdTile(String std) {
    return Card(
      child: ExpansionTile(
        title: Text("STD $std",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: navy)),
        children: ["A", "B", "C"]
            .map((div) => _divisionBlock(std, div))
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
              child: Text("DIV $div",
                  style: const TextStyle(fontWeight: FontWeight.bold))),

          const SizedBox(height: 6),

          if (_loading.contains(key))
            const CircularProgressIndicator(strokeWidth: 2),

          if (students != null && students.isNotEmpty)
            ...students.map((s) {
              final percent =
                  double.tryParse(s["percentage"]?.toString() ?? "0") ?? 0;
              final low = isMonthly && percent < 75;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: low
                    ? BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6))
                    : null,
                child: Row(
                  children: [
                    SizedBox(
                        width: 30,
                        child: Text(s["rollNo"].toString())),
                    Expanded(
                      child: Text(s["name"]),
                    ),
                    if (!isMonthly)
                      _statusIcon(s["status"] ?? ""),
                    if (isMonthly)
                      Text("${percent.toStringAsFixed(1)}%"),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case "present":
        return const Icon(Icons.check_circle, color: Colors.green);
      case "absent":
        return const Icon(Icons.cancel, color: Colors.red);
      case "late":
        return const Icon(Icons.access_time, color: Colors.orange);
      default:
        return const SizedBox();
    }
  }
}
