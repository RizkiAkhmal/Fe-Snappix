import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_snappix/services/post_service.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:fe_snappix/models/post_model.dart';
import './post_detail_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          columnCount: crossAxisCount,
                          child: SlideAnimation(
                            verticalOffset: 50.0, // muncul dari bawah
                            curve: Curves.easeOutCubic, // smooth banget
                            child: FadeInAnimation(
                              curve: Curves.easeOut, // fade pelan
                              child: _PostCard(
                                post: post,
                                currentUserId: _currentUserId!,
                              ),
                            ),
                          ),
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
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUserId = widget.currentUserId;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        _onTapUp(details);
        // pindah ke detail_post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailPage(post: post), // ganti sesuai nama page detailmu
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

                      Future<bool?> showConfirmBottomSheet({
                        required String title,
                        required String message,
                        required String confirmText,
                        required Color confirmColor,
                      }) {
                        return showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // drag handle
                                    Container(
                                      width: 40,
                                      height: 5,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),

                                    // judul
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // pesan
                                    Text(
                                      message,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // tombol aksi utama
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: confirmColor,
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        confirmText,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // tombol batal
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        "Batal",
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      Future<void> showResponseBottomSheet(
                        BuildContext context, {
                        required String title,
                        required String message,
                        required Color color,
                        IconData icon = Icons.info,
                      }) {
                        return showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, -3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Jika ingin lebih clean, bisa hapus drag handle juga
                                    Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    // Content row: icon + text (tidak ada tombol X)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              color.withOpacity(0.15),
                                          child: Icon(icon,
                                              color: color, size: 24),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: color,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                message,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      if (value == 'hapus') {
                        final confirm = await showConfirmBottomSheet(
                          title: "Hapus Postingan",
                          message:
                              "Apakah kamu yakin ingin menghapus postingan ini? Aksi ini tidak bisa dibatalkan.",
                          confirmText: "Hapus",
                          confirmColor: Colors.red,
                        );

                        if (confirm == true) {
                          try {
                            await PostService(baseUrl: ApiConfig.baseUrl)
                                .deletePost(token, post.id);

                            if (context.mounted) {
                              await showResponseBottomSheet(
                                context,
                                title: "Berhasil",
                                message: "Postingan berhasil dihapus",
                                color: Colors.green,
                                icon: Icons.check_circle,
                              );

                              final homeState = context
                                  .findAncestorStateOfType<HomePageState>();
                              homeState?.setState(() {
                                homeState._posts
                                    .removeWhere((p) => p.id == post.id);
                              });

                              final profileRefresh =
                                  homeState?.widget.profileRefreshTrigger;
                              if (profileRefresh != null)
                                profileRefresh.value++;
                            }
                          } catch (e) {
                            if (context.mounted) {
                              await showResponseBottomSheet(
                                context,
                                title: "Gagal",
                                message: "Gagal menghapus postingan: $e",
                                color: Colors.red,
                                icon: Icons.error,
                              );
                            }
                          }
                        }
                      } else if (value == 'laporkan') {
                        final confirm = await showConfirmBottomSheet(
                          title: "Laporkan Postingan",
                          message:
                              "Apakah kamu yakin ingin melaporkan postingan ini sebagai konten tidak pantas?",
                          confirmText: "Laporkan",
                          confirmColor: const Color.fromARGB(255, 255, 0, 0),
                        );

                        if (confirm == true) {
                          try {
                            await PostService(baseUrl: ApiConfig.baseUrl)
                                .reportPost(token, post.id,
                                    alasan: "Konten tidak pantas");

                            if (context.mounted) {
                              await showResponseBottomSheet(
                                context,
                                title: "Berhasil",
                                message: "Postingan berhasil dilaporkan",
                                color: Colors.blue,
                                icon: Icons.flag,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              await showResponseBottomSheet(
                                context,
                                title: "Gagal",
                                message: "Gagal melaporkan postingan: $e",
                                color: Colors.red,
                                icon: Icons.error,
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (currentUserId == post.userId.toString())
                        PopupMenuItem(
                          value: 'hapus',
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.15),
                                      Colors.red.withOpacity(0.05)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hapus Postingan',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        PopupMenuItem(
                          value: 'laporkan',
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.15),
                                      Colors.orange.withOpacity(0.05)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flag,
                                    color: Colors.deepOrange, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Laporkan',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepOrange.shade600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}