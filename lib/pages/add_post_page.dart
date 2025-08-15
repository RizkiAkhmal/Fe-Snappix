import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';

class AddPostPage extends StatefulWidget {
  final String token;
  final PostService postService;

  const AddPostPage({super.key, required this.token, required this.postService});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();

  File? _selectedImage; // untuk mobile
  XFile? _webImage;     // untuk web

  int? _selectedAlbumId; // pilih album sebagai id
  List<Map<String, dynamic>> _albums = [];
  bool _isLoadingAlbums = true;
  bool _isSubmitting = false; // tambah loading state

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat album: $e')));
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

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post berhasil disimpan!')));

        _captionController.clear();
        setState(() {
          _selectedImage = null;
          _webImage = null;
          _selectedAlbumId = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuat post: $e')));
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
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          } else {
            return const Center(
              child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
            );
          }
        },
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else {
      return const Center(
        child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Postingan"), backgroundColor: Colors.orange),
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
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _imagePreview(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _captionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Caption",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Caption tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
  value: _selectedAlbumId,
  decoration: const InputDecoration(
    labelText: "Pilih Album (opsional)",
    border: OutlineInputBorder(),
  ),
  items: _albums
      .map((album) {
        final dynamic rawId = album['id'];
        final int id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
        final String name = (album['name'] ?? '').toString();
        return DropdownMenuItem<int>(
          value: id,
          child: Text(name),
        );
      })
      .toList(),
  onChanged: (value) => setState(() => _selectedAlbumId = value),
  isExpanded: true,
),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Simpan Postingan", style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
