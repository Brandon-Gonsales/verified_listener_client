import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telegram_message.dart';

class TelegramService {
  static const String _baseUrl = 'https://api.telegram.org/bot';

  // Resultado de la operación
  static Future<TelegramResult> sendMessage(TelegramMessage message) async {
    try {
      if (!message.isValid) {
        return TelegramResult.error('Todos los campos son obligatorios');
      }

      final String url = '$_baseUrl${message.token}/sendMessage';
      final requestBody = message.toJson();

      // Debug logging
      print('🔍 URL: $url');
      print('🔍 Request Body: ${jsonEncode(requestBody)}');
      print(
          '🔍 Chat ID: "${message.chatId}" (length: ${message.chatId.length})');
      print(
          '🔍 Token: "${message.token.substring(0, 10)}..." (length: ${message.token.length})');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['ok'] == true) {
          return TelegramResult.success('Mensaje enviado exitosamente');
        } else {
          return TelegramResult.error(
              'Error Telegram: ${responseData['description'] ?? 'Error desconocido'}');
        }
      } else {
        // Para error 400, intentemos obtener más detalles
        try {
          final errorData = jsonDecode(response.body);
          return TelegramResult.error(
              'Error ${response.statusCode}: ${errorData['description'] ?? response.body}');
        } catch (e) {
          return TelegramResult.error(
              'Error HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      return TelegramResult.error('Error de conexión: $e');
    }
  }

  // Método para validar el token (opcional)
  static Future<TelegramResult> validateBot(String token) async {
    try {
      final String url = '$_baseUrl$token/getMe';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['ok'] == true) {
          final botName = responseData['result']['username'];
          return TelegramResult.success('Bot válido: @$botName');
        } else {
          return TelegramResult.error('Token inválido');
        }
      } else {
        return TelegramResult.error('Error al validar el token');
      }
    } catch (e) {
      return TelegramResult.error('Error de conexión: $e');
    }
  }
}

// Clase para manejar los resultados de las operaciones
class TelegramResult {
  final bool isSuccess;
  final String message;

  TelegramResult._({required this.isSuccess, required this.message});

  factory TelegramResult.success(String message) {
    return TelegramResult._(isSuccess: true, message: message);
  }

  factory TelegramResult.error(String message) {
    return TelegramResult._(isSuccess: false, message: message);
  }
}
