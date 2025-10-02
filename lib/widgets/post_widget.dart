import 'package:flutter/material.dart';
import 'package:adivinheganhe/models/comment.dart';
import 'package:adivinheganhe/services/post_service.dart';

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
  List<Comment> comments = [];
  bool liked = false;
  int likeCount = 0;
  bool commentsLoaded = false;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes_count'] ?? 0;
    liked = widget.post['liked_by_user'] ?? false;
  }

  Future<void> _loadComments() async {
    if (commentsLoaded) return;
    try {
      final loadedComments = await _postService.loadComments(widget.post['id']);
      setState(() {
        comments = loadedComments;
        commentsLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar comentários: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _postService.toggleLike(widget.post['id']);
      setState(() {
        liked = !liked;
        likeCount += liked ? 1 : -1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao curtir/descurtir: $e')),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    try {
      await _postService.deletePost(widget.post['id']);
      if (widget.onDeleted != null) widget.onDeleted!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deletado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar post: $e')),
        );
      }
    }
  }
  Future<void> _abrirComentariosModal() async {
    await _loadComments();
    if (!mounted) return;
    final comentarioController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctxModal, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Comentários",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (!commentsLoaded)
                const Center(child: CircularProgressIndicator())
              else if (comments.isEmpty)
                const Text("Nenhum comentário ainda.")
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (ctx, i) {
                      final c = comments[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: c.userPhoto != null
                              ? NetworkImage(c.userPhoto!)
                              : null,
                          child: c.userPhoto == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(c.usuario),
                        subtitle: Text(c.body),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: comentarioController,
                      decoration: const InputDecoration(
                        hintText: "Adicionar comentário...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final body = comentarioController.text.trim();
                      if (body.isEmpty) return;
                      try {
                        await _postService.addComment(widget.post['id'], body);
                        comentarioController.clear();
                        // Reload comments
                        setState(() => commentsLoaded = false);
                        await _loadComments();
                        setModalState(() {});
                      } catch (e) {
                        // Error handled in service
                      }
                    },
                    child: const Text("Enviar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isOwnPost = widget.post['user_id'] == widget.currentUser['id'];
    final createdAt = DateTime.parse(widget.post['created_at']);
    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.post['user_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isOwnPost) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deletePost),
            ],
          ),
          Text(widget.post['content'] ?? ''),
          if (widget.post['file'] != null && widget.post['file'].isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Image.network(widget.post['file'])),
          Row(
            children: [
              IconButton(
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
                onPressed: _toggleLike,
              ),
              Text('$likeCount likes'),
              const Spacer(),
              IconButton(icon: const Icon(Icons.comment), onPressed: _abrirComentariosModal),
            ],
          ),
          Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}
