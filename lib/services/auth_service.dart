import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000/api"; // ganti sesuai API Laravel

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    } else if (response.statusCode == 401) {
      // khusus salah email/password
      throw Exception(body["message"] ?? "Email atau password salah");
    } else {
      throw Exception(body["message"] ?? "Terjadi kesalahan (${response.statusCode})");
    }
  }

  /// Register
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse("$baseUrl/register");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    } else {
      throw Exception(body["message"] ?? "Terjadi kesalahan saat register");
    }
  }

  /// Logout (hapus token lokal)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
