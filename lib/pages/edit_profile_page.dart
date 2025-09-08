import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:fe_snappix/services/profile_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfilePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> profile;
  final VoidCallback? onUpdated;

  const EditProfilePage({super.key, required this.token, required this.profile, this.onUpdated});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  XFile? _pickedImage;
  File? _avatarFile;
  bool _isLoading = false;
  bool _isChangingPassword = false;
  final _profileService = ProfileService();

  String? _initialAvatarUrl() {
    final raw = widget.profile['avatar'];
    if (raw == null || raw.toString().isEmpty) return null;
    return ApiConfig.resolveMediaUrl(raw.toString());
  }

  @override
  void initState() {
    super.initState();
    // Prefill from incoming profile data
    final p = widget.profile;
    _nameController.text = (p['name'] ?? '').toString();
    _emailController.text = (p['email'] ?? '').toString();
    _usernameController.text = (p['username'] ?? '').toString();
    _bioController.text = (p['bio'] ?? '').toString();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        if (!kIsWeb) {
          _avatarFile = File(picked.path);
        } else {
          _avatarFile = null;
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_pickedImage == null) {
        // No file: send JSON PUT via service with only provided fields
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final username = _usernameController.text.trim();
        final bio = _bioController.text.trim();

        await _profileService.updateProfile(
          widget.token,
          username: username.isEmpty ? null : username,
          name: name.isEmpty ? null : name,
          email: email.isEmpty ? null : email,
          bio: bio.isEmpty ? null : bio,
        );
      } else {
        // With file: use multipart and method spoofing for Laravel
        final dio = Dio();
        final Map<String, dynamic> formMap = {"_method": "PUT"};
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final username = _usernameController.text.trim();
        final bio = _bioController.text.trim();
        if (name.isNotEmpty) formMap["name"] = name;
        if (email.isNotEmpty) formMap["email"] = email;
        if (username.isNotEmpty) formMap["username"] = username;
        if (bio.isNotEmpty) formMap["bio"] = bio;

        if (kIsWeb) {
          // On web, use bytes for MultipartFile
          final bytes = await _pickedImage!.readAsBytes();
          formMap["avatar"] = MultipartFile.fromBytes(
            bytes,
            filename: _pickedImage!.name,
          );
        } else if (_avatarFile != null) {
          formMap["avatar"] = await MultipartFile.fromFile(
            _avatarFile!.path,
            filename: _avatarFile!.path.split("/").last,
          );
        }

        final formData = FormData.fromMap(formMap);

        final response = await dio.post(
          "${ApiConfig.baseUrl}/user/profile",
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer ${widget.token}",
              "Accept": "application/json",
            },
          ),
        );

        if (response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      widget.onUpdated?.call();
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map && (e.response?.data as Map).containsKey('message')
          ? (e.response?.data['message']).toString()
          : 'Gagal update profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitChangePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field password')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await _profileService.changePassword(widget.token, current, newPass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah password: $e')),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (_pickedImage != null && kIsWeb
                              ? NetworkImage(_pickedImage!.path)
                              : (_initialAvatarUrl() != null
                                  ? NetworkImage(_initialAvatarUrl()!)
                                  : null)),
                      child: _avatarFile == null && _pickedImage == null && _initialAvatarUrl() == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update Profile"),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Ubah Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Saat Ini',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isChangingPassword ? null : _submitChangePassword,
                child: _isChangingPassword
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
