import 'package:adivinheganhe/services/api_service.dart';
import 'package:adivinheganhe/widgets/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adivinheganhe/screens/edit_profile_screen.dart';

class PerfilScreen extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onLogout;

  const PerfilScreen({
    super.key,
    required this.username,
    this.currentUser,
    this.onLogout,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  bool loading = true;
  Map<String, dynamic>? user;
  List posts = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await apiService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/${widget.username}'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final u = data['user'];
        setState(() {
          user = u;
          posts = u['posts'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Exceção em _loadUser: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _sendFriendRequest() async {
    final token = await apiService.getToken();
    await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/user/${user?['username']}/enviar-pedido-de-amizade',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pedido de amizade enviado!')));
  }

  Future<void> _createPost(String content) async {
    final token = await apiService.getToken();
    await http.post(
      Uri.parse('${ApiService.baseUrl}/posts/store'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({'content': content}),
    );
    _loadUser(); // recarrega o user (com posts novos)
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.currentUser;
    final isOwnProfile = user?['id'] == currentUser?['id'];

    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: Text(
            "Usuário não encontrado",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B44),
        title: Text(
          user?['username'] ?? '',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white, // texto da aba selecionada
          unselectedLabelColor: Colors.white70, // texto das não selecionadas
          tabs: const [Tab(text: 'Publicações'), Tab(text: 'Partidas')],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF142B44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[700],
                  backgroundImage:
                      (user?['image'] != null && user!['image'] != '')
                          ? NetworkImage(user!['image'])
                          : null,
                  child:
                      (user?['image'] == null || user!['image'] == '')
                          ? Text(
                            user?['username'] != null &&
                                    user!['username'].isNotEmpty
                                ? user!['username'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['username'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (user?['perfil_privado'] != 'S' ||
                          isOwnProfile ||
                          user?['isFriend'] == true)
                        Text(
                          user?['bio'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!isOwnProfile &&
                              !(user?['perfil_privado'] == 'S' &&
                                  user?['isFriend'] != true))
                            ElevatedButton(
                              onPressed:
                                  user?['friendRequested'] == true
                                      ? null
                                      : _sendFriendRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                user?['friendRequested'] == true
                                    ? 'Solicitado'
                                    : 'Adicionar amigo',
                              ),
                            ),
                          if (isOwnProfile)
                            ElevatedButton(
                              onPressed: () async {
                                final updatedUser = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditProfileScreen(
                                          currentUser: currentUser!,
                                        ),
                                  ),
                                );
                                if (updatedUser != null) {
                                  setState(() {
                                    user!.addAll(updatedUser);
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Editar Perfil'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Publicações
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
                              ? const Center(
                                child: Text(
                                  'Nenhuma publicação',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: posts.length,
                                itemBuilder: (_, index) {
                                  final post = posts[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: PostWidget(
                                      post: post,
                                      currentUser: currentUser!,
                                      onDeleted: _loadUser,
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
                // Partidas
                const Center(
                  child: Text(
                    'Nenhuma partida competitiva por enquanto',
                    style: TextStyle(color: Colors.white70),
                  ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142B44),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'O que você está pensando?',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                widget.onSubmit(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
