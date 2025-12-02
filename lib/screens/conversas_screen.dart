import 'dart:convert';
import 'package:adivinheganhe/screens/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:adivinheganhe/widgets/admob_native_advanced_widget.dart';

class ConversasScreen extends StatefulWidget {
  const ConversasScreen({super.key});

  @override
  State<ConversasScreen> createState() => _ConversasScreenState();
}

class _ConversasScreenState extends State<ConversasScreen> {
  final ApiService apiService = ApiService();
  bool loading = true;
  List<dynamic> chats = [];
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _loadVipStatus();
    fetchChats();
  }

  Future<void> _loadVipStatus() async {
    final isVip = await apiService.isVip();
    setState(() {
      _isVip = isVip;
    });
  }

  Future<void> fetchChats() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chats'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          chats = jsonDecode(response.body)['chats'];
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar conversas");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Widget _buildUnreadBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text("Conversas", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF142B44),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : chats.isEmpty
                ? const Center(
                  child: Text(
                    "Nenhuma conversa encontrada",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
                : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final String username = chat['username'] ?? 'Usuário';
                    final String ultimaMensagem =
                        chat['ultima_mensagem'] ?? 'Sem mensagens';
                    final int naoLidas = chat['nao_lidas'] ?? 0;
                    final String? avatar = chat['avatar'];

                    return Card(
                      color: const Color(0xFF142B44),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child:
                              avatar == null
                                  ? Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  )
                                  : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          ultimaMensagem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: _buildUnreadBadge(naoLidas),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatDetailScreen(
                                    username: username,
                                    avatar: avatar,
                                  ),
                            ),
                          );
                        },
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
