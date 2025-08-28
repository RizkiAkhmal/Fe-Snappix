import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> profile;
  final VoidCallback onUpdated;

  const EditProfilePage({
    super.key,
    required this.token,
    required this.profile,
    required this.onUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  File? _avatarFile;
  bool _loading = false;

  late final ProfileService _service =
      ProfileService(baseUrl: 'http://10.0.2.2:8000/api');

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.profile['username'] ?? '');
    _nameController = TextEditingController(text: widget.profile['name'] ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    try {
      // Update username & name
      await _service.updateProfile(
        widget.token,
        username: _usernameController.text.trim(),
        name: _nameController.text.trim(),
      );

      // Update password jika diisi
      if (_currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        await _service.changePassword(
          widget.token,
          _currentPasswordController.text.trim(),
          _newPasswordController.text.trim(),
        );
      }

      // TODO: Upload avatar jika mau, bisa buat endpoint multipart di service

      widget.onUpdated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui profil: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : (widget.profile['avatar'] != null
                        ? NetworkImage(
                            'http://10.0.2.2:8000/storage/${widget.profile['avatar']}')
                        : const AssetImage('assets/avatar_placeholder.png')
                            as ImageProvider),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Lama"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Baru"),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Simpan"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
