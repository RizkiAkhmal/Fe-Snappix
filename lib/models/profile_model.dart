class Profile {
  final int id;
  final String name;
  final String email;
  final String? avatar;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }
}
