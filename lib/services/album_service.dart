import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fe_snappix/models/album_model.dart'; 

class AlbumService {
  static const String baseUrl = "http://127.0.0.1:8000/api/albums"; 
  final String token; 

  AlbumService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Album>> getAlbums() async {
    final response = await http.get(Uri.parse(baseUrl), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Album.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load albums');
    }
  }

  Future<Album> createAlbum(Album album) async {
    final response = await http.post(
      Uri.parse(baseUrl),
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
    final response = await http.get(Uri.parse('$baseUrl/$id'), headers: _headers);

    if (response.statusCode == 200) {
      return Album.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get album detail');
    }
  }

  Future<void> deleteAlbum(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: _headers);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete album');
    }
  }
}