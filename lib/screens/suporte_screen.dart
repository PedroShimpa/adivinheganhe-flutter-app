import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class SuporteScreen extends StatefulWidget {
  const SuporteScreen({super.key});

  @override
  State<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends State<SuporteScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> chamados = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchChamados();
  }

  Future<void> fetchChamados() async {
    setState(() {
      loading = true;
    });
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/suporte/meus-chamados'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          chamados = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar chamados");
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Falha: ${e.toString()}")),
        );
      }
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'A':
        return 'Aguardando';
      case 'EA':
        return 'Em Atendimento';
      case 'F':
        return 'Finalizado';
      default:
        return 'Desconhecido';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'A':
        return Colors.orange;
      case 'EA':
        return Colors.blue;
      case 'F':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('Meus Chamados'),
        backgroundColor: const Color(0xFF142B44),
      ),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : chamados.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum chamado encontrado',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchChamados,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chamados.length,
                      itemBuilder: (context, index) {
                        final chamado = chamados[index];
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            title: Text(
                              'Chamado #${chamado['id']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chamado['categoria']?['descricao'] ?? 'N/A',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(chamado['status']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    getStatusText(chamado['status']),
                                    style: TextStyle(
                                      color: getStatusColor(chamado['status']),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SuporteChatScreen(chamado: chamado),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class SuporteChatScreen extends StatefulWidget {
  final Map<String, dynamic> chamado;

  const SuporteChatScreen({super.key, required this.chamado});

  @override
  State<SuporteChatScreen> createState() => _SuporteChatScreenState();
}

class _SuporteChatScreenState extends State<SuporteChatScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/suporte/${widget.chamado['id']}/chat/messages'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          messages = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar mensagens");
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Falha: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/suporte/${widget.chamado['id']}/chat/store'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        fetchMessages();
      } else {
        throw Exception("Erro ao enviar mensagem");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Falha: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text('Chamado #${widget.chamado['id']}'),
        backgroundColor: const Color(0xFF142B44),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['user_name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['message'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['created_at'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (widget.chamado['status'] != 'F')
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF142B44),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: sendMessage,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
