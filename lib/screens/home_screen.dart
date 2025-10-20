import 'dart:convert';
import 'package:adivinheganhe/screens/conversas_screen.dart';
import 'package:adivinheganhe/screens/friends_screen.dart';
import 'package:adivinheganhe/screens/meus_premios_screen.dart';
import 'package:adivinheganhe/screens/perfil_screen.dart';
import 'package:adivinheganhe/screens/players_screen.dart';
import 'package:adivinheganhe/screens/suporte_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:adivinheganhe/widgets/adivinhacao_card_widget.dart';
import 'package:adivinheganhe/widgets/admob_banner_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isExpanded = false;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadExpandedState();
    fetchAdivinhacoes();

    // Check for extra data from login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is String && extra.startsWith('Bem-vindo')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extra)),
        );
      }
    });
  }

  Future<void> _loadUser() async {
    try {
      user = await apiService.getUser();
      username = user?['username'];
      _isVip = await apiService.isVip();
      setState(() {});
    } catch (e) {
      // print(e);
      logout();
    }
  }

  Future<void> _loadExpandedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isExpanded = prefs.getBool('isExpanded') ?? true;
      });
    } catch (e) {
      // Fallback to default if SharedPreferences fails
      setState(() {
        _isExpanded = true;
      });
    }
  }

  Future<void> _saveExpandedState(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isExpanded', value);
    } catch (e) {
      // Silently fail if SharedPreferences is not available
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir $url');
    }
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
          builder: (_) => AlertDialog(
            title: const Text("Notificações"),
            content: SizedBox(
              width: double.maxFinite,
              child: notifications.isEmpty
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Falha: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> fetchAdivinhacoes() async {
    setState(() {
      loading = true;
    });
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
        if (!mounted) return;
        setState(() {
          adivinhacoes = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar adivinhações");
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        logout();
      }
    }
  }

  Future<void> logout() async {
    await apiService.logout();
    await apiService.clearToken();
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
        Column(
          children: [
            // Expandable Container for Indication and WhatsApp
            ExpansionTile(
              title: const Text(
                'Promoções e Comunidade',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              initiallyExpanded: _isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isExpanded = expanded;
                });
                _saveExpandedState(expanded);
              },
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              children: [
                // Indication Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🎯 Indique e ganhe 5 palpites por adivinhador registrado em seu link',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(
                                  text: 'https://adivinheganhe.com.br/register?ib=${user?['uuid'] ?? ''}',
                                ),
                                readOnly: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final link = 'https://adivinheganhe.com.br/register?ib=${user?['uuid'] ?? ''}';
                                await Clipboard.setData(ClipboardData(text: link));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copiado!')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Copiar link'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // WhatsApp Community Alert
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Entre na nossa comunidade do WhatsApp!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _openUrl('https://whatsapp.com/channel/0029VbBcnEJ35fLpTurxDe33'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Participar agora'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RefreshIndicator(
                  onRefresh: fetchAdivinhacoes,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: adivinhacoes.length,
                    itemBuilder: (context, index) {
                      final jogo = adivinhacoes[index];
                      return AdivinhacaoCard(
                        adivinhacao: jogo,
                        index: index,
                        onResponder: (id, resposta, idx) => responder(id, resposta, idx),
                      );
                    },
                  ),
                ),
              ),
            ),
            // AdMob Banner
            if (!_isVip) ...[
              const SizedBox(height: 8),
              const AdmobBannerWidget(adUnitId: 'ca-app-pub-2128338486173774/2391858728'),
            ],
          ],
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
                leading: const Icon(Icons.emoji_events),
                title: const Text('Premiações'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/premiacoes');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Seja Membro'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/seja-membro');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Comprar Palpites'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/palpites/comprar');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Sobre'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/sobre');
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Suporte'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/suporte');
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Meus Chamados'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SuporteScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Adivinhações VIP'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/adivinhacoes-vip');
                },
              ),
              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('Ranking'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl('https://adivinheganhe.com.br/ranking-classico');
                },
              ),
              const Divider(),
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

      // Always show 'info' or 'error' if present
      if (data['info'] != null || data['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['info'] ?? data['error'])),
        );
      }

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
        // Additional handling for non-200 if needed, but 'info'/'error' already shown above
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
