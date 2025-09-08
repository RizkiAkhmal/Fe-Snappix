import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_snappix/services/post_service.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:fe_snappix/models/post_model.dart';
import './post_detail_page.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;
  final ValueNotifier<int>? profileRefreshTrigger;

  const HomePage({super.key, this.refreshTrigger, this.profileRefreshTrigger});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? _token;
  String? _currentUserId;
  late final PostService _postService = PostService(baseUrl: ApiConfig.baseUrl);

  bool _isLoadingPosts = false;
  List<Post> _posts = [];

  VoidCallback? _refreshListener;

  @override
  void initState() {
    super.initState();
    _loadTokenAndUser();

    if (widget.refreshTrigger != null) {
      _refreshListener = () {
        _loadTokenAndUser();
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

  Future<void> _loadTokenAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("user_id");
    setState(() {
      _token = token;
      _currentUserId = userId;
    });
    if (token != null) await _fetchPosts(token);
  }

  Future<void> _fetchPosts(String token) async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _postService.getPosts(token);
      setState(() => _posts = posts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat postingan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> reloadPosts() async {
    if (_token != null) {
      await _fetchPosts(_token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null || _currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_token != null) await _fetchPosts(_token!);
        },
        child: CustomScrollView(
          slivers: [
            if (_isLoadingPosts)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Belum ada postingan')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.crossAxisExtent;
                    int crossAxisCount = 2;
                    if (screenWidth > 600) crossAxisCount = 3;
                    if (screenWidth > 900) crossAxisCount = 4;
                    if (screenWidth > 1200) crossAxisCount = 5;

                    return SliverMasonryGrid.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return _PostCard(
                          post: post,
                          currentUserId: _currentUserId!,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;

  const _PostCard({required this.post, required this.currentUserId});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  double _scale = 1.0;
  String? _avatar;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.96); // mengecil halus saat ditekan
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0); // balik normal
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  void initState() {
    super.initState();
    _maybeFetchAvatarDetail();
  }

  Future<void> _maybeFetchAvatarDetail() async {
    if (widget.post.userAvatar != null && widget.post.userAvatar!.isNotEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final detail = await PostService(baseUrl: ApiConfig.baseUrl).getPost(token, widget.post.id);
      if (!mounted) return;
      setState(() {
        _avatar = detail.userAvatar;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUserId = widget.currentUserId;

    // Lazy load avatar jika belum tersedia pada list
    if (_avatar == null && (post.userAvatar == null || post.userAvatar!.isEmpty)) {
      SharedPreferences.getInstance().then((prefs) async {
        final token = prefs.getString('token');
        if (!mounted || token == null) return;
        try {
          final detail = await PostService(baseUrl: ApiConfig.baseUrl).getPost(token, post.id);
          if (!mounted) return;
          setState(() {
            _avatar = detail.userAvatar;
          });
        } catch (_) {}
      });
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        _onTapUp(details);
        final effectiveAvatar = post.userAvatar ?? _avatar;
        final enrichedPost = post.copyWith(userAvatar: effectiveAvatar);
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 0),
            pageBuilder: (_, __, ___) => PostDetailPage(post: enrichedPost),
          ),
        );
      },
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 4), // makin tipis
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: post.imageUrl.isNotEmpty
                    ? Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, _, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        width: double.infinity,
                        height: 150,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 2), // sebelumnya 4 → makin rapat
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: ((post.userAvatar ?? _avatar) != null && (post.userAvatar ?? _avatar)!.isNotEmpty)
                        ? NetworkImage(ApiConfig.resolveMediaUrl((post.userAvatar ?? _avatar)!))
                        : null,
                    child: ((post.userAvatar ?? _avatar) == null || (post.userAvatar ?? _avatar)!.isEmpty)
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.caption.isNotEmpty ? post.caption : '(Tanpa judul)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // sedikit kecil biar serasi
                      ),
                    ),
                  ),
                  const SizedBox(width: 2), // super rapat
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    icon: const Icon(
                      CupertinoIcons.ellipsis,
                      size: 16, // lebih kecil biar nggak tabrakan
                      color: Colors.black,
                    ),
                    onSelected: (value) async {
                      final token = await SharedPreferences.getInstance()
                          .then((prefs) => prefs.getString("token"));
                      if (token == null) return;

                      if (value == 'hapus') {
                        try {
                          await PostService(baseUrl: ApiConfig.baseUrl)
                              .deletePost(token, post.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Postingan berhasil dihapus")),
                            );
                            final homeState = context
                                .findAncestorStateOfType<HomePageState>();
                            homeState?.setState(() {
                              homeState._posts
                                  .removeWhere((p) => p.id == post.id);
                            });
                            // Trigger refresh untuk ProfilePage juga
                            final profileRefresh =
                                homeState?.widget.profileRefreshTrigger;
                            if (profileRefresh != null) {
                              profileRefresh.value++;
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Gagal menghapus postingan: $e")),
                            );
                          }
                        }
                      } else if (value == 'laporkan') {
                        try {
                          await PostService(baseUrl: ApiConfig.baseUrl)
                              .reportPost(token, post.id,
                                  alasan: "Konten tidak pantas");
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Postingan berhasil dilaporkan")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Gagal melaporkan postingan: $e")),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (currentUserId == post.userId.toString())
                        PopupMenuItem(
                          value: 'hapus',
                          child: Row(
                            children: const [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        )
                      else
                        PopupMenuItem(
                          value: 'laporkan',
                          child: Row(
                            children: const [
                              Icon(Icons.flag,
                                  color: Color.fromARGB(255, 255, 0, 0)),
                              SizedBox(width: 8),
                              Text(
                                'Laporkan',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 255, 0, 0)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
