class Post {
  final int id;
  final String caption;
  final String imageUrl;
  final int? albumId;
  final String? albumName; // nama album opsional
  final String createdAt;

  Post({
    required this.id,
    required this.caption,
    required this.imageUrl,
    this.albumId,
    this.albumName,
    required this.createdAt,
  });

  /// Membuat object Post dari JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      caption: json['caption'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      albumId: json['album_id'] as int?,
      albumName: json['album'] != null ? json['album']['name'] as String : null,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  /// Mengubah object Post menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'image_url': imageUrl,
      'album_id': albumId,
      // albumName biasanya tidak dikirim ke server, cukup albumId
    };
  }

  /// Membuat copy Post dengan beberapa field diubah (opsional)
  Post copyWith({
    int? id,
    String? caption,
    String? imageUrl,
    int? albumId,
    String? albumName,
    String? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
