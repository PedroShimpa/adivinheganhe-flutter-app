import 'package:flutter_test/flutter_test.dart';
import 'package:adivinheganhe/models/comment.dart';

void main() {
  group('Comment Model', () {
    test('should create Comment from JSON', () {
      final json = {
        'id': 1,
        'usuario': 'Test User',
        'user_photo': 'photo.jpg',
        'body': 'Test comment',
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, 1);
      expect(comment.usuario, 'Test User');
      expect(comment.userPhoto, 'photo.jpg');
      expect(comment.body, 'Test comment');
    });

    test('should handle null user_photo', () {
      final json = {
        'id': 1,
        'usuario': 'Test User',
        'user_photo': null,
        'body': 'Test comment',
      };

      final comment = Comment.fromJson(json);

      expect(comment.userPhoto, null);
    });
  });
}
