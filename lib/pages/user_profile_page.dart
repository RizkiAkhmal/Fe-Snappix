import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:fe_snappix/services/profile_service.dart';
import 'package:fe_snappix/services/post_service.dart';
import 'package:fe_snappix/models/post_model.dart';
import 'package:fe_snappix/models/album_model.dart';
import 'package:fe_snappix/pages/album_detail_page.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? initialUser;

  const UserProfilePage({super.key, required this.userId, this.initialUser});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _loading = true;
  List<Post> _posts = [];
  List<Album> _albums = [];
  late TabController _tabController;

  late final ProfileService _profileService;
  late final PostService _postService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profileService = ProfileService(baseUrl: ApiConfig.baseUrl);
    _postService = PostService(baseUrl: ApiConfig.baseUrl);
    _user = widget.initialUser;
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Coba isi profil user jika belum lengkap
      Map<String, dynamic>? user = _user;
      if (user == null || (user['avatar'] == null && user['name'] == null)) {
        // Tidak ada endpoint user detail spesifik di service; jika backend menyediakan, tambahkan di ProfileService.
        // Sebagai fallback, jika kita punya username, coba ambil via username.
        final username = user?['username']?.toString();
        if (username != null && username.isNotEmpty) {
          user = await _profileService.getUserByUsername(token, username);
        }
      }
      _user = user ?? _user;

      // Ambil postingan user terlebih dahulu
      final posts = await _postService.getPostsByUser(token, widget.userId);
      
      // Try to get albums from different sources
      List<Album> albums = [];
      
      try {
        // Method 1: Try getUserAlbums from PostService
        final albumMaps = await _postService.getUserAlbums(token);
        print('getUserAlbums returned: $albumMaps');
        albums = albumMaps.map((map) => Album(
          id: map['id'],
          namaAlbum: map['name'] ?? '',
          deskripsi: '',
          coverUrl: null,
        )).toList();
      } catch (e) {
        print('getUserAlbums failed: $e');
        
        try {
          // Method 2: Try getMyAlbums from ProfileService
          final albumData = await _profileService.getMyAlbums(token);
          print('getMyAlbums returned: $albumData');
          albums = albumData.map((item) {
            if (item is Map<String, dynamic>) {
              return Album(
                id: item['id'] ?? item['album_id'],
                namaAlbum: item['nama_album'] ?? item['name'] ?? item['title'] ?? '',
                deskripsi: item['deskripsi'] ?? item['description'] ?? '',
                coverUrl: item['cover_url'] ?? item['cover'] ?? item['image'],
              );
            }
            return Album(namaAlbum: '', deskripsi: '');
          }).toList();
        } catch (e2) {
          print('getMyAlbums failed: $e2');
          
          // Method 3: Extract albums from posts
          final albumSet = <int, Map<String, dynamic>>{};
          for (final post in posts) {
            if (post.albumId != null && post.albumName != null) {
              albumSet[post.albumId!] = {
                'id': post.albumId,
                'nama_album': post.albumName,
                'deskripsi': '',
                'cover_url': null,
              };
            }
          }
          albums = albumSet.values.map((albumData) => Album(
            id: albumData['id'],
            namaAlbum: albumData['nama_album'] ?? '',
            deskripsi: albumData['deskripsi'] ?? '',
            coverUrl: albumData['cover_url'],
          )).toList();
          print('Extracted ${albums.length} albums from posts');
        }
      }
      
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _albums = albums;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    }
  }

  String? _avatarUrl() {
    final path = _user?['avatar']?.toString();
    if (path == null || path.isEmpty) return null;
    return ApiConfig.resolveMediaUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?['name']?.toString() ?? _user?['username']?.toString() ?? 'Profil'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Postingan'),
            Tab(text: 'Album'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: _avatarUrl() != null ? NetworkImage(_avatarUrl()!) : null,
                          child: _avatarUrl() == null ? const Icon(Icons.person, size: 36) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _user?['name']?.toString() ?? _user?['username']?.toString() ?? 'User',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if ((_user?['username']?.toString().isNotEmpty ?? false))
                                Text('@${_user!['username']}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Posts Tab
                        _posts.isEmpty
                            ? const Center(child: Text('Belum ada postingan'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  final post = _posts[index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ApiConfig.resolveMediaUrl(post.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                        // Albums Tab
                        _albums.isEmpty
                            ? const Center(child: Text('Belum ada album'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: _albums.length,
                                itemBuilder: (context, index) {
                                  final album = _albums[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      final token = prefs.getString('token');
                                      if (token != null && mounted) {
                                        if (mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AlbumDetailPage(
                                                albumId: album.id!,
                                                token: token,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: album.coverUrl != null
                                                  ? Image.network(
                                                      ApiConfig.resolveMediaUrl(album.coverUrl!),
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.photo_album,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.photo_album,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    album.namaAlbum,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    album.deskripsi,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


