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

  // ================== POST ==================

  // Ambil semua postingan
  Future<List<Post>> getPosts(String token) async {
    final uri = Uri.parse('$baseUrl/posts');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List items = const [];
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final dynamic data = decoded['data'];
        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          items = data['data'];
        }
      }
      return items.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
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
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
        return Post.fromJson(decoded['data']);
      }
      if (decoded is Map<String, dynamic>) {
        return Post.fromJson(decoded);
      }
      throw Exception('Format response tidak dikenali untuk detail post');
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
        request.files
            .add(await http.MultipartFile.fromPath('image', imageFile.path));
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal membuat postingan: ${response.body}');
      }
    } catch (e) {
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
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
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

  // Ambil album user
  Future<List<Map<String, dynamic>>> getUserAlbums(String token) async {
    final uri = Uri.parse('$baseUrl/albums');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) {
        final dynamic rawId = e['id'] ?? e['album_id'] ?? e['id_album'];
        final int parsedId =
            rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
        final String name =
            (e['nama_album'] ?? e['name'] ?? e['title'] ?? '').toString();
        return {
          'id': parsedId,
          'name': name,
        };
      }).toList();
    } else {
      throw Exception('Gagal mengambil album: ${response.body}');
    }
  }

  // Ambil postingan berdasarkan album
  Future<List<Post>> getPostsByAlbum(String token, int albumId) async {
    final uri = Uri.parse('$baseUrl/albums/$albumId/posts');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      final List data = decoded['data'] ?? [];
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil postingan album: ${response.body}');
    }
  }


  // Ambil postingan milik user tertentu
  Future<List<Post>> getPostsByUser(String token, int userId) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    Future<List<Post>> tryParse(http.Response response) async {
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List items = const [];
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map<String, dynamic>) {
          final dynamic data = decoded['data'];
          if (data is List) {
            items = data;
          } else if (data is Map<String, dynamic> && data['data'] is List) {
            items = data['data'];
          } else if (decoded['posts'] is List) {
            items = decoded['posts'];
          }
        }
        return items.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Gagal mengambil postingan user: ${response.body}');
    }

    final candidates = <Uri>[
      Uri.parse('$baseUrl/users/$userId/posts'),
      Uri.parse('$baseUrl/user/$userId/posts'),
      Uri.parse('$baseUrl/social/users/$userId/posts'),
    ];

    for (final uri in candidates) {
      try {
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200) {
          return await tryParse(res);
        }
      } catch (_) {}
    }

    // Jika tidak ada endpoint khusus, ambil semua postingan lalu filter di client
    final allPosts = await getPosts(token);
    return allPosts.where((p) => p.userId == userId).toList();
  }

  // ================== LIKE ==================

  Future<Map<String, dynamic>> likePost(String token, int postId) async {
    final uri = Uri.parse('$baseUrl/social/posts/$postId/like');
    final response = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal like post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> unlikePost(String token, int postId) async {
    final uri = Uri.parse('$baseUrl/social/posts/$postId/unlike');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal unlike post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkLikeStatus(String token, int postId) async {
    final uri = Uri.parse('$baseUrl/social/posts/$postId/like-status');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal cek status like: ${response.body}');
    }
  }

  // ================== COMMENT ==================

  Future<Map<String, dynamic>> getComments(
    String token,
    int postId, {
    int page = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/social/posts/$postId/comments?page=$page');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil komentar: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> addComment(
    String token,
    int postId,
    String isiKomentar,
  ) async {
    final uri = Uri.parse('$baseUrl/social/posts/$postId/comments');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'isi_komentar': isiKomentar}),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal menambahkan komentar: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateComment(
    String token,
    int commentId,
    String isiKomentar,
  ) async {
    final uri = Uri.parse('$baseUrl/social/comments/$commentId');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'isi_komentar': isiKomentar}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengupdate komentar: ${response.body}');
    }
  }

  Future<void> deleteComment(String token, int commentId) async {
    final uri = Uri.parse('$baseUrl/social/comments/$commentId');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus komentar: ${response.body}');
    }
  }

// ================== REPORT ==================
  Future<Map<String, dynamic>> reportPost(
    String token,
    int postId, {
    String alasan = "Konten tidak pantas",
  }) async {
    final uri = Uri.parse('$baseUrl/social/posts/$postId/report');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({"alasan": alasan}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal melaporkan postingan: ${response.body}');
    }
  }

  Future<void> reportComment(String token, int commentId,
      {required String alasan}) async {
    final uri = Uri.parse('$baseUrl/social/comments/$commentId/report');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'alasan': alasan}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal melaporkan komentar: ${response.body}');
    }
  }
}
