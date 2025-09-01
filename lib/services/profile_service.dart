import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import 'package:fe_snappix/config/api_config.dart';

class ProfileService {
  final String baseUrl;

  ProfileService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Ambil profil user
  Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse('$baseUrl/user/profile');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body['user'] ?? {};
    } else {
      throw Exception('Gagal load profil: ${res.body}');
    }
  }

  /// Ambil postingan user
  Future<List<Post>> getMyPosts(String token) async {
    final url = Uri.parse('$baseUrl/user/my-posts');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final data = body['data'] as List<dynamic>? ?? [];
      return data.map((e) => Post.fromJson(e)).toList();
    } else {
      throw Exception('Gagal load postingan: ${res.body}');
    }
  }

  /// Ambil album user
  Future<List<dynamic>> getMyAlbums(String token) async {
    final url = Uri.parse('$baseUrl/user/my-albums');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body['data'] ?? [];
    } else {
      throw Exception('Gagal load album: ${res.body}');
    }
  }

  /// Update profil
  Future<void> updateProfile(String token,
      {String? username, String? name, String? email, String? bio}) async {
    final url = Uri.parse('$baseUrl/user/profile');

    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (bio != null) body['bio'] = bio;

    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal update profil: ${res.body}');
    }
  }

  /// Ganti password
  Future<void> changePassword(
      String token, String currentPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/user/change-password');

    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal ganti password: ${res.body}');
    }
  }

  /// Logout (hapus token dari SharedPreferences)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
