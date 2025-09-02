import 'dart:convert';
import 'package:adivinheganhe/widgets/adivinhacao_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final bool loggedIn;
  final String? userName;
  const HomeScreen({super.key, this.loggedIn = false, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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
        Uri.parse('${ApiService.baseUrl}/adivinhacoes'),
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
        title: Text("Bem-vindo, ${widget.userName ?? 'Usuário'}"),
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
          // ------------------ ABA HOME ------------------
          loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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

          // ------------------ ABA PERFIL ------------------
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_circle, size: 120, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    widget.userName ?? 'Usuário',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1B2A),
    );
  }

  // ---------- Funções auxiliares (responder, buildMedia, etc.) ----------
  Widget buildMedia(String? url) {
    if (url == null) return const SizedBox.shrink();
    final lower = url.toLowerCase();
    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png") || lower.endsWith(".webp") || lower.endsWith(".gif")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(url, height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (lower.endsWith(".mp4") || lower.endsWith(".mov") || lower.endsWith(".webm")) {
      return AspectRatio(aspectRatio: 16 / 9, child: VideoPlayerWidget(url: url));
    } else if (lower.endsWith(".mp3") || lower.endsWith(".wav") || lower.endsWith(".ogg")) {
      return AudioPlayerWidget(url: url);
    } else if (lower.endsWith(".pdf")) {
      return ElevatedButton.icon(
        onPressed: () => launchUrl(Uri.parse(url)),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Abrir PDF"),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<void> responder(int adivinhacaoId, String resposta, int index) async {
    if (resposta.trim().isEmpty) return;
    try {
      final token = await apiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adivinhacoes/responder'),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        body: jsonEncode({"adivinhacao_id": adivinhacaoId, "resposta": resposta}),
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
              content: const Text("Você acertou! Em breve nossos adivinistradores entrarão em contato."),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Resposta registrada! Palpites restantes: ${data['trys']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${data['info'] ?? response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Falha: ${e.toString()}")));
    }
  }
}

// ------------------- WIDGETS DE MÍDIA (Video, Audio, PDF) -------------------
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)..initialize().then((_) => setState(() {}));
    _chewieController = ChewieController(videoPlayerController: _controller, autoPlay: false, looping: false);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_controller.value.isInitialized
      ? const Center(child: CircularProgressIndicator())
      : ClipRRect(borderRadius: BorderRadius.circular(16), child: Chewie(controller: _chewieController!));
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  const AudioPlayerWidget({super.key, required this.url});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.url);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (isPlaying) {
                await _player.pause();
              } else {
                await _player.play();
              }
              setState(() => isPlaying = !isPlaying);
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                return LinearProgressIndicator(
                  value: _player.duration != null && _player.duration!.inMilliseconds > 0
                      ? pos.inMilliseconds / _player.duration!.inMilliseconds
                      : 0,
                  color: Colors.blue,
                  backgroundColor: Colors.grey[300],
                );
              },
            ),
          ),
        ],
      );
}
