class Post {
  final int id;
  final String caption;
  final String imageUrl;
  final int? albumId;
  final String? albumName; // nama album opsional
  final String? userName; // nama user opsional
  final String? userUsername; // username opsional
  final int? userId; // ID user yang membuat post
  final String? userAvatar; // avatar user opsional
  final String createdAt;

  Post({
    required this.id,
    required this.caption,
    required this.imageUrl,
    this.albumId,
    this.albumName,
    this.userName,
    this.userUsername,
    this.userId,
    this.userAvatar,
    required this.createdAt,
  });

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final int id = _asInt(json['id']) ?? 0;

    final String caption = _asString(
      json['caption'] ?? json['judul'],
      fallback: '',
    );

    final String imageUrl = _asString(
      json['image_url'] ?? json['image'] ?? json['photo_url'] ?? json['photo'],
      fallback: '',
    );

    final int? albumId =
        _asInt(json['album_id'] ?? json['albumId'] ?? json['id_album']);

    String? albumName;
    final dynamic albumObj = json['album'];
    if (albumObj is Map<String, dynamic>) {
      albumName = _asString(
        albumObj['name'] ?? albumObj['nama_album'] ?? albumObj['title'],
        fallback: '',
      );
      if (albumName.isEmpty) albumName = null;
    } else {
      final directName = json['album_name'] ?? json['nama_album'];
      if (directName != null) {
        final s = _asString(directName);
        albumName = s.isEmpty ? null : s;
      }
    }

    // Ambil nama user dari relasi
    String? userName;
    String? userUsername;
    int? userId;
    String? userAvatar;
    final dynamic userObj = json['user'];
    if (userObj is Map<String, dynamic>) {
      final s = _asString(userObj['name']);
      userName = s.isEmpty ? null : s;
      final uu = _asString(userObj['username'], fallback: '');
      userUsername = uu.isEmpty ? null : uu;
      userId = _asInt(userObj['id']);
      final avatar = _asString(
        userObj['avatar'] ??
            userObj['avatar_url'] ??
            userObj['photo'] ??
            userObj['profile_photo'] ??
            userObj['profile_photo_path'],
        fallback: '',
      );
      userAvatar = avatar.isEmpty ? null : avatar;
    }

    // Jika tidak ada user object, coba ambil langsung dari json
    if (userId == null) {
      userId = _asInt(json['user_id'] ?? json['userId'] ?? json['id_user']);
    }

    // Fallback lain untuk avatar di level root
    if (userAvatar == null || userAvatar.isEmpty) {
      final rootAvatar = _asString(
        json['user_avatar'] ??
            json['avatar_url'] ??
            json['avatar'] ??
            json['photo'] ??
            json['profile_photo'] ??
            json['profile_photo_path'],
        fallback: '',
      );
      if (rootAvatar.isNotEmpty) userAvatar = rootAvatar;
    }

    // Fallback username di root
    if (userUsername == null || userUsername.isEmpty) {
      final uu = _asString(json['username'], fallback: '');
      if (uu.isNotEmpty) userUsername = uu;
    }

    final String createdAt =
        _asString(json['created_at'] ?? json['createdAt'], fallback: '');

    return Post(
      id: id,
      caption: caption,
      imageUrl: imageUrl,
      albumId: albumId,
      albumName: albumName,
      userName: userName,
      userUsername: userUsername,
      userId: userId,
      userAvatar: userAvatar,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'image_url': imageUrl,
      'album_id': albumId,
      'user_id': userId,
      'user_avatar': userAvatar,
      'username': userUsername,
    };
  }

  Post copyWith({
    int? id,
    String? caption,
    String? imageUrl,
    int? albumId,
    String? albumName,
    String? userName,
    String? userUsername,
    String? userAvatar,
    int? userId,
    String? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      userName: userName ?? this.userName,
      userUsername: userUsername ?? this.userUsername,
      userId: userId ?? this.userId,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

