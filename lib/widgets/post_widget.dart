import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adivinheganhe/services/api_service.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> currentUser;
  final VoidCallback? onDeleted;

  const PostWidget({
    super.key,
    required this.post,
    required this.currentUser,
    this.onDeleted,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  List comments = [];
  bool liked = false;
  int likeCount = 0;
  final baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes_count'] ?? 0;
    liked = widget.post['liked_by_user'] ?? false;
    _loadComments();
  }

  Future<void> _loadComments() async {
    final postId = widget.post['id'];
    final res = await http.get(
      Uri.parse('$baseUrl/posts/comments/$postId'),
      headers: {'Authorization': 'Bearer ${widget.currentUser['token']}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        print(res.body);
        comments = json.decode(res.body)['comments'] ?? [];
      });
    }
  }

  Future<void> _comment(String content) async {
    final postId = widget.post['id'];
    await http.post(
      Uri.parse('$baseUrl/posts/comment/$postId'),
      headers: {
        'Authorization': 'Bearer ${widget.currentUser['token']}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'content': content}),
    );
    _loadComments();
  }

  Future<void> _toggleLike() async {
    final postId = widget.post['id'];
    final res = await http.post(
      Uri.parse('$baseUrl/posts/$postId/toggle-like'),
      headers: {'Authorization': 'Bearer ${widget.currentUser['token']}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        liked = !liked;
        likeCount += liked ? 1 : -1;
      });
    }
  }

  Future<void> _deletePost() async {
    final postId = widget.post['id'];
    final res = await http.delete(
      Uri.parse('$baseUrl/posts/delete/$postId'),
      headers: {'Authorization': 'Bearer ${widget.currentUser['token']}'},
    );
    if (res.statusCode == 200) {
      if (widget.onDeleted != null) widget.onDeleted!();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deletado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnPost = widget.post['user_id'] == widget.currentUser['id'];
    final createdAt = DateTime.parse(widget.post['created_at']);
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.post['user_name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isOwnPost)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deletePost,
                  ),
              ],
            ),
            Text(widget.post['content'] ?? ''),
            if (widget.post['file'] != null && widget.post['file'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(widget.post['file']),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likeCount likes'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        final TextEditingController _commentController =
                            TextEditingController();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: comments.length,
                              itemBuilder: (_, index) {
                                final comment = comments[index];
                                return ListTile(
                                  title: Text(comment['user_name']),
                                  subtitle: Text(comment['content']),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Escreva um comentário',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () {
                                      if (_commentController.text.isNotEmpty) {
                                        _comment(_commentController.text);
                                        _commentController.clear();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
