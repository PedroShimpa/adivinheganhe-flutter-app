import 'package:adivinheganhe/widgets/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adivinheganhe/screens/edit_profile_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? currentUser; // usuário autenticado
  final VoidCallback? onLogout;

  const PerfilScreen({super.key, this.user, this.currentUser, this.onLogout});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  bool isFriend = false;
  bool loading = true;
  List posts = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFriendshipAndLoad();
  }

  Future<void> _checkFriendshipAndLoad() async {
    final userId = widget.user?['id'];
    final currentUserId = widget.currentUser?['id'];

    if (widget.user?['perfil_privado'] == 'S' && userId != currentUserId) {
      final res = await http.get(
        Uri.parse('https://adivinheganhe.com.br/api/meu-amigo/$userId'),
        headers: {'Authorization': 'Bearer ${widget.currentUser?['token']}'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          isFriend = data['isFriend'] ?? false;
          loading = false;
        });
      }
    } else {
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    final username = widget.user?['username'];
    final res = await http.get(
      Uri.parse('https://adivinheganhe.com.br/api/posts/$username'),
      headers: {'Authorization': 'Bearer ${widget.currentUser?['token']}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        posts = data['posts'] ?? [];
        loading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    final username = widget.user?['username'];
    await http.post(
      Uri.parse(
        'https://adivinheganhe.com.br/api/user/$username/enviar-pedido-de-amizade',
      ),
      headers: {'Authorization': 'Bearer ${widget.currentUser?['token']}'},
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pedido de amizade enviado!')));
  }

  Future<void> _createPost(String content) async {
    await http.post(
      Uri.parse('https://adivinheganhe.com.br/api/posts/store'),
      headers: {
        'Authorization': 'Bearer ${widget.currentUser?['token']}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'content': content}),
    );
    _loadPosts(); // recarrega posts
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final currentUser = widget.currentUser;
    final isOwnProfile = user?['id'] == currentUser?['id'];

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user?['name'] ?? ''),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Publicações'),
            Tab(text: 'Partidas Competitivas'),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 150,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user?['image'] ?? ''),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['username'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user?['perfil_privado'] != 'S' ||
                          isOwnProfile ||
                          isFriend)
                        Text(user?['bio'] ?? ''),
                    ],
                  ),
                ),
                if (!isOwnProfile &&
                    !(user?['perfil_privado'] == 'S' && !isFriend))
                  ElevatedButton(
                    onPressed: _sendFriendRequest,
                    child: const Text('Adicionar amigo'),
                  ),
                if (isOwnProfile)
                  ElevatedButton(
                    onPressed: () async {
                      // Navega para a tela de edição do perfil
                      final updatedUser = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  EditProfileScreen(currentUser: currentUser!),
                        ),
                      );
                      // Se retornou usuário atualizado, atualiza state
                      if (updatedUser != null) {
                        setState(() {
                          widget.user!.addAll(updatedUser);
                        });
                      }
                    },
                    child: const Text('Editar Perfil'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Publicações
                Column(
                  children: [
                    if (isOwnProfile)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PostInput(onSubmit: _createPost),
                      ),
                    Expanded(
                      child:
                          posts.isEmpty
                              ? const Center(child: Text('Nenhuma publicação'))
                              : ListView.builder(
                                itemCount: posts.length,
                                itemBuilder: (_, index) {
                                  final post = posts[index];
                                  return PostWidget(
                                    post: post,
                                    currentUser: currentUser!,
                                    onDeleted: () {
                                      _loadPosts();
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
                // Tab Partidas Competitivas
                const Center(
                  child: Text('Nenhuma partida competitiva por enquanto'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostInput extends StatefulWidget {
  final Function(String) onSubmit;
  const PostInput({super.key, required this.onSubmit});

  @override
  State<PostInput> createState() => _PostInputState();
}

class _PostInputState extends State<PostInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'O que você está pensando?',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSubmit(_controller.text);
              _controller.clear();
            }
          },
        ),
      ],
    );
  }
}
