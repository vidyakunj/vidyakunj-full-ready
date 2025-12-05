import 'package:flutter/material.dart';
import 'new_attendance_screen.dart'; // Make sure path is correct

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool isAdmin = false; // false = Teacher, true = Admin

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
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fade);

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _onLoginPressed() {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showSnack("Please enter username & password");
      return;
    }

    // STEP 1: NO BACKEND YET
    // Navigate directly to NEW attendance screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NewAttendanceScreen()),
    );
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
            Image.asset("assets/logo.png", height: 38),
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
                      borderRadius: BorderRadius.circular(14)),
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

                        // ─────────── Teacher / Admin Toggle ───────────
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

                        // ─────────── Username ───────────
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

                        // ─────────── Password ───────────
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

                        // ─────────── LOGIN BUTTON ───────────
                        SizedBox(
                          width: double.infinity,
