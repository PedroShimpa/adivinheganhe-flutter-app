import 'package:flutter_test/flutter_test.dart';
import 'package:adivinheganhe/models/post.dart';

void main() {
  group('Post Model', () {
    test('should create Post from JSON', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'user_name': 'Test User',
        'content': 'Test content',
        'file': 'test.jpg',
        'created_at': '2023-01-01T00:00:00.000Z',
        'likes_count': 5,
        'liked_by_user': true,
      };

      final post = Post.fromJson(json);

      expect(post.id, 1);
      expect(post.userId, 10);
      expect(post.userName, 'Test User');
      expect(post.content, 'Test content');
      expect(post.file, 'test.jpg');
      expect(post.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(post.likesCount, 5);
      expect(post.likedByUser, true);
    });

    test('should handle null file', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'user_name': 'Test User',
        'content': 'Test content',
        'file': null,
        'created_at': '2023-01-01T00:00:00.000Z',
        'likes_count': 0,
        'liked_by_user': false,
      };

      final post = Post.fromJson(json);

      expect(post.file, null);
    });
  });
}
