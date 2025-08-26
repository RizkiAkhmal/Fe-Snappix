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
  bool _loadingComments = false;
  final TextEditingController _commentController = TextEditingController();

  // tambahan untuk post lain
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
        await _fetchOtherPosts(); // ambil postingan lain
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
      // filter supaya tidak menampilkan postingan yang sedang dilihat
      final filtered = posts.where((p) => p.id != widget.post.id).toList();
      setState(() => _otherPosts = filtered);
    } catch (e) {
      print("Error fetch other posts: $e");
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update like: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchComments() async {
    if (_token == null) return;
    setState(() => _loadingComments = true);

    try {
      final data = await _postService.getComments(_token!, widget.post.id);
      setState(() {
        _comments = data['data'] ?? [];
      });
    } catch (e) {
      print("Error fetch comments: $e");
    } finally {
      setState(() => _loadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (_token == null || _commentController.text.trim().isEmpty) return;

    try {
      final result = await _postService.addComment(
        _token!,
        widget.post.id,
        _commentController.text.trim(),
      );
      setState(() {
        _comments = [result['comment'], ..._comments];
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambah komentar: $e")),
      );
    }
  }

  Future<void> _updateComment(int index, dynamic comment) async {
    final editController = TextEditingController(text: comment['isi_komentar']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Komentar"),
        content: TextField(
          controller: editController,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: "Tulis komentar..."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              try {
                final updated = await _postService.updateComment(
                  _token!,
                  comment['id'],
                  editController.text.trim(),
                );
                setState(() {
                  _comments[index] = updated['comment'];
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal update komentar: $e")),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(int index, dynamic comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Komentar"),
        content: const Text("Apakah kamu yakin ingin menghapus komentar ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _postService.deleteComment(_token!, comment['id']);
        setState(() {
          _comments.removeAt(index);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal hapus komentar: $e")),
        );
      }
    }
  }

  /// Helper untuk menentukan action apa saja yang bisa dipakai user
  List<Widget> _buildCommentActions(Map<String, dynamic> comment, int index) {
    final user = comment['user'];
    final isOwnComment = user != null && user['id'].toString() == _userId;
    final isPostOwner = widget.post.userId != null && widget.post.userId.toString() == _userId;

    List<Widget> actions = [];

    if (isOwnComment) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _updateComment(index, comment),
        ),
      );
    }

    if (isOwnComment || isPostOwner) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteComment(index, comment),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Postingan"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== detail postingan utama =====
                  if (post.imageUrl.isNotEmpty)
                    Image.network(post.imageUrl, fit: BoxFit.cover)
                  else
                    Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 80),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.caption.isNotEmpty
                              ? post.caption
                              : "(Tanpa caption)",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (post.userName != null)
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 18, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(post.userName!),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _loading ? null : _toggleLike,
                              icon: Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                            Text("$_likesCount suka"),
                          ],
                        ),
                        const Divider(),
                        const Text("Komentar",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_loadingComments)
                          const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator()))
                        else if (_comments.isEmpty)
                          const Text("Belum ada komentar")
                        else
                          Column(
                            children: _comments.asMap().entries.map((entry) {
                              final index = entry.key;
                              final c = entry.value;
                              final user = c['user'];

                              return ListTile(
                                leading: const Icon(Icons.comment,
                                    color: Colors.orange),
                                title: Text(c['isi_komentar'] ?? ''),
                                subtitle: Text(user != null
                                    ? user['name'] ?? 'Unknown'
                                    : 'Anonim'),
                                trailing: (user != null &&
                                        (user['id'].toString() == _userId ||
                                            (widget.post.userId != null && widget.post.userId.toString() ==
                                                _userId)))
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children:
                                            _buildCommentActions(c, index),
                                      )
                                    : null,
                              );
                            }).toList(),
                          ),
                        const Divider(),
                        const SizedBox(height: 8),

                        // ====== bagian post lain ======
                        const Text("Postingan Lain",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_loadingPosts)
                          const Center(child: CircularProgressIndicator())
                        else if (_otherPosts.isEmpty)
                          const Text("Belum ada postingan lain")
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
                  ),
                ],
              ),
            ),
          ),
          // ===== input komentar =====
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: const Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Tulis komentar...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.orange),
                    onPressed: _addComment,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reuse card dari home
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
