// lib/screens/admin_dashboard.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';

import '../config.dart';
import 'login_screen.dart';

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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

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
