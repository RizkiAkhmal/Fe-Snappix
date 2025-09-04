import 'package:flutter/material.dart';
import 'package:fe_snappix/services/album_service.dart';
import 'package:fe_snappix/models/album_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAlbumPage extends StatefulWidget {
  final String token;

  const AddAlbumPage({super.key, required this.token});

  @override
  State<AddAlbumPage> createState() => _AddAlbumPageState();
}

class _AddAlbumPageState extends State<AddAlbumPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  late final AlbumService _albumService;

  @override
  void initState() {
    super.initState();
    _albumService = AlbumService(token: widget.token);
  }

  Future<void> _saveAlbum() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    Album album = Album(
      namaAlbum: _nameController.text,
      deskripsi: _descriptionController.text,
    );

    try {
      await _albumService.createAlbum(album);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Album "${album.namaAlbum}" berhasil disimpan!')),
      );

      _nameController.clear();
      _descriptionController.clear();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan album: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        leadingWidth: 120,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Album',
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nama Album
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      maxLength: 255,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nama Album',
                        hintStyle:
                            GoogleFonts.inter(fontSize: 13, color: Colors.grey),
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
                          ? 'Nama album tidak boleh kosong'
                          : null,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_nameController.text.length}/255",
                      textAlign: TextAlign.right,
                      style:
                          GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.black12, thickness: 1, height: 0),
                const SizedBox(height: 24),

                // Deskripsi Album
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 255,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Deskripsi (opsional)',
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
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_descriptionController.text.length}/255",
                      textAlign: TextAlign.right,
                      style:
                          GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // ruang agar FAB tidak menutupi
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 45,
        child: FloatingActionButton.extended(
          onPressed: _isSubmitting ? null : _saveAlbum,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
