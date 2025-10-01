import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users/friend-requests'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          requests = jsonDecode(response.body)['peding_requests'] ?? [];
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar pedidos");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Future<void> handleAction(String action, int userId) async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final url = '${ApiService.baseUrl}/users/friend-request/$action/$userId';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          requests.removeWhere((r) => r['sender_id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Solicitação $action com sucesso")),
        );
      } else {
        throw Exception("Erro ao $action solicitação");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Widget _buildAvatar(dynamic user) {
    if (user['user_photo'] != null && user['user_photo'].isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(user['user_photo']),
      );
    } else {
      String initials = '';
      if (user['username'] != null && user['username'].isNotEmpty) {
        initials =
            user['username']
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
        title: const Text("Pedidos de Amizade"),
        backgroundColor: const Color(0xFF142B44),
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.white),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
              ? const Center(
                child: Text(
                  "Nenhum pedido de amizade",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final user = requests[index];
                  return Card(
                    color: const Color(0xFF1B2D4A),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: _buildAvatar(user),
                      title: Text(
                        user['username'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed:
                                () => handleAction("accept", user['sender_id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed:
                                () => handleAction("recuse", user['sender_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
