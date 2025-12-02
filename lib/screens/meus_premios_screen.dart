import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:adivinheganhe/services/api_service.dart';
import 'package:adivinheganhe/widgets/admob_native_advanced_widget.dart';

class MeusPremiosScreen extends StatefulWidget {
  const MeusPremiosScreen({super.key});

  @override
  State<MeusPremiosScreen> createState() => _MeusPremiosScreenState();
}

class _MeusPremiosScreenState extends State<MeusPremiosScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> premios = [];
  bool loading = true;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _loadVipStatus();
    fetchPremios();
  }

  Future<void> _loadVipStatus() async {
    final isVip = await apiService.isVip();
    setState(() {
      _isVip = isVip;
    });
  }

  Future<void> fetchPremios() async {
    try {
      final token = await apiService.getToken();
      if (token == null) throw Exception("Token não encontrado");

      final uri = Uri.parse('${ApiService.baseUrl}/meus-premios');

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );

print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          premios = jsonDecode(response.body)['meus_premios'] ?? [];
          loading = false;
        });
      } else {
        throw Exception("Erro ao carregar prêmios");
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text("Meus Prêmios"),
        backgroundColor: const Color(0xFF142B44),
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : premios.isEmpty
                    ? const Center(
                        child: Text(
                          "Você ainda não tem prêmios",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: premios.length,
                        itemBuilder: (context, index) {
                          final premio = premios[index];
                          return Card(
                            color: const Color(0xFF1B2D4A),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                premio['titulo'] ?? 'Sem título',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Prêmio: ${premio['premio'] ?? '-'}\n"
                                "Enviado: ${premio['premio_enviado'] == 1 ? "Sim" : "Não"}",
                                style: const TextStyle(color: Colors.white70),
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
