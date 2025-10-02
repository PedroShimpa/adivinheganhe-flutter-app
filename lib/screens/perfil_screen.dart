import 'dart:io';

import 'package:adivinheganhe/services/api_service.dart';
import 'package:adivinheganhe/widgets/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adivinheganhe/screens/edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:adivinheganhe/widgets/admob_banner_widget.dart';

class PerfilScreen extends StatefulWidget {
  final String username;
  final VoidCallback? onLogout;

  const PerfilScreen({super.key, required this.username, this.onLogout});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? currentUser;
  bool loading = true;
  Map<String, dynamic>? user;
  List posts = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await apiService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/${widget.username}'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      try {
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final u = data['user'];
          setState(() {
            user = u;
            posts = u['posts'] ?? [];
          });
        }
      } finally {
        setState(() => loading = false);
      }
    } catch (e) {
      widget.onLogout;
    }
  }

  Future<void> _sendFriendRequest() async {
    final token = await apiService.getToken();
    await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/user/${user?['username']}/enviar-pedido-de-amizade',
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pedido de amizade enviado!')));
  }

  Future<void> _loadCurrentUser() async {
    final u = await apiService.getUser(); // pega do storage
    setState(() {
      currentUser = u;
    });
  }

  Future<void> _createPost(String content, [String? filePath]) async {
    final token = await apiService.getToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/posts/store'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['content'] = content;

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      _loadUser(); // recarrega os posts
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erro ao criar post")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: widget.onLogout,
            ),
        ],
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
                        )
                      else if (user?['isFriend'] != true)
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
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
                                child:
                                    currentUser == null
                                        ? const SizedBox.shrink()
                                        : PostWidget(
                                          post: post,
                                          currentUser: currentUser!,
                                          onDeleted: _loadUser,
                                        ),
                              );
                            },
                          ),
                ),
                const AdmobBannerWidget(adUnitId: 'ca-app-pub-2128338486173774/2391858728'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostInput extends StatefulWidget {
  final Function(String, [String?]) onSubmit;
  const PostInput({super.key, required this.onSubmit});

  @override
  State<PostInput> createState() => _PostInputState();
}

class _PostInputState extends State<PostInput> {
  final TextEditingController _controller = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void _submit() {
    if (_controller.text.isNotEmpty || _selectedImage != null) {
      widget.onSubmit(_controller.text, _selectedImage?.path);
      _controller.clear();
      setState(() => _selectedImage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => _selectedImage = null),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF142B44),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image, color: Colors.white),
                onPressed: _pickImage,
              ),
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
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
