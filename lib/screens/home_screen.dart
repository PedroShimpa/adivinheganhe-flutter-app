import 'dart:convert';
import 'package:adivinheganhe/widgets/adivinhacao_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool loggedIn;
  // ignore: prefer_typing_uninitialized_variables
  final user;
  final String? username;
  const HomeScreen({super.key, this.loggedIn = false, this.username, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  List<dynamic> adivinhacoes = [];
  bool loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.loggedIn) fetchAdivinhacoes();
  }

  Future<void> fetchAdivinhacoes() async {
    try {
      final token = await apiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/adivinhacoes/index'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() {
          adivinhacoes = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar adivinhações");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Future<void> logout() async {
    await apiService.clearToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loggedIn) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: Text(
            "Faça login para ver as adivinhações",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Bem-vindo, ${widget.username ?? 'Usuário'}"),
        backgroundColor: const Color(0xFF142B44),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: "Home"),
            Tab(icon: Icon(Icons.person), text: "Perfil"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: adivinhacoes.length,
                itemBuilder: (context, index) {
                  final jogo = adivinhacoes[index];
                  return AdivinhacaoCard(
                    adivinhacao: jogo,
                    index: index,
                    onResponder:
                        (id, resposta, idx) => responder(id, resposta, idx),
                  );
                },
              ),

          // ------------------ ABA PERFIL ------------------
          PerfilScreen(
            user:widget.user,
            onLogout: logout,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1B2A),
    );
  }

  Future<void> responder(int adivinhacaoId, String resposta, int index) async {
    if (resposta.trim().isEmpty) return;
    try {
      final token = await apiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adivinhacao/responder'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "adivinhacao_id": adivinhacaoId,
          "resposta": resposta,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          adivinhacoes[index]['palpites_restantes'] = data['trys'];
        });
        if (data['message'] == 'acertou') {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Parabéns!"),
                  content: const Text(
                    "Você acertou! Em breve nossos adivinistradores entrarão em contato.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Resposta registrada! Palpites restantes: ${data['trys']}",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${data['info'] ?? response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }
}
