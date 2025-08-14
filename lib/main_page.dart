import 'package:fe_snappix/pages/add_album_page.dart';
import 'package:fe_snappix/pages/add_post_page.dart'; // Import halaman tambah postingan
import 'package:fe_snappix/pages/home_page.dart';
import 'package:fe_snappix/pages/profile_page.dart';
import 'package:fe_snappix/pages/search_page.dart';
import 'package:fe_snappix/services/post_service.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  final String token; // Token auth Sanctum

  const MainPage({super.key, required this.token});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const SizedBox(), // Halaman kosong untuk tombol tambah
    const ProfilePage(),
  ];

  final List<String> _titles = [
    "Home",
    "Search",
    "",
    "Profile",
  ];

  // Inisialisasi PostService dengan baseUrl API
  final PostService _postService = PostService(baseUrl: ''); // Ganti sesuai URL API kamu

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Mulai berkreasi sekarang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOption(
                    icon: Icons.camera_alt,
                    label: "Postingan",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPostPage(
                            token: widget.token,
                            postService: _postService, // Kirim service yang sudah diinisialisasi
                          ),
                        ),
                      );
                    },
                  ),
                  _buildOption(
                    icon: Icons.photo_album,
                    label: "Album",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAlbumPage(
                            token: widget.token,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Icon(icon, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          if (_currentIndex == 2) // Tombol tambah hanya muncul di index 2
            IconButton(
              icon: const Icon(Icons.add_box),
              onPressed: _showCreateModal,
            ),
        ],
      ),
      body: _currentIndex == 2 ? const SizedBox() : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            if (index == 2) {
              _showCreateModal(); // Tombol tengah memunculkan modal
            } else {
              _currentIndex = index;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
