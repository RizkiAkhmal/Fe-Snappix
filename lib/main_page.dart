import 'package:fe_snappix/pages/add_album_page.dart';
import 'package:fe_snappix/pages/add_post_page.dart'; 
import 'package:fe_snappix/pages/home_page.dart';
import 'package:fe_snappix/pages/profile_page.dart';
import 'package:fe_snappix/pages/search_page.dart';
import 'package:fe_snappix/services/post_service.dart';
import 'package:fe_snappix/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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

  // Inisialisasi PostService dengan baseUrl API
  final PostService _postService = PostService(baseUrl: ApiConfig.baseUrl);

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
                            postService: _postService,
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

  /// Fungsi custom nav item dengan garis bawah
  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      label: '',
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: _currentIndex == index ? Colors.black : Colors.black54),
          if (_currentIndex == index)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 20,
              color: Colors.black, // garis bawah aktif
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 2 ? const SizedBox() : _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            setState(() {
              if (index == 2) {
                _showCreateModal();
              } else {
                _currentIndex = index;
              }
            });
          },
          items: [
            _buildNavItem(Iconsax.home_2, 0),
            _buildNavItem(Iconsax.search_normal, 1),
            _buildNavItem(Iconsax.add_square, 2),
            _buildNavItem(Iconsax.user, 3),
          ],
        ),
      ),
    );
  }
}
