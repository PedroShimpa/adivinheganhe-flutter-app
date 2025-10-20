import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;

class ChatDetailScreen extends StatefulWidget {
  final String username;
  final String? avatar;

  const ChatDetailScreen({super.key, required this.username, this.avatar});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  Map<String, dynamic>? currentUser;
  int? receiverId;
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    loadUserAndMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadUserAndMessages() async {
    final u = await apiService.getUser();
    setState(() => currentUser = u);
    await fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chat/messages/${widget.username}'),
         headers: {"Authorization": "Bearer $token",  'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
          receiverId = data['receiver_id'];
          loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      } else {
        throw Exception("Erro ao carregar mensagens");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Future<void> sendMessage() async {
    if (_msgController.text.trim().isEmpty || receiverId == null) return;

    final msgText = _msgController.text.trim();
    _msgController.clear();

    setState(() {
      sending = true;
    });

    try {
      final token = await apiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/chat/new-message'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"message": msgText, "receiver_id": receiverId}),
      );

      if (response.statusCode != 200) {
        throw Exception("Erro ao enviar mensagem");

      }
      fetchMessages();

      // O Reverb enviará a mensagem automaticamente para os inscritos, então não precisa do WebSocketManager.
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    } finally {
      setState(() {
        sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.avatar != null ? NetworkImage(widget.avatar!) : null,
              child:
                  widget.avatar == null
                      ? Text(
                        widget.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Text(widget.username, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF142B44),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                loading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : messages.isEmpty
                    ? const Center(
                      child: Text(
                        "Nenhuma mensagem",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe =
                            currentUser != null &&
                            msg['user_id'] == currentUser!['id'];
                        final isVip = msg['is_vip'] == true;
                        final isAdmin = msg['is_admin'] == true;
                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isVip || isAdmin)
                                  Text(
                                    isAdmin ? 'ADMIN' : 'MEMBRO VIP',
                                    style: TextStyle(
                                      color: isAdmin ? Colors.red : Colors.yellow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  msg['mensagem'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF142B44),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Digite uma mensagem...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      sending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.send, color: Colors.white),
                  onPressed: sending ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
