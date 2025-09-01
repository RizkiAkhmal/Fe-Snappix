import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/album_model.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/album_service.dart';
import '../config/api_config.dart';
import 'post_detail_page.dart';

class AlbumDetailPage extends StatefulWidget {
  final int albumId;
  final String token;

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    required this.token,
  });

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late final PostService _postService;
  late final AlbumService _albumService;

  Album? _album;
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _postService = PostService(baseUrl: ApiConfig.baseUrl);
    _albumService = AlbumService(token: widget.token);
    _loadAlbumData();
  }

  Future<void> _loadAlbumData() async {
    try {
      // Load album detail and posts in parallel
      final albumFuture = _albumService.getAlbumDetail(widget.albumId);
      final postsFuture = _postService.getPostsByAlbum(widget.token, widget.albumId);

      final results = await Future.wait([albumFuture, postsFuture]);

      if (mounted) {
        setState(() {
          _album = results[0] as Album;
          _posts = results[1] as List<Post>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat album: $e')),
        );
      }
    }
  }

  String _buildImageUrl(String? path) {
    return ApiConfig.resolveMediaUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_album == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Album Tidak Ditemukan'),
        ),
        body: const Center(
          child: Text('Album tidak dapat dimuat'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_album!.namaAlbum),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album Cover
                if (_album!.coverUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _buildImageUrl(_album!.coverUrl),
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_album,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Album Info
                Text(
                  _album!.namaAlbum,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _album!.deskripsi,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${_posts.length} postingan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Posts Grid
          Expanded(
            child: _posts.isEmpty
                ? const Center(
                    child: Text('Belum ada postingan di album ini'),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemCount: _posts.length,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
