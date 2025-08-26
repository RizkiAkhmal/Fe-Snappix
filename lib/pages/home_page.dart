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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _token;
  late final PostService _postService = PostService(baseUrl: ApiConfig.baseUrl);

  bool _isLoadingPosts = false;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    setState(() {
      _token = token;
    });
    if (token != null) {
      await _fetchPosts(token);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
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
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(post: post),
                            ),
                          );
                        },
                        child: _PostCard(post: post),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // tinggi minimal gambar juga responsive
    double minHeight = 150;
    if (screenWidth > 600) minHeight = 200;
    if (screenWidth > 900) minHeight = 250;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: post.imageUrl.isNotEmpty
                ? Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: minHeight,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, _, __) => Container(
                      height: minHeight,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: minHeight,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.caption.isNotEmpty ? post.caption : '(Tanpa judul)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: Colors.black,
                ),
                onPressed: () {
                  // TODO: menu aksi (edit, hapus, dsb)
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
