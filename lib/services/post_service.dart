import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';

class PostService {
  final String baseUrl;

  PostService({required this.baseUrl});

  // Ambil semua postingan
  Future<List<Post>> getPosts(String token) async {
    final uri = Uri.parse('$baseUrl/posts');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      final List data = decoded['data'];
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil postingan: ${response.body}');
    }
  }

  // Ambil detail postingan
  Future<Post> getPost(String token, int postId) async {
    final uri = Uri.parse('$baseUrl/posts/$postId');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal mengambil detail postingan: ${response.body}');
    }
  }

  // Buat postingan baru (support mobile & web)
  Future<Post> createPost({
    required String token,
    required String judul,
    File? imageFile,
    XFile? webImage,
    int? albumId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/posts');
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['judul'] = judul;

      if (albumId != null) request.fields['album_id'] = albumId.toString();

      // Upload image
      if (!kIsWeb && imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      } else if (kIsWeb && webImage != null) {
        final bytes = await webImage.readAsBytes();
        final ext = webImage.name.split('.').last.toLowerCase();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: webImage.name,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal membuat postingan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Gagal membuat postingan: $e');
    }
  }

  // Update postingan
  Future<Post> updatePost({
    required String token,
    required int postId,
    String? judul,
    File? imageFile,
    XFile? webImage,
    int? albumId,
  }) async {
    final uri = Uri.parse('$baseUrl/posts/$postId');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['_method'] = 'PUT';

    if (judul != null) request.fields['judul'] = judul;
    if (albumId != null) request.fields['album_id'] = albumId.toString();

    if (!kIsWeb && imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    } else if (kIsWeb && webImage != null) {
      final bytes = await webImage.readAsBytes();
      final ext = webImage.name.split('.').last.toLowerCase();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: webImage.name,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal mengupdate postingan: ${response.body}');
    }
  }

  // Hapus postingan
  Future<void> deletePost(String token, int postId) async {
    final uri = Uri.parse('$baseUrl/posts/$postId');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus postingan: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserAlbums(String token) async {
    final uri = Uri.parse('$baseUrl/albums');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body) as List;
        return data.map((e) {
          final dynamic rawId = e['id'] ?? e['album_id'] ?? e['id_album'];
          final int parsedId = rawId is int
              ? rawId
              : int.tryParse(rawId?.toString() ?? '') ?? 0;
          final String name = (e['nama_album'] ?? e['name'] ?? e['title'] ?? '').toString();
          return {
            'id': parsedId,
            'name': name,
          };
        }).toList();
      } catch (_) {
        throw Exception('Format album tidak valid: ${response.body}');
      }
    } else {
      throw Exception('Gagal mengambil album: ${response.body}');
    }
  }


}
