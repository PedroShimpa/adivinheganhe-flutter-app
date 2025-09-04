import 'dart:convert';
import 'package:adivinheganhe/widgets/adivinhacao_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> adivinhacoes = [];
  bool loading = true;
  int _selectedIndex = 0;
  Map<String, dynamic>? user;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUser();
    fetchAdivinhacoes();
  }

  Future<void> _loadUser() async {
    user = await apiService.getUser();
    username = user?['username'];
    setState(() {});
  }

  Future<void> fetchAdivinhacoes() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Future<void> logout() async {
    await apiService.clearToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D1B2A),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  _onNavTapped(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: adivinhacoes.length,
                      itemBuilder: (context, index) {
                        final jogo = adivinhacoes[index];
                        return AdivinhacaoCard(
                          adivinhacao: jogo,
                          index: index,
                          onResponder: (id, resposta, idx) =>
                              responder(id, resposta, idx),
                        );
                      },
                    ),
                  ),
            const Center(
              child: Text(
                "Modo Online",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            if (username != null)
              PerfilScreen(username: username!, currentUser: user, onLogout: logout)
            else
              const Center(
                child: Text(
                  "Faça login para ver o perfil",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF142B44),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            _scaffoldKey.currentState?.openEndDrawer();
          } else {
            _onNavTapped(index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Clássico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.online_prediction, color: Colors.white),
            label: 'Online',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, color: Colors.white),
            label: '',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
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
            builder: (_) => AlertDialog(
              title: const Text("Parabéns!"),
              content: const Text(
                  "Você acertou! Em breve nossos adivinistradores entrarão em contato."),
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
              content:
                  Text("Resposta registrada! Palpites restantes: ${data['trys']}"),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${data['info'] ?? response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }
}
