import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'new_attendance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool isAdmin = false;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  // =====================================================
  // NEW LOGIN FUNCTION WITH BACKEND API + AUTO SESSION
  // =====================================================
  Future<void> _onLoginPressed() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnack("Please enter username & password");
      return;
    }

    final url = Uri.parse("$SERVER_URL/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      // Save session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("loggedIn", true);
      await prefs.setString("username", data["username"]);
      await prefs.setString("role", data["role"]);

      // Redirect based on role
      if (data["role"] == "teacher") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewAttendanceScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("Admin Dashboard")),
              body: const Center(child: Text("Admin panel coming soon")),
            ),
          ),
        );
      }
    } else {
      _showSnack("Invalid username or password");
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff003366);

    return Scaffold(
      backgroundColor: const Color(0xffeef3ff),
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 4,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 10),
            Image.asset("assets/logo.png", height: 40),
            const SizedBox(width: 12),
            const Text(
              "VIDYAKUNJ SCHOOL",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),

      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Login to continue",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text("Teacher"),
                              selected: !isAdmin,
                              onSelected: (v) =>
                                  setState(() => isAdmin = false),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text("Admin"),
                              selected: isAdmin,
                              onSelected: (v) =>
                                  setState(() => isAdmin = true),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        TextField(
                          controller: _userCtrl,
                          decoration: InputDecoration(
                            labelText: "Username / Mobile",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onSubmitted: (_) => _onLoginPressed(),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _onLoginPressed,
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () =>
                              _showSnack("Please contact school admin."),
                          child: const Text("Forgot Password?"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
