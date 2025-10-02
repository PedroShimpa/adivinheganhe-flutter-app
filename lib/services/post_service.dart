import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:adivinheganhe/models/comment.dart';
import 'api_service.dart';

class PostService {
  final String baseUrl = ApiService.baseUrl;

  Future<List<Comment>> loadComments(int postId) async {
    final token = await ApiService().getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/posts/comments/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final rawComments = json.decode(response.body) ?? [];
      return (rawComments as List).map((c) => Comment.fromJson(c)).toList();
    } else {
      throw Exception('Erro ao carregar comentários');
    }
  }

  Future<void> addComment(int postId, String content) async {
    final token = await ApiService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/posts/comment/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'content': content}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao enviar comentário');
    }
  }

  Future<void> toggleLike(int postId) async {
    final token = await ApiService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/toggle-like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao curtir/descurtir');
    }
  }

  Future<void> deletePost(int postId) async {
    final token = await ApiService().getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/delete/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao deletar post');
    }
  }
}
