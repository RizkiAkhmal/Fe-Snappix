import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPostPage extends StatefulWidget {
  final String token;
  final PostService postService;

  const AddPostPage({
    super.key,
    required this.token,
    required this.postService,
  });

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();

  File? _selectedImage;
  XFile? _webImage;

  int? _selectedAlbumId;
  List<Map<String, dynamic>> _albums = [];
  bool _isLoadingAlbums = true;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserAlbums();
  }

  Future<void> _fetchUserAlbums() async {
    try {
      final albumsData = await widget.postService.getUserAlbums(widget.token);
      setState(() {
        _albums = albumsData;
        _isLoadingAlbums = false;
      });
    } catch (e) {
      setState(() => _isLoadingAlbums = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat album: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _selectedImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final imageFile = kIsWeb ? null : _selectedImage;

        await widget.postService.createPost(
          token: widget.token,
          judul: _captionController.text,
          imageFile: imageFile,
          webImage: _webImage,
          albumId: _selectedAlbumId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post berhasil disimpan!')),
        );

        _captionController.clear();
        setState(() {
          _selectedImage = null;
          _webImage = null;
          _selectedAlbumId = null;
        });

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat post: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _imagePreview() {
    if (kIsWeb && _webImage != null) {
      return FutureBuilder<Uint8List>(
        future: _webImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(snapshot.data!, fit: BoxFit.cover),
            );
          } else {
            return const Icon(Icons.add_a_photo, size: 50, color: Colors.grey);
          }
        },
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else {
      return const Icon(Icons.add_a_photo, size: 50, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leadingWidth: 150,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Postingan',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoadingAlbums
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // IMAGE
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Align(
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            widthFactor: 0.45,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Center(child: _imagePreview()),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                          color: Colors.black12, thickness: 1, height: 0),

                      // CAPTION
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _captionController,
                            maxLines: 3,
                            maxLength: 255,
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Tulis caption di sini...",
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              counterText: "",
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Caption tidak boleh kosong'
                                : null,
                            onChanged: (value) {
                              setState(() {}); // update counter
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_captionController.text.length}/255",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                          color: Colors.black12, thickness: 1, height: 0),

                      // ALBUM
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: _selectedAlbumId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _albums.map((album) {
                          final dynamic rawId = album['id'];
                          final int id = rawId is int
                              ? rawId
                              : int.tryParse(rawId?.toString() ?? '') ?? 0;
                          final String name = (album['name'] ?? '').toString();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name,
                                style: GoogleFonts.inter(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedAlbumId = value),
                        isExpanded: true,
                        hint: Text("Pilih Album (opsional)",
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: SizedBox(
        height: 45,
        child: FloatingActionButton.extended(
          onPressed: _isSubmitting ? null : _submitPost,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          label: _isSubmitting
              ? const SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Text(
                    "Buat",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
