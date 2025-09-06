// friends_screen.dart
import 'dart:convert';
import 'package:adivinheganhe/screens/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> friends = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/meus-amigos'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          friends = jsonDecode(response.body)['friends'] ?? [];
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar amigos");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Widget _buildAvatar(dynamic friend) {
    if (friend['user_photo'] != null && friend['user_photo'].isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(friend['user_photo']),
      );
    } else {
      String initials = '';
      if (friend['username'] != null && friend['username'].isNotEmpty) {
        initials =
            friend['username']
                .trim()
                .split(' ')
                .map((e) => e[0].toUpperCase())
                .take(2)
                .join();
      }
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.blueGrey,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text("Amigos"),
        backgroundColor: const Color(0xFF142B44),
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: () {
              context.push('/friend-requests');
            },
          ),
        ],
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : friends.isEmpty
              ? const Center(
                child: Text(
                  "Nenhum amigo encontrado",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return Card(
                    color: const Color(0xFF1B2D4A),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: _buildAvatar(friend),
                      title: Text(
                        friend['username'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: const Color(0xFF1B2D4A),
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'chat',
                                child: Text(
                                  'Conversar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'perfil',
                                child: Text(
                                  'Ver Perfil',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                        onSelected: (value) {
                          if (value == 'chat') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChatDetailScreen(
                                      username: friend['username'],
                                      avatar: friend['user_photo'],
                                    ),
                              ),
                            );
                          } else if (value == 'perfil') {
                            context.push('/perfil/${friend['username']}');
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
