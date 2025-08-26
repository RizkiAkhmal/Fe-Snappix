// PostDetailPage.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        final result =
            await _postService.checkLikeStatus(token, widget.post.id);
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
      setState(() {
        _comments = data['data'] ?? [];
      });
    } catch (e) {
      print("Error fetch comments: $e");
    }
  }

  Future<void> _submitComment() async {
    if (_token == null || _commentController.text.trim().isEmpty) return;

    try {
      if (_editingCommentId != null) {
        await _postService.updateComment(
          _token!,
          int.parse(_editingCommentId!),
          _commentController.text.trim(),
        );
        await _fetchComments();
      } else {
        final result = await _postService.addComment(
          _token!,
          widget.post.id,
          _commentController.text.trim(),
        );
        setState(() {
          _comments.insert(0, result['comment']);
        });
      }
      _commentController.clear();
      setState(() => _editingCommentId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan komentar: $e")),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    if (_token == null) return;
    try {
      await _postService.deleteComment(
        _token!,
        int.parse(commentId),
      );
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
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    final user = c['user'];
                    final commentId = c['id'].toString();
                    return ListTile(
                      leading: const Icon(Icons.comment, color: Colors.orange),
                      title: Text(c['isi_komentar'] ?? ''),
                      subtitle: Text(
                          user != null ? user['name'] ?? "User" : "Anonim"),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _startEditComment(
                                commentId, c['isi_komentar'] ?? '');
                          } else if (value == 'delete') {
                            _deleteComment(commentId);
                          } else if (value == 'report') {
                            _reportComment(commentId);
                          }
                        },
                        itemBuilder: (context) {
                          if (_userId == c['user_id'].toString()) {
                            return [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text("Edit"),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text("Hapus"),
                              ),
                            ];
                          } else {
                            return [
                              const PopupMenuItem(
                                value: 'report',
                                child: Text("Laporkan"),
                              ),
                            ];
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: MediaQuery.of(context).viewInsets.add(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _editingCommentId != null
                              ? "Edit komentar..."
                              : "Tambahkan komentar...",
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _editingCommentId != null ? Icons.check : Icons.send,
                        color: Colors.blue,
                      ),
                      onPressed: _submitComment,
                    )
                  ],
                ),
              )
            ],
          ),
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
          if (post.imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200, // tinggi default sementara loading
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.image_not_supported, size: 80),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: _loading ? null : _toggleLike,
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: _showCommentsSheet,
                  icon: const Icon(Icons.mode_comment_outlined, size: 26),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      if (_token != null) {
                        try {
                          await _postService.deletePost(
                              _token!, widget.post.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Postingan berhasil dihapus")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Gagal hapus postingan: $e")),
                            );
                          }
                        }
                      }
                    } else if (value == 'report') {
                      if (_token != null) {
                        try {
                          await _postService.reportPost(
                            _token!,
                            widget.post.id,
                            alasan: "Konten tidak pantas",
                          );
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
                    }
                  },
                  itemBuilder: (context) {
                    if (_userId == widget.post.userId.toString()) {
                      return [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("Hapus"),
                        ),
                      ];
                    } else {
                      return [
                        const PopupMenuItem(
                          value: 'report',
                          child: Text("Laporkan"),
                        ),
                      ];
                    }
                  },
                  icon: const Icon(Icons.more_vert, size: 26),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("$_likesCount suka",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: "${post.userName ?? "User"} ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),
          if (_comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: GestureDetector(
                onTap: _showCommentsSheet,
                child: Text(
                  "Lihat semua ${_comments.length} komentar",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (_comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: "${_comments.first['user']?['name'] ?? "User"} ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: _comments.first['isi_komentar'] ?? ''),
                  ],
                ),
              ),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text("Postingan Lain",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_loadingPosts)
            const Center(child: CircularProgressIndicator())
          else if (_otherPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("Belum ada postingan lain"),
            )
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(post: p),
                      ),
                    );
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

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: post.imageUrl.isNotEmpty
              ? Image.network(post.imageUrl, fit: BoxFit.cover)
              : Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          post.caption.isNotEmpty ? post.caption : "(Tanpa judul)",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
