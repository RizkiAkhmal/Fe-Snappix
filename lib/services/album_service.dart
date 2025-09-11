import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fe_snappix/models/album_model.dart';
import 'package:fe_snappix/config/api_config.dart';

class AlbumService {
  final String token;

  AlbumService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  String get _albumsUrl => "${ApiConfig.baseUrl}/albums";

  Future<List<Album>> getAlbums() async {
    final response = await http.get(Uri.parse(_albumsUrl), headers: _headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
      return data.map((json) => Album.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load albums');
    }
  }

  Future<Album> createAlbum(Album album) async {
    final response = await http.post(
      Uri.parse(_albumsUrl),
      headers: _headers,
      body: json.encode(album.toJson()),
    );

    if (response.statusCode == 201) {
      return Album.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create album');
    }
  }

  Future<Album> getAlbumDetail(int id) async {
    final response = await http.get(Uri.parse('$_albumsUrl/$id'), headers: _headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final Map<String, dynamic> obj = decoded is Map<String, dynamic>
          ? (decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded)
          : <String, dynamic>{};
      return Album.fromJson(obj);
    } else {
      throw Exception('Failed to get album detail');
    }
  }

 Future<void> deleteAlbum(int id) async {
  final response = await http.delete(Uri.parse('$_albumsUrl/$id'), headers: _headers);

  if (response.statusCode == 200 || response.statusCode == 204) {
    // sukses
    return;
  } else {
    final msg = response.body.isNotEmpty ? response.body : 'Unknown error';
    throw Exception('Failed to delete album: $msg');
  }
}

  Future<List<Album>> getAlbumsByUser(int userId) async {
    final response = await http.get(
      Uri.parse('$_albumsUrl/user/$userId'), 
      headers: _headers
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
      return data.map((json) => Album.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load user albums');
    }
  }
}