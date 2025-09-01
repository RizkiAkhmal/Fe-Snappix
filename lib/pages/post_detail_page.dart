import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fe_snappix/models/post_model.dart';
import 'package:fe_snappix/services/post_service.dart';
import 'package:fe_snappix/config/api_config.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final PostService _postService = PostService(baseUrl: ApiConfig.baseUrl);

  String? _token;
  String? _userId;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _loading = false;

  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  String? _editingCommentId;

  List<Post> _otherPosts = [];
  bool _loadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndUserId();
  }

  Future<void> _loadTokenAndUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("user_id");
    setState(() {
      _token = token;
      _userId = userId;
    });

    if (token != null) {
      try {
        final result = await _postService.checkLikeStatus(token, widget.post.id);
        setState(() {
          _isLiked = result['is_liked'] ?? false;
          _likesCount = result['likes_count'] ?? 0;
        });
        await _fetchComments();
        await _fetchOtherPosts();
      } catch (e) {
        print("Error init: $e");
      }
    }
  }

  Future<void> _fetchOtherPosts() async {
    if (_token == null) return;
    setState(() => _loadingPosts = true);
    try {
      final posts = await _postService.getPosts(_token!);
      setState(() {
        _otherPosts = posts.where((p) => p.id != widget.post.id).toList();
      });
    } finally {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_token == null) return;
    setState(() => _loading = true);

    try {
      if (_isLiked) {
        final result = await _postService.unlikePost(_token!, widget.post.id);
        setState(() {
          _isLiked = false;
          _likesCount = result['likes_count'] ?? _likesCount;
        });
      } else {
        final result = await _postService.likePost(_token!, widget.post.id);
        setState(() {
          _isLiked = true;
          _likesCount = result['likes_count'] ?? _likesCount;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchComments() async {
    if (_token == null) return;
    try {
      final data = await _postService.getComments(_token!, widget.post.id);
      setState(() => _comments = data['data'] ?? []);
    } catch (e) {
      print("Error fetch comments: $e");
    }
  }

  Future<void> _deleteComment(String commentId) async {
    if (_token == null) return;
    try {
      await _postService.deleteComment(_token!, int.parse(commentId));
      setState(() {
        _comments.removeWhere((c) => c['id'].toString() == commentId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal hapus komentar: $e")),
      );
    }
  }

  Future<void> _reportComment(String commentId) async {
    if (_token == null) return;
    try {
      await _postService.reportComment(
        _token!,
        int.parse(commentId),
        alasan: "Komentar tidak pantas",
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar berhasil dilaporkan")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal melaporkan komentar: $e")),
        );
      }
    }
  }

  void _startEditComment(String commentId, String oldText) {
    setState(() {
      _editingCommentId = commentId;
      _commentController.text = oldText;
    });
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, controller) => Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                        const SizedBox(width: 8),
                        Text(
                          _comments.isEmpty ? "Tidak ada komentar" : "${_comments.length} komentar",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _comments.isEmpty
                        ? const Center(child: Text("Belum ada komentar", style: TextStyle(color: Colors.grey, fontSize: 14)))
                        : ListView.builder(
                            controller: controller,
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final c = _comments[index];
                              final user = c['user'];
                              final commentId = c['id'].toString();
                              final userName = user != null ? user['name'] ?? "User" : "Anonim";
                              final avatarUrl = user?['avatar'] ?? "https://i.pravatar.cc/150?img=${index + 10}";

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl), backgroundColor: Colors.grey.shade300),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(c['isi_komentar'] ?? '', style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          _startEditComment(commentId, c['isi_komentar'] ?? '');
                                        } else if (value == 'delete') {
                                          await _deleteComment(commentId);
                                          modalSetState(() {});
                                        } else if (value == 'report') {
                                          await _reportComment(commentId);
                                        }
                                      },
                                      itemBuilder: (context) {
                                        if (_userId == c['user_id'].toString()) {
                                          return const [
                                            PopupMenuItem(value: 'edit', child: Text("Edit")),
                                            PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                                          ];
                                        } else {
                                          return const [
                                            PopupMenuItem(value: 'report', child: Text("Laporkan", style: TextStyle(color: Colors.red))),
                                          ];
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 18, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=10"), backgroundColor: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: const Offset(0, 2))],
                            ),
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: _editingCommentId != null ? "Edit komentar..." : "Tambahkan komentar...",
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: IconButton(
                            icon: Icon(_editingCommentId != null ? Icons.check : Icons.send, color: Colors.white, size: 20),
                            onPressed: () async {
                              if (_token == null || _commentController.text.trim().isEmpty) return;
                              try {
                                if (_editingCommentId != null) {
                                  await _postService.updateComment(_token!, int.parse(_editingCommentId!), _commentController.text.trim());
                                  await _fetchComments();
                                  setState(() => _editingCommentId = null);
                                  modalSetState(() {});
                                } else {
                                  final result = await _postService.addComment(_token!, widget.post.id, _commentController.text.trim());
                                  setState(() => _comments.insert(0, result['comment']));
                                  modalSetState(() {});
                                }
                                _commentController.clear();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan komentar: $e")));
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      body: ListView(
        children: [
          // Gambar post
          if (post.imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      ApiConfig.resolveMediaUrl(post.imageUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(height: 200, child: const Center(child: CircularProgressIndicator()));
                      },
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Avatar, username, like, comment, menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundImage: const NetworkImage("https://i.pravatar.cc/150?img=5")),
                const SizedBox(width: 8),
                Text(post.userName ?? "User", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loading ? null : _toggleLike,
                      icon: SvgPicture.asset(
                        _isLiked ? 'assets/icons/like-fill.svg' : 'assets/icons/like-outline.svg',
                        height: 26,
                        width: 26,
                        colorFilter: _isLiked
                            ? const ColorFilter.mode(Colors.red, BlendMode.srcIn)
                            : const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
                      ),
                    ),
                    Text('$_likesCount Likes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _showCommentsSheet,
                      icon: SvgPicture.asset('assets/icons/chat.svg', height: 26, width: 26, colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: "${post.userName ?? "User"} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),
          // Komentar singkat
          if (_comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: _showCommentsSheet,
                child: Text("Lihat semua ${_comments.length} komentar", style: GoogleFonts.inter(color: Colors.grey, fontSize: 15)),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text("Lainnya untuk dijelajahi", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
          if (_loadingPosts)
            const Center(child: CircularProgressIndicator())
          else if (_otherPosts.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text("Belum ada postingan lain"))
          else
            MasonryGridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: _otherPosts.length,
              itemBuilder: (context, index) {
                final p = _otherPosts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: p)));
                  },
                  child: _PostCard(post: p),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  String? _currentUserId;
  String? _token;
  late final PostService _postService = PostService(baseUrl: ApiConfig.baseUrl);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString("user_id");
      _token = prefs.getString("token");
    });
  }

  Future<void> _deletePost() async {
    if (_token == null) return;
    try {
      await _postService.deletePost(_token!, widget.post.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Postingan berhasil dihapus")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus postingan: $e")));
    }
  }

  Future<void> _reportPost() async {
    if (_token == null) return;
    try {
      await _postService.reportPost(_token!, widget.post.id, alasan: "Konten tidak pantas");
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Postingan berhasil dilaporkan")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal melaporkan postingan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ApiConfig.resolveMediaUrl(widget.post.imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.grey.shade200, height: 180, child: const Center(child: CupertinoActivityIndicator()));
              },
              errorBuilder: (context, _, __) => Container(color: Colors.grey.shade200, height: 180, child: const Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.post.caption.isNotEmpty ? widget.post.caption : '(Tanpa judul)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: const Icon(CupertinoIcons.ellipsis, size: 20, color: Colors.black),
                onSelected: (value) async {
                  if (value == 'hapus') await _deletePost();
                  if (value == 'laporkan') await _reportPost();
                },
                itemBuilder: (context) {
                  if (_currentUserId == widget.post.userId.toString()) {
                    return const [
                      PopupMenuItem(
                        value: 'hapus',
                        child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))]),
                      )
                    ];
                  } else {
                    return const [
                      PopupMenuItem(
                        value: 'laporkan',
                        child: Row(children: [Icon(Icons.flag, color: Colors.red), SizedBox(width: 8), Text('Laporkan', style: TextStyle(color: Colors.red))]),
                      )
                    ];
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
