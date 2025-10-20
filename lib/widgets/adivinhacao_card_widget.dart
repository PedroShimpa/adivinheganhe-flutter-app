import 'package:adivinheganhe/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'video_audio_widgets.dart';

class AdivinhacaoCard extends StatefulWidget {
  final Map<String, dynamic> adivinhacao;
  final int index;
  final void Function(int id, String resposta, int index) onResponder;

  const AdivinhacaoCard({
    super.key,
    required this.adivinhacao,
    required this.index,
    required this.onResponder,
  });

  @override
  State<AdivinhacaoCard> createState() => _AdivinhacaoCardState();
}

class _AdivinhacaoCardState extends State<AdivinhacaoCard>
    with AutomaticKeepAliveClientMixin {
  final respostaController = TextEditingController();
  final apiUrl = ApiService.baseUrl;
  late ValueNotifier<int> likes;
  late ValueNotifier<bool> liked;
  List<dynamic> comentarios = [];
  bool loadingComentarios = false;
  bool mediaInitialized = false;
  bool isVip = false;

  @override
  void initState() {
    super.initState();
    likes = ValueNotifier(widget.adivinhacao['likes_count'] ?? 0);
    liked = ValueNotifier(widget.adivinhacao['liked'] ?? false);
    _checkVipStatus();
  }

  Future<void> _checkVipStatus() async {
    try {
      isVip = await ApiService().isVip();
      setState(() {});
    } catch (_) {
      // Default to false if error
    }
  }

  Future<void> _carregarComentarios() async {
    try {
      setState(() => loadingComentarios = true);
      final uuid = widget.adivinhacao['uuid'];
      var token = await ApiService().getToken();

      final resp = await http.get(
        Uri.parse("$apiUrl/adivinhacao/$uuid/comentarios"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        comentarios = data is List ? data : (data ?? []);
      }
    } catch (_) {
    } finally {
      setState(() => loadingComentarios = false);
    }
  }

  Future<void> _toogleLike() async {
    try {
      final uuid = widget.adivinhacao['uuid'];
      final token = await ApiService().getToken();
      final resp = await http.post(
        Uri.parse("$apiUrl/adivinhacao/$uuid/toogle-like"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        likes.value = data['likes_count'] ?? likes.value;
        liked.value = data['liked'] ?? liked.value;
      }
    } catch (_) {}
  }

Future<void> _abrirComentariosModal() async {
  await _carregarComentarios();
  if (!mounted) return;
  final comentarioController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctxModal, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Comentários",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (loadingComentarios)
              const Center(child: CircularProgressIndicator())
            else if (comentarios.isEmpty)
              const Text("Nenhum comentário ainda.")
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: comentarios.length,
                  itemBuilder: (ctx, i) {
                    final c = comentarios[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: c['user_photo'] != null
                            ? NetworkImage(c['user_photo'])
                            : null,
                        child: c['user_photo'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(c['usuario'] ?? 'Anônimo'),
                      subtitle: Text(c['body'] ?? ''),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: comentarioController,
                    decoration: const InputDecoration(
                      hintText: "Adicionar comentário...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final body = comentarioController.text.trim();
                    if (body.isEmpty) return;
                    final uuid = widget.adivinhacao['uuid'];
                    final token = await ApiService().getToken();
                    try {
                      final resp = await http.post(
                        Uri.parse("$apiUrl/adivinhacao/$uuid/comentar"),
                        headers: {
                          "Authorization": "Bearer $token",
                          "Content-Type": "application/json",
                        },
                        body: json.encode({"body": body}),
                      );
                      if (resp.statusCode == 200 || resp.statusCode == 201) {
                        comentarioController.clear();
                        setModalState(() => loadingComentarios = true);
                        await _carregarComentarios();
                        setModalState(() => loadingComentarios = false);
                      }
                    } catch (_) {}
                  },
                  child: const Text("Enviar"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget buildMedia(String? url) {
    if (url == null) return const SizedBox.shrink();
    final lower = url.toLowerCase();
    if (lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".png") ||
        lower.endsWith(".webp") ||
        lower.endsWith(".gif")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if ((lower.endsWith(".mp4") ||
            lower.endsWith(".mov") ||
            lower.endsWith(".webm")) &&
        mediaInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoPlayerWidget(url: url),
      );
    } else if ((lower.endsWith(".mp3") ||
            lower.endsWith(".wav") ||
            lower.endsWith(".ogg")) &&
        mediaInitialized) {
      return AudioPlayerWidget(url: url);
    } else {
      return TextButton(
        onPressed: () => setState(() => mediaInitialized = true),
        child: const Text(
          "Carregar mídia",
          style: TextStyle(color: Colors.blueAccent),
        ),
      );
    }
  }

  Widget buildPremio() {
    final premio = widget.adivinhacao['premio'];
    if (premio == null ||
        premio.isEmpty ||
        !premio.toString().startsWith("http")) {
      return const SizedBox.shrink();
    }
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      icon: const Icon(Icons.card_giftcard),
      label: const Text("Abrir Prêmio"),
      onPressed: () async {
        final uri = Uri.parse(premio);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final palpites = widget.adivinhacao['palpites_restantes'] ?? 0;
    final podeResponder = palpites > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.adivinhacao['imagem'] != null)
              buildMedia(widget.adivinhacao['imagem']),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.adivinhacao['titulo'] ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.adivinhacao['only_members'] == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'VIP',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Html(data: widget.adivinhacao['descricao'] ?? ''),
            const SizedBox(height: 8),
            if (widget.adivinhacao['dificuldade'] != null)
              Text(
                "Dificuldade: ${widget.adivinhacao['dificuldade']}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            if (widget.adivinhacao['vip_release_at'] != null)
              Text(
                "Liberado para VIPs em: ${widget.adivinhacao['vip_release_at']}",
                style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.w500),
              ),
            if (widget.adivinhacao['only_members'] == true)
              const Text(
                "Apenas para membros VIP",
                style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 8),
            buildPremio(),
            if(widget.adivinhacao['expire_at_br'] != null)
            Text(
              "Expira em: ${widget.adivinhacao['expire_at_br']}",
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            // Check if adivinhacao is VIP-only or released to VIPs first and user is not VIP
            if ((widget.adivinhacao['only_members'] == 1 || (widget.adivinhacao['vip_release_at'] != null && DateTime.now().isBefore(DateTime.parse(widget.adivinhacao['vip_release_at'])))) && !isVip)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Apenas membros VIP podem responder a esta adivinhação.",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    "Palpites restantes: $palpites",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: podeResponder ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: respostaController,
                    enabled: podeResponder,
                    decoration: InputDecoration(
                      hintText:
                          podeResponder
                              ? "Digite sua resposta..."
                              : "Sem palpites hoje",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          podeResponder ? const Color(0xFF0A2540) : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 24,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed:
                        podeResponder
                            ? () => widget.onResponder(
                              widget.adivinhacao['id'],
                              respostaController.text,
                              widget.index,
                            )
                            : null,
                    child: const Text("Responder"),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.comment),
                  label: Text("Comentários"),
                  onPressed: _abrirComentariosModal,
                ),
                ValueListenableBuilder(
                  valueListenable: likes,
                  builder:
                      (context, int l, _) => ValueListenableBuilder(
                        valueListenable: liked,
                        builder:
                            (context, bool isLiked, _) => OutlinedButton.icon(
                              icon: Icon(
                                isLiked
                                    ? Icons.thumb_up_alt
                                    : Icons.thumb_up_outlined,
                                color:
                                    isLiked
                                        ? Colors.deepOrange
                                        : Colors.black54,
                              ),
                              label: Text("$l Curtidas"),
                              onPressed: _toogleLike,
                            ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
