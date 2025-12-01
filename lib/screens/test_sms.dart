import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class TestSMS extends StatefulWidget {
  const TestSMS({super.key});

  @override
  State<TestSMS> createState() => _TestSMSState();
}

class _TestSMSState extends State<TestSMS> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  bool sending = false;
  String result = "";

  Future<void> sendTestSMS() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => result = "Name or Phone missing!");
      return;
    }

    setState(() => sending = true);

    final res = await http.post(
      Uri.parse('$SERVER_URL/send-sms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "mobile": phone,
        "studentName": name,
      }),
    );

    setState(() {
      sending = false;
      result = "Response: ${res.body}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TEST SMS")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Student Name",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: "Parent Phone",
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: sending ? null : sendTestSMS,
              child: Text(sending ? "Sending..." : "SEND TEST SMS"),
            ),
            const SizedBox(height: 30),
            Text(
              result,
              style: const TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
