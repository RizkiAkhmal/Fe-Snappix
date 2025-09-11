import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_snappix/services/profile_service.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:fe_snappix/pages/user_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ProfileService _profileService = ProfileService(baseUrl: ApiConfig.baseUrl);
  Timer? _debounce;

  String? _token;
  bool _isLoading = false;
  String _error = '';
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  void _onQueryChanged(String value) {
    _error = '';
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = value.trim();
    
    // Clear results immediately if query is empty
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    
    // Start search immediately for short queries (1-2 characters)
    if (query.length <= 2) {
      _debounce = Timer(const Duration(milliseconds: 50), () {
        if (_token != null) {
          _search(query);
        }
      });
    } else {
      // Use slightly longer delay for longer queries
      _debounce = Timer(const Duration(milliseconds: 100), () {
        if (_token != null) {
          _search(query);
        }
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await _profileService.searchUsers(_token!, query);
      if (!mounted) return;
      setState(() {
        _results = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal mencari pengguna: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _avatarPath(Map<String, dynamic> user) {
    final raw = user['avatar'];
    if (raw == null) return null;
    final path = raw.toString();
    if (path.isEmpty) return null;
    return ApiConfig.resolveMediaUrl(path);
  }

  Widget _buildSearchResults() {
    final query = _controller.text.trim();
    
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Mulai ketik untuk mencari pengguna',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ketik 1-2 huruf untuk melihat hasil',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari pengguna...'),
          ],
        ),
      );
    }
    
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pengguna ditemukan',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'untuk "$query"',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_results.length} hasil ditemukan untuk "$query"',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = _results[index];
              final name = (user['name'] ?? user['username'] ?? 'Pengguna').toString();
              final username = user['username']?.toString();
              final avatarUrl = _avatarPath(user);
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(name),
                subtitle: username != null ? Text('@$username') : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                        userId: int.tryParse(user['id']?.toString() ?? '' ) ?? 0,
                        initialUser: user,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari pengguna (ketik 1-2 huruf untuk mulai)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _results = []);
                            },
                          )
                        : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              if (_error.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
