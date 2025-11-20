import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsService {
  static const String apiUrl =
      "https://vidyakunj-sms-server.onrender.com/send-sms";

  static Future<bool> sendSms(String mobile, String studentName) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobile": mobile,
          "studentName": studentName,   // 👈 CORRECT PARAMETER
        }),
      );

      print("SMS API Response: ${response.body}");

      final data = jsonDecode(response.body);

      return data["success"] == true;
    } catch (e) {
      print("SMS ERROR: $e");
      return false;
    }
  }
}
// (Optional placeholder - main SMS handled in AttendanceScreen)

