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
      // Handle both direct user object and wrapped user object
      if (body is Map<String, dynamic>) {
        return body['user'] ?? body; // Try 'user' key first, then direct body
      }
      return {};
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

  /// Ambil user by username (untuk melengkapi avatar jika perlu)
  Future<Map<String, dynamic>?> getUserByUsername(String token, String username) async {
    final url = Uri.parse('$baseUrl/user/username/$username');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body is Map<String, dynamic>) return body;
      return null;
    }
    return null;
  }

  /// Cari users berdasarkan query (nama/username/email)
  Future<List<Map<String, dynamic>>> searchUsers(String token, String query) async {
    Future<List<Map<String, dynamic>>> tryParse(http.Response res) async {
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body is List) return body.cast<Map<String, dynamic>>();
        if (body is Map<String, dynamic>) {
          // Bentuk umum: { data: [...] }
          final data = body['data'];
          if (data is List) return data.cast<Map<String, dynamic>>();
          // Paginasi Laravel: { data: { data: [...] } }
          if (data is Map<String, dynamic> && data['data'] is List) {
            return (data['data'] as List).cast<Map<String, dynamic>>();
          }
          // Alternatif: { users: [...] } atau { results: [...] }
          if (body['users'] is List) return (body['users'] as List).cast<Map<String, dynamic>>();
          if (body['results'] is List) return (body['results'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      }
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    List<Map<String, dynamic>> filterLocal(List<Map<String, dynamic>> items) {
      final q = query.toLowerCase();
      return items.where((u) {
        final name = (u['name'] ?? u['nama'] ?? '').toString().toLowerCase();
        final username = (u['username'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || username.contains(q) || email.contains(q);
      }).toList();
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final candidates = <Uri>[
      Uri.parse('$baseUrl/users/search?q=${Uri.encodeQueryComponent(query)}'),
      Uri.parse('$baseUrl/users?search=${Uri.encodeQueryComponent(query)}'),
      Uri.parse('$baseUrl/user/search?q=${Uri.encodeQueryComponent(query)}'),
      // Beberapa API memakai param 'q' di /users
      Uri.parse('$baseUrl/users?q=${Uri.encodeQueryComponent(query)}'),
      // Ada juga yang pakai name langsung
      Uri.parse('$baseUrl/users?name=${Uri.encodeQueryComponent(query)}'),
      Uri.parse('$baseUrl/users?username=${Uri.encodeQueryComponent(query)}'),
    ];

    for (final uri in candidates) {
      try {
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200) {
          final parsed = await tryParse(res);
          if (parsed.isNotEmpty) return filterLocal(parsed);
        }
      } catch (_) {}
    }

    // Fallback: ambil semua users dan filter lokal jika endpoint tidak ada
    for (final path in ['users', 'user']) {
      try {
        final allUsersUri = Uri.parse('$baseUrl/$path');
        final res = await http.get(allUsersUri, headers: headers);
        if (res.statusCode == 200) {
          final parsed = await tryParse(res);
          final filtered = filterLocal(parsed);
          if (filtered.isNotEmpty) return filtered;
        }
      } catch (_) {}
    }

    // Final fallback: exact match by username, lalu bungkus sebagai list
    try {
      final exactUri = Uri.parse('$baseUrl/user/username/${Uri.encodeComponent(query)}');
      final res = await http.get(exactUri, headers: headers);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body is Map<String, dynamic>) return [body];
      }
    } catch (_) {}

    return <Map<String, dynamic>>[];
  }
}
