class Post {
  final int id;
  final int userId;
  final String userName;
  final String content;
  final String? file;
  final DateTime createdAt;
  final int likesCount;
  final bool likedByUser;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.file,
    required this.createdAt,
    required this.likesCount,
    required this.likedByUser,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      content: json['content'] ?? '',
      file: json['file'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      likedByUser: json['liked_by_user'] ?? false,
    );
  }
}
