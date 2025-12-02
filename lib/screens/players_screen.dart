import 'dart:convert';
import 'package:adivinheganhe/screens/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'package:adivinheganhe/widgets/admob_native_advanced_widget.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> players = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _loadVipStatus();
    fetchPlayers();
  }

  Future<void> _loadVipStatus() async {
    final isVip = await apiService.isVip();
    setState(() {
      _isVip = isVip;
    });
  }

  Future<void> fetchPlayers({String search = ""}) async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final uri = Uri.parse(
        '${ApiService.baseUrl}/jogadores/index${search.isNotEmpty ? "?search=$search" : ""}',
      );

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          players = jsonDecode(response.body)['players'] ?? [];
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar jogadores");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Widget _buildAvatar(dynamic player) {
    if (player['user_photo'] != null && player['user_photo'].isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(player['user_photo']),
      );
    } else {
      String initials = '';
      if (player['username'] != null && player['username'].isNotEmpty) {
        initials = player['username']
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
        title: const Text("Jogadores"),
        backgroundColor: const Color(0xFF142B44),
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar jogador...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1B2D4A),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = "";
                      loading = true;
                    });
                    fetchPlayers();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  searchQuery = value.trim();
                  loading = true;
                });
                fetchPlayers(search: searchQuery);
              },
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : players.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum jogador encontrado",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (searchQuery.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Algum de nossos jogadores:",
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          return Card(
                            color: const Color(0xFF1B2D4A),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: _buildAvatar(player),
                              title: Text(
                                player['username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white),
                                color: const Color(0xFF1B2D4A),
                                itemBuilder: (context) => [
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
                                        builder: (_) => ChatDetailScreen(
                                          username: player['username'],
                                          avatar: player['user_photo'],
                                        ),
                                      ),
                                    );
                                  } else if (value == 'perfil') {
                                    context.push(
                                        '/perfil/${player['username']}');
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (!_isVip) ...[
                      const AdmobNativeAdvancedWidget(adUnitId: 'ca-app-pub-2128338486173774/5795614167'),
                    ],
                  ],
                ),
    );
  }
}
