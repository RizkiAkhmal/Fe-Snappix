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
}
