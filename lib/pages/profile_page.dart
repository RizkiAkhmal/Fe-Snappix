import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/album_model.dart';
import 'edit_profile_page.dart';
import 'album_detail_page.dart';
import 'post_detail_page.dart';
import 'login_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/album_service.dart';

class ProfilePage extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;
  final ValueNotifier<int>? homeRefreshTrigger;

  const ProfilePage({super.key, this.refreshTrigger, this.homeRefreshTrigger});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}


class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _service;
  late final PostService _postService;
  AlbumService? _albumService; // tambahkan

  String? _token;
  String? _currentUserId;
  Map<String, dynamic>? _profile;
  List<Post> _myPosts = [];
  List<Album> _myAlbums = [];
  bool _loading = true;
  VoidCallback? _refreshListener;

  @override
  void initState() {
    super.initState();
    _service = ProfileService();
    _postService = PostService(baseUrl: ApiConfig.baseUrl);
    _loadData();

    if (widget.refreshTrigger != null) {
      _refreshListener = () {
        _loadData();
      };
      widget.refreshTrigger!.addListener(_refreshListener!);
    }
  }

  @override
  void dispose() {
    if (widget.refreshTrigger != null && _refreshListener != null) {
      widget.refreshTrigger!.removeListener(_refreshListener!);
    }
    super.dispose();
  }

  Future<void> _deleteAlbum(Album album) async {
    if (_token == null) return;

    try {
      _albumService ??= AlbumService(token: _token!); // pastikan service ada
      await _albumService!.deleteAlbum(album.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Album berhasil dihapus")),
        );
        setState(() {
          _myAlbums.removeWhere((a) => a.id == album.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus album: $e")),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        // Arahkan ke login bila token hilang/invalid
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _token = token;
      _currentUserId = userId;
    });

    try {
      final profile = await _service.getProfile(token);
      final posts = await _service.getMyPosts(token);
      final albumsData = await _service.getMyAlbums(token);

      final albums = Album.listFromJson(albumsData);

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
    ).then((_) => _loadData());
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
    return ApiConfig.resolveMediaUrl(path);
  }

  Future<void> _deletePost(Post post) async {
    if (_token == null) return;
    
    try {
      await _postService.deletePost(_token!, post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Postingan berhasil dihapus")),
        );
        // Hapus dari list lokal
        setState(() {
          _myPosts.removeWhere((p) => p.id == post.id);
        });
                 // Trigger refresh untuk HomePage juga
         if (widget.homeRefreshTrigger != null) {
           widget.homeRefreshTrigger!.value++;
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus postingan: $e")),
        );
      }
    }
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
        child: RefreshIndicator(
          onRefresh: _loadData,
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundImage: (_profile?['avatar'] != null && (_profile!['avatar'].toString().isNotEmpty))
                  ? NetworkImage(_buildImageUrl(_profile!['avatar']))
                  : null,
              child: (_profile?['avatar'] == null || _profile!['avatar'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
                _profile?['name'] ?? _profile?['username'] ?? 'User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
              if (_profile?['username'] != null)
            Text(
                  '@${_profile!['username']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
            // Email disembunyikan demi privasi
            if ((_profile?['bio'] ?? '').toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  _profile!['bio'].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
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
                      const TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                        tabs: [
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
                                            ).then((_) => _loadData());
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _buildImageUrl(post.imageUrl),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                // Delete button untuk post milik user
                                                if (_currentUserId == post.userId.toString())
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: GestureDetector(
                                                      onTap: () => _deletePost(post),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black54,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: const Icon(
                                                          Icons.delete,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              post.caption.isNotEmpty
                                                  ? post.caption
                                                  : '(Tanpa judul)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            // Album List
                          _myAlbums.isEmpty
                              ? const Center(child: Text('Belum ada album'))
                              : ListView.builder(
                                  itemCount: _myAlbums.length,
                                  itemBuilder: (context, index) {
                                    final album = _myAlbums[index];
                                    return ListTile(
  leading: CircleAvatar(
    backgroundImage: album.coverUrl != null
        ? NetworkImage(_buildImageUrl(album.coverUrl))
        : null,
    child: album.coverUrl == null
        ? const Icon(Icons.photo_album_outlined, color: Colors.grey)
        : null,
  ),
  title: Text(album.namaAlbum),
  subtitle: Text(album.deskripsi),
  trailing: IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () {
      _deleteAlbum(album);
    },
  ),
  onTap: () {
    if (_token != null && album.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlbumDetailPage(
            albumId: album.id!,
            token: _token!,
          ),
        ),
      ).then((_) => _loadData());
    }
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
      ),
    );
  }
}
