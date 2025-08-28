import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/album_model.dart'; // <- import Album
import 'edit_profile_page.dart';
import 'post_detail_page.dart';
import 'login_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _service;
  String? _token;
  Map<String, dynamic>? _profile;
  List<Post> _myPosts = [];
  List<Album> _myAlbums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ProfileService();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    if (!mounted) return;
    setState(() => _token = token);

    try {
      final profile = await _service.getProfile(token);
      final posts = await _service.getMyPosts(token);
      final albumsData = await _service.getMyAlbums(token);

      final albums = albumsData.map<Album>((json) => Album.fromJson(json)).toList();

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _myPosts = posts;
        _myAlbums = albums;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal load profil: $e')));
    }
  }

  void _openEditProfile() {
    if (_profile == null || _token == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          token: _token!,
          profile: _profile!,
          onUpdated: _loadData,
        ),
      ),
    );
  }

  void _logout() async {
    await _service.logout();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'https://i.pravatar.cc/300';
    return path.startsWith('http')
        ? path
        : 'http://127.0.0.1:8000/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _buildImageUrl(_profile?['avatar']),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _profile?['username'] ?? 'Username',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _profile?['email'] ?? '@email',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _openEditProfile,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Profil"),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text(
                    "Keluar",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Postingan'),
                        Tab(text: 'Album'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Postingan Grid
                          _myPosts.isEmpty
                              ? const Center(child: Text('Belum ada postingan'))
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: MasonryGridView.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    itemCount: _myPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = _myPosts[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PostDetailPage(post: post),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                _buildImageUrl(post.imageUrl),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              post.caption.isNotEmpty
                                                  ? post.caption
                                                  : '(Tanpa judul)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          // Album List menggunakan model Album
                          _myAlbums.isEmpty
                              ? const Center(child: Text('Belum ada album'))
                              : ListView.builder(
                                  itemCount: _myAlbums.length,
                                  itemBuilder: (context, index) {
                                    final album = _myAlbums[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          _buildImageUrl(album.deskripsi),
                                          // jika ada cover di API, bisa diganti dengan album.cover
                                        ),
                                      ),
                                      title: Text(album.namaAlbum),
                                      subtitle: Text(album.deskripsi),
                                      onTap: () {
                                        // Navigasi ke detail album bisa ditambahkan
                                      },
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
