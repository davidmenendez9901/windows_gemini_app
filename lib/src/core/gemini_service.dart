import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../model/message.dart';

class GeminiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<String> sendPrompt(List<Message> messages, String model) async {
    if (_apiKey == null) {
      throw Exception('API Key no encontrada en el archivo .env');
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'contents': messages.map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'model',
          'parts': [
            {'text': msg.text}
          ]
        };
      }).toList(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse['candidates'] != null &&
            decodedResponse['candidates'].isNotEmpty) {
          return decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        }
        return 'No se recibió una respuesta válida del modelo.';
      } else {
        return 'Error: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      return 'Error al conectar con la API: $e';
    }
  }
} 