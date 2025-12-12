import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Please enter both username and password.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await http.post(
        Uri.parse("$SERVER_URL/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username']);
        await prefs.setString('role', data['role']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => errorMessage = "Invalid username or password.");
      }
    } catch (e) {
      setState(() => errorMessage = "Login failed. Please try again.");
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Vidyakunj School", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                if (errorMessage != null)
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Login", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
