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
  bool isRange = false;
  bool loading = false;

  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  Map<String, dynamic>? schoolTotal;
  List<dynamic> primary = [];
  List<dynamic> secondary = [];

  /* ================= LOAD SUMMARY ================= */
  Future<void> loadSummary() async {
    setState(() => loading = true);

    final from =
        "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
    final to =
        "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";

    final url = isRange
        ? "$SERVER_URL/attendance/summary-school-range?from=$from&to=$to"
        : "$SERVER_URL/attendance/summary-school?date=$from";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      setState(() {
        schoolTotal = data["schoolTotal"];
        primary = data["primary"] ?? [];
        secondary = data["secondary"] ?? [];
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }

    setState(() => loading = false);
  }

  /* ================= UI ================= */
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modeSelector(),
            const SizedBox(height: 10),
            _dateSelector(),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: loadSummary, child: const Text("Load Summary")),
            const SizedBox(height: 20),

            if (loading) const Center(child: CircularProgressIndicator()),

            if (!loading && schoolTotal != null) ...[
              _schoolTotalCard(),
              const SizedBox(height: 20),
              _section("Primary (STD 1–8)", primary),
              const SizedBox(height: 20),
              _section("Secondary (STD 9–12)", secondary),
            ],
          ],
        ),
      ),
    );
  }

  /* ================= COMPONENTS ================= */

  Widget _modeSelector() {
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

  Widget _dateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: fromDate,
              firstDate: DateTime(2023),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => fromDate = d);
          },
          child: Text("From: ${fromDate.toIso8601String().split('T')[0]}"),
        ),
        if (isRange)
          ElevatedButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: toDate,
                firstDate: fromDate,
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => toDate = d);
            },
            child: Text("To: ${toDate.toIso8601String().split('T')[0]}"),
          ),
      ],
    );
  }

  Widget _schoolTotalCard() {
    return Card(
      color: Colors.green[100],
      child: ListTile(
        title: const Text("School Total",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Total: ${schoolTotal!["total"]} | "
          "Present: ${schoolTotal!["present"]} | "
          "Absent: ${schoolTotal!["absent"]} | "
          "Late: ${schoolTotal!["late"]} | "
          "%: ${schoolTotal!["attendancePercent"] ?? 0}",
        ),
      ),
    );
  }

  Widget _section(String title, List data) {
    if (data.isEmpty) return const Text("No data available");

    data.sort((a, b) =>
        int.parse(a["std"]).compareTo(int.parse(b["std"])));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
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
            rows: data.map<DataRow>((r) {
              return DataRow(cells: [
                DataCell(Text(r["std"].toString())),
                DataCell(Text(r["div"].toString())),
                DataCell(Text(r["totalStudents"]?.toString() ?? r["total"].toString())),
                DataCell(Text(r["present"].toString())),
                DataCell(Text(r["absent"].toString())),
                DataCell(Text(r["late"].toString())),
                DataCell(Text(r["attendancePercent"].toString())),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
