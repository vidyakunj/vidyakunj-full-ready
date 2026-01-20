import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool loading = false;
  bool isRange = false;

  DateTime singleDate = DateTime.now();
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  Map<String, dynamic>? schoolTotal;
  List<Map<String, dynamic>> primary = [];
  List<Map<String, dynamic>> secondary = [];

  /* ==============================
     LOAD SUMMARY
     ============================== */
  Future<void> loadSummary() async {
    setState(() {
      loading = true;
      primary.clear();
      secondary.clear();
      schoolTotal = null;
    });

    final String url = isRange
        ? "$SERVER_URL/attendance/summary-range"
            "?from=${_fmt(fromDate)}&to=${_fmt(toDate)}"
        : "$SERVER_URL/attendance/summary"
            "?date=${_fmt(singleDate)}";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        _show("Failed to load summary (${res.statusCode})");
        return;
      }

      final data = jsonDecode(res.body);

      setState(() {
        schoolTotal = data["schoolTotal"];

        primary = List<Map<String, dynamic>>.from(data["primary"] ?? []);
        secondary = List<Map<String, dynamic>>.from(data["secondary"] ?? []);

        _sortData(primary);
        _sortData(secondary);
      });
    } catch (e) {
      _show("Error loading summary");
    } finally {
      setState(() => loading = false);
    }
  }

  /* ==============================
     SORT STD & DIV
     ============================== */
  void _sortData(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final int stdA = int.parse(a["std"].toString());
      final int stdB = int.parse(b["std"].toString());
      if (stdA != stdB) return stdA.compareTo(stdB);
      return a["div"].toString().compareTo(b["div"].toString());
    });
  }

  /* ==============================
     DATE FORMAT
     ============================== */
  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ==============================
     UI
     ============================== */
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF110E38);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Admin Attendance Summary"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modeSwitch(),
            const SizedBox(height: 10),
            _dateSelectors(),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: loadSummary, child: const Text("Load Summary")),
            const SizedBox(height: 20),

            if (loading) const Center(child: CircularProgressIndicator()),

            if (!loading && schoolTotal != null) _schoolTotal(),

            if (primary.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle("Primary (STD 1–8)"),
              _summaryTable(primary),
            ],

            if (secondary.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle("Secondary (STD 9–12)"),
              _summaryTable(secondary),
            ],
          ],
        ),
      ),
    );
  }

  /* ==============================
     WIDGETS
     ============================== */
  Widget _modeSwitch() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text("Single Day"),
          selected: !isRange,
          onSelected: (_) => setState(() => isRange = false),
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text("Date Range"),
          selected: isRange,
          onSelected: (_) => setState(() => isRange = true),
        ),
      ],
    );
  }

  Widget _dateSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRange)
          _dateButton("Select Date", singleDate, (d) => singleDate = d),
        if (isRange) ...[
          _dateButton("From", fromDate, (d) => fromDate = d),
          _dateButton("To", toDate, (d) => toDate = d),
        ],
      ],
    );
  }

  Widget _dateButton(String label, DateTime date, Function(DateTime) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
          );
          if (d != null) setState(() => onPick(d));
        },
        child: Text("$label: ${_fmt(date)}"),
      ),
    );
  }

  Widget _schoolTotal() {
    final t = schoolTotal!;
    final percent = t["total"] == 0
        ? 0
        : ((t["present"] / t["total"]) * 100).toStringAsFixed(2);

    return Card(
      color: Colors.green[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "School Total\n"
          "Total: ${t["total"]} | Present: ${t["present"]} | "
          "Absent: ${t["absent"]} | Late: ${t["late"]} | %: $percent",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _summaryTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("STD")),
          DataColumn(label: Text("DIV")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Present")),
          DataColumn(label: Text("Absent")),
          DataColumn(label: Text("Late")),
          DataColumn(label: Text("%")),
        ],
        rows: data.map((r) {
          final percent = r["total"] == 0
              ? "0.00"
              : ((r["present"] / r["total"]) * 100).toStringAsFixed(2);

          return DataRow(cells: [
            DataCell(Text(r["std"].toString())),
            DataCell(Text(r["div"].toString())),
            DataCell(Text(r["total"].toString())),
            DataCell(Text(r["present"].toString())),
            DataCell(Text(r["absent"].toString())),
            DataCell(Text(r["late"].toString())),
            DataCell(Text(percent)),
          ]);
        }).toList(),
      ),
    );
  }
}
