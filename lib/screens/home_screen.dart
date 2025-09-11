import 'dart:convert';
import 'package:adivinheganhe/screens/conversas_screen.dart';
import 'package:adivinheganhe/screens/friends_screen.dart';
import 'package:adivinheganhe/screens/meus_premios_screen.dart';
import 'package:adivinheganhe/screens/perfil_screen.dart';
import 'package:adivinheganhe/screens/players_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:adivinheganhe/widgets/adivinhacao_card_widget.dart';
import '../services/api_service.dart';

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

  Future<void> _showNotifications() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notificacoes'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = data['notifications'] as List<dynamic>;

        if (!mounted) return;

        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Notificações"),
                content: SizedBox(
                  width: double.maxFinite,
                  child:
                      notifications.isEmpty
                          ? const Text("Nenhuma notificação")
                          : ListView.builder(
                            shrinkWrap: true,
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final n = notifications[index];
                              return ListTile(
                                title: Text(
                                  n['data']['message'] ?? 'Nova notificação',
                                ),
                                subtitle: Text(n['created_at_br'] ?? ''),
                              );
                            },
                          ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fechar"),
                  ),
                ],
              ),
        );
      } else {
        throw Exception("Erro ao buscar notificações");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  Future<void> fetchAdivinhacoes() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/adivinhacoes/index'),
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
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
    // 1. Chama o endpoint de logout no backend (se houver)
    await apiService.logout();

    // 2. Limpa localmente o token e o usuário
    await apiService.clearToken();

    // 3. Redireciona para login usando GoRouter
    if (mounted) context.go('/login');
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return IndexedStack(
      index: _selectedIndex,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
        PerfilScreen(username: username ?? '', onLogout: logout),
      ],
    );
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
                  _onNavTapped(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Amigos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Jogadores'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayersScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Conversas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConversasScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('Meus Prêmios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MeusPremiosScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  Navigator.pop(context);
                  await logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF142B44),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            _scaffoldKey.currentState?.openEndDrawer(); // Mais
          } else if (index == 1) {
            _showNotifications(); // Notificações
          } else {
            _onNavTapped(index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad, color: Colors.white),
            label: 'Clássico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.white),
            label: 'Notificações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, color: Colors.white),
            label: 'Mais',
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
            builder:
                (_) => AlertDialog(
                  title: const Text("Parabéns!"),
                  content: const Text(
                    "Você acertou! Em breve nossos administradores entrarão em contato.",
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
                "Resposta incorreta! Palpites restantes: ${data['trys']}",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${data['info'] ?? response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
