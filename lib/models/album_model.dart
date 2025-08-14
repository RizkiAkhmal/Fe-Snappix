class Album {
  final int? id;
  final String namaAlbum;
  final String deskripsi;

  Album({
    this.id,
    required this.namaAlbum,
    required this.deskripsi,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      namaAlbum: json['nama_album'],
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_album': namaAlbum,
      'deskripsi': deskripsi,
    };
  }
}
