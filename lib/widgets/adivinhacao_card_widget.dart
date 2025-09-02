import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_audio_widgets.dart'; // Importa VideoPlayerWidget e AudioPlayerWidget

class AdivinhacaoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final respostaController = TextEditingController();
    final palpites = adivinhacao['palpites_restantes'] ?? 0;
    final podeResponder = palpites > 0;

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

    return Card(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (adivinhacao['imagem'] != null) buildMedia(adivinhacao['imagem']),
          const SizedBox(height: 12),
          Text(
            adivinhacao['titulo'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
          ),
          const SizedBox(height: 8),
          Html(
            data: adivinhacao['descricao'] ?? '',
            style: {
              "body": Style(color: Colors.black, fontSize: FontSize(16.0)),
            },
          ),
          const SizedBox(height: 8),
          Text(
            "Prêmio: ${adivinhacao['premio'] ?? 'Nenhum'}",
            style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
          ),
          Text(
            "Expira em: ${adivinhacao['expire_at_br'] ?? 'Sem data'}",
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
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
              hintText: podeResponder ? "Digite sua resposta..." : "Você não tem mais palpites hoje",
              hintStyle: TextStyle(
                color: Colors.black45,
                fontStyle: podeResponder ? FontStyle.normal : FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: podeResponder ? const Color(0xFF0D1B2A) : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: podeResponder
                  ? () => onResponder(adivinhacao['id'], respostaController.text, index)
                  : null,
              child: const Text("Responder"),
            ),
          ),
        ]),
      ),
    );
  }
}
