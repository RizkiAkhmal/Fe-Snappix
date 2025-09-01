class Album {
  final int? id;
  final String namaAlbum;
  final String deskripsi;
  final String? coverUrl;

  Album({
    this.id,
    required this.namaAlbum,
    required this.deskripsi,
    this.coverUrl,
  });

  /// Convert dynamic ke int aman
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Convert dynamic ke String
  static String _toString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  /// Factory dari JSON fleksibel
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: _toInt(json['id'] ?? json['album_id']),
      namaAlbum: _toString(json['nama_album'] ?? json['name'] ?? json['title']),
      deskripsi: _toString(json['deskripsi'] ?? json['description']),
      coverUrl: _toString(json['cover_url'] ?? json['cover'] ?? json['image'] ?? '', fallback: '').isEmpty
          ? null
          : _toString(json['cover_url'] ?? json['cover'] ?? json['image'] ?? ''),
    );
  }

  /// Parsing List JSON ke List<Album>
  static List<Album> listFromJson(dynamic data) {
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return Album.fromJson(e);
        } else if (e is Map) {
          return Album.fromJson(Map<String, dynamic>.from(e));
        } else {
          return Album(namaAlbum: '', deskripsi: '');
        }
      }).toList();
    }
    return [];
  }

  /// Konversi ke JSON (untuk request)
  Map<String, dynamic> toJson() {
    return {
      'nama_album': namaAlbum,
      'deskripsi': deskripsi,
      if (coverUrl != null) 'cover_url': coverUrl,
    };
  }

  /// Salinan baru dengan field dimodifikasi
  Album copyWith({
    int? id,
    String? namaAlbum,
    String? deskripsi,
    String? coverUrl,
  }) {
    return Album(
      id: id ?? this.id,
      namaAlbum: namaAlbum ?? this.namaAlbum,
      deskripsi: deskripsi ?? this.deskripsi,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  @override
  String toString() {
    return 'Album(id: $id, namaAlbum: $namaAlbum, deskripsi: $deskripsi, coverUrl: $coverUrl)';
  }
}