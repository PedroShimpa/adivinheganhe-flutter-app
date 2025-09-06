import 'package:flutter/services.dart';
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('adivinheganhe/deeplink');

  /// Inicializa listener para novos intents
  static void initListener(Function(Uri uri) onLinkReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'newIntent') {
        final String? link = call.arguments as String?;
        if (link != null) {
          final uri = Uri.parse(link);
          onLinkReceived(uri);
        }
      }
    });
  }

  /// Retorna deep link que abriu o app
  static Future<Uri?> getInitialLink() async {
    try {
      final String? link = await _channel.invokeMethod<String>(
        'getInitialLink',
      );
      if (link != null) return Uri.parse(link);
    } catch (e) {
    }
    return null;
  }
}