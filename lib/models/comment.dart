class Comment {
  final int id;
  final String usuario;
  final String body;
  final String? userPhoto;
  final bool? isAdmin;

  Comment({
    required this.id,
    required this.usuario,
    required this.body,
    this.userPhoto,
    this.isAdmin,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      usuario: json['usuario'] ?? 'Anônimo',
      body: json['body'] ?? '',
      userPhoto: json['user_photo'],
      isAdmin: json['is_admin'] == 'S' || json['is_admin'] == true,
    );
  }
}
