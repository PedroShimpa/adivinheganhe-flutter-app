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
  bool commentsLoaded = false;
  final baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    // Inicializa contagem de likes e status de like
    likeCount = widget.post['likes_count'] ?? 0;
    liked = widget.post['liked_by_user'] ?? false;
  }

  Future<void> _loadComments() async {
    if (commentsLoaded) return;
    final token = await ApiService().getToken();
    final postId = widget.post['id'];

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/posts/comments/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final rawComments = json.decode(res.body)['comments'] ?? [];

        // Garantir que seja lista de mapas
        comments =
            (rawComments as List)
                .map((c) => Map<String, dynamic>.from(c))
                .toList();

        setState(() => commentsLoaded = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar comentários')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar comentários: $e')),
      );
    }
  }

  /// Envia um novo comentário
  Future<void> _comment(String content) async {
    final postId = widget.post['id'];
    try {
      final token = await ApiService().getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/posts/comment/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': content}),
      );

      if (res.statusCode == 200) {
        setState(() => commentsLoaded = false); // Força recarregar comentários
        _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar comentário')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar comentário: $e')));
    }
  }

  /// Alterna like/deslike do post
  Future<void> _toggleLike() async {
    final token = await ApiService().getToken();
    final postId = widget.post['id'];

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/posts/$postId/toggle-like'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          liked = !liked;
          likeCount += liked ? 1 : -1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao curtir/descurtir: $e')));
    }
  }

  /// Deleta o post (somente se for do usuário atual)
  Future<void> _deletePost() async {
    final postId = widget.post['id'];
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao deletar post: $e')));
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
            // Header: nome do usuário + botão de deletar (se for próprio post)
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
            // Conteúdo do post
            Text(widget.post['content'] ?? ''),
            if (widget.post['file'] != null && widget.post['file'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(widget.post['file']),
              ),
            // Likes e botão de comentários
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
                  onPressed: () async {
                    await _loadComments();
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        final TextEditingController commentController =
                            TextEditingController();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Lista de comentários
                            if (comments.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: comments.length,
                                itemBuilder: (_, index) {
                                  final comment = comments[index];
                                  return ListTile(
                                    title: Text(comment['usuario'].toString()),
                                    subtitle: Text(comment['body'].toString()),
                                  );
                                },
                              ),
                            if (comments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Sem comentários ainda',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            // Campo para escrever novo comentário
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Escreva um comentário',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () {
                                      if (commentController.text.isNotEmpty) {
                                        _comment(commentController.text);
                                        commentController.clear();
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
            // Data de criação do post
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
