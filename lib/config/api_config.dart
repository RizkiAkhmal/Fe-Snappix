import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  // Gunakan baseUrl dinamis agar bekerja di Web, Android emulator, dan iOS/desktop
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator mengakses host via 10.0.2.2
      return 'http://10.0.2.2:8000/api';
    }
    // iOS simulator/desktop biasanya bisa akses 127.0.0.1 langsung
    return 'http://127.0.0.1:8000/api';
  }

  // Base origin tanpa suffix "/api" untuk akses file di storage
  static String get baseOrigin {
    final url = baseUrl;
    // hapus trailing "/api" jika ada
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  // Normalisasi path media agar bisa diakses di semua platform
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://i.pravatar.cc/300';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Hilangkan leading slash agar tidak double slash saat join
    final normalized = path.startsWith('/') ? path.substring(1) : path;

    // Jika path sudah diawali "storage/" atau "public/storage/", tetap gunakan seperti itu
    if (normalized.startsWith('storage/')) {
      return '$baseOrigin/$normalized';
    }
    if (normalized.startsWith('public/storage/')) {
      return '$baseOrigin/${normalized.replaceFirst('public/', '')}';
    }

    // Default: anggap path adalah relative ke storage
    return '$baseOrigin/storage/$normalized';
  }
}
