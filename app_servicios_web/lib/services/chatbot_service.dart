import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Cliente mínimo del chatbot Laravel (BotMan web driver en `/chatbot`).
///
/// El endpoint vive **fuera** de `/api` (ruta web). Se deriva el origin
/// quitando el sufijo `/api` de [ApiService.baseUrl].
class ChatbotService {
  /// Origin del backend, p.ej. `http://127.0.0.1:8000`.
  static String get originUrl {
    final api = ApiService.baseUrl;
    if (api.endsWith('/api')) {
      return api.substring(0, api.length - 4);
    }
    return api;
  }

  static Uri get chatbotUri => Uri.parse('$originUrl/chatbot');

  /// Envía [text] al bot y devuelve los textos de respuesta.
  ///
  /// Lanza [ChatbotException] en error de red o respuesta inválida.
  Future<List<String>> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ChatbotException('Escribe un mensaje.');
    }

    late final http.Response response;
    try {
      response = await http
          .post(
            chatbotUri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            // Formato documentado en ChatbotController (OpenAPI) + WebDriver.
            body: jsonEncode({
              'driver': 'web',
              'userId': 'flutter-web',
              'message': trimmed,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ChatbotException(
        'No se pudo contactar al servidor ($originUrl). ¿Laravel está en marcha?',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatbotException(
        'Error del servidor (${response.statusCode}). Intenta de nuevo.',
      );
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw ChatbotException('Respuesta inválida del chatbot.');
    }

    final texts = <String>[];

    // Formato BotMan web: { status, messages: [ { type, text } ] }
    if (data is Map && data['messages'] is List) {
      for (final m in data['messages'] as List) {
        if (m is Map && m['text'] != null) {
          final t = m['text'].toString().trim();
          if (t.isNotEmpty) texts.add(t);
        }
      }
    }

    // Fallback por si el backend devolviera un string plano.
    if (texts.isEmpty && data is Map && data['message'] != null) {
      final t = data['message'].toString().trim();
      if (t.isNotEmpty) texts.add(t);
    }

    if (texts.isEmpty) {
      throw ChatbotException('El bot no devolvió mensajes.');
    }

    return texts;
  }
}

class ChatbotException implements Exception {
  ChatbotException(this.message);
  final String message;

  @override
  String toString() => message;
}
