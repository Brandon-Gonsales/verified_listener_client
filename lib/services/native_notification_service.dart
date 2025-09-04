import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/telegram_message.dart';
import 'telegram_service.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('notification_listener');
  static bool _isListening = false;
  static String? _telegramToken;
  static String? _chatId;
  static Function(String)? _onStatusChanged;

  // Inicializar el servicio
  static Future<bool> initialize({
    required String token,
    required String chatId,
    Function(String)? onStatusChanged,
  }) async {
    _telegramToken = token;
    _chatId = chatId;
    _onStatusChanged = onStatusChanged;

    try {
      // Configurar handler para recibir notificaciones
      _channel.setMethodCallHandler(_handleMethodCall);

      // Verificar permisos
      bool hasPermission =
          await _channel.invokeMethod('hasNotificationPermission');

      if (!hasPermission) {
        _updateStatus('Solicitando permisos...');
        await _channel.invokeMethod('requestNotificationPermission');

        // Verificar nuevamente
        hasPermission =
            await _channel.invokeMethod('hasNotificationPermission');
        if (!hasPermission) {
          _updateStatus('❌ Permisos no otorgados');
          return false;
        }
      }

      // Iniciar servicio
      bool started = await _channel.invokeMethod('startListening');
      if (started) {
        _isListening = true;
        _updateStatus('✅ Escuchando notificaciones de Yape');
        return true;
      } else {
        _updateStatus('❌ Error iniciando servicio');
        return false;
      }
    } catch (e) {
      _updateStatus('❌ Error: $e');
      print('Error inicializando servicio nativo: $e');
      return false;
    }
  }

  // Manejar llamadas desde Android
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        await _handleNotification(call.arguments);
        break;
      case 'onStatusUpdate':
        _updateStatus(call.arguments.toString());
        break;
    }
  }

  // Procesar notificación recibida
  static Future<void> _handleNotification(Map<dynamic, dynamic> data) async {
    try {
      String packageName = data['packageName'] ?? '';
      String title = data['title'] ?? '';
      String text = data['text'] ?? '';

      print('📱 Notificación: $packageName - $title - $text');

      // Verificar si es de Yape
      if (_isYapeNotification(packageName, title, text) &&
          packageName == "com.bcp.bo.wallet") {
        _updateStatus('🔔 Yape detectado');

        final yapeData = _extractYapeData(packageName, title, text);
        if (yapeData != null) {
          // Agregar data cruda original a los datos extraídos
          yapeData['rawData'] = jsonEncode(data);
          await _sendToTelegram(yapeData, originalData: data);
        }
      }
    } catch (e) {
      print('Error procesando notificación: $e');
    }
  }

  // Verificar si es notificación de Yape
  static bool _isYapeNotification(
      String packageName, String title, String text) {
    String fullText = '$packageName $title $text'.toLowerCase();

    return fullText.contains('yape') ||
        fullText.contains('bcp') ||
        (text.contains('s/') &&
            (text.contains('recibiste') || text.contains('yapaste')));
  }

  // Extraer datos de Yape
  static Map<String, String>? _extractYapeData(
      String packageName, String title, String text) {
    try {
      String fullText = '$title $text';

      // Extraer monto
      RegExp montoRegex =
          RegExp(r'S\/?\s*(\d+(?:[.,]\d{2})?)', caseSensitive: false);
      String monto =
          montoRegex.firstMatch(fullText)?.group(1) ?? 'No detectado';

      // Extraer contacto
      RegExp nombreRegex = RegExp(
          r'(?:de|para|a|con)\s+([A-Za-z\s]+?)(?:\s|$|por|\.)',
          caseSensitive: false);
      String contacto =
          nombreRegex.firstMatch(fullText)?.group(1)?.trim() ?? 'No detectado';

      // Limpiar contacto
      contacto = contacto
          .replaceAll(
              RegExp(r'\b(yape|s/|por|el|la)\b', caseSensitive: false), '')
          .trim();
      if (contacto.length > 50) contacto = contacto.substring(0, 50) + '...';

      // Tipo de operación
      String tipo = '📱 Yape';
      if (fullText.toLowerCase().contains('recibiste')) {
        tipo = '💰 Recibido';
      } else if (fullText.toLowerCase().contains('yapeste')) {
        tipo = '📤 Enviado';
      }

      return {
        'monto': monto,
        'contacto': contacto.isNotEmpty ? contacto : 'No detectado',
        'tipo': tipo,
        'fecha': DateTime.now().toString(),
        'titulo': title,
        'contenido': text,
        'packageName': packageName,
      };
    } catch (e) {
      print('Error extrayendo datos: $e');
      return null;
    }
  }

  // Enviar a Telegram
  static Future<void> _sendToTelegram(Map<String, String> yapeData,
      {Map<dynamic, dynamic>? originalData}) async {
    if (_telegramToken == null || _chatId == null) return;

    try {
      _updateStatus('📤 Enviando a Telegram...');

      String message = _formatMessage(yapeData, originalData: originalData);

      final telegramMessage = TelegramMessage(
        token: _telegramToken!,
        chatId: _chatId!,
        message: message,
      );

      final result = await TelegramService.sendMessage(telegramMessage);

      if (result.isSuccess) {
        _updateStatus('✅ Enviado correctamente');
      } else {
        _updateStatus('❌ Error enviando: ${result.message}');
      }
    } catch (e) {
      _updateStatus('❌ Error enviando a Telegram');
      print('Error enviando: $e');
    }
  }

  // Formatear mensaje - Solo data cruda JSON
  static String _formatMessage(Map<String, String> data,
      {Map<dynamic, dynamic>? originalData}) {
    if (originalData != null) {
      try {
        // Crear una copia limpia de los datos
        Map<String, dynamic> cleanData = {};
        originalData.forEach((key, value) {
          cleanData[key.toString()] = value?.toString() ?? 'null';
        });

        // Convertir a JSON con formato legible
        return const JsonEncoder.withIndent('  ').convert(cleanData);
      } catch (e) {
        return originalData.toString();
      }
    }

    return 'No data available';
  }

  // ALTERNATIVA: Enviar solo la data cruda
  static String _formatRawDataOnly(Map<dynamic, dynamic> originalData) {
    DateTime now = DateTime.now();
    String fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String rawDataJson = '';
    try {
      Map<String, dynamic> cleanData = {
        'timestamp': fecha,
        'detected_at': now.toIso8601String(),
      };

      originalData.forEach((key, value) {
        cleanData[key.toString()] = value?.toString() ?? 'null';
      });

      rawDataJson = const JsonEncoder.withIndent('  ').convert(cleanData);
    } catch (e) {
      rawDataJson = originalData.toString();
    }

    return '''$fecha

```
$rawDataJson
```''';
  }

  // Actualizar estado
  static void _updateStatus(String status) {
    print('📊 $status');
    if (_onStatusChanged != null) {
      _onStatusChanged!(status);
    }
  }

  // Detener servicio
  static Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
      _isListening = false;
      _updateStatus('⏹️ Servicio detenido');
    } catch (e) {
      print('Error deteniendo servicio: $e');
    }
  }

  // Estado
  static bool get isListening => _isListening;

  // Enviar solo data cruda a Telegram
  static Future<void> _sendRawDataToTelegram(
      Map<dynamic, dynamic> rawData) async {
    if (_telegramToken == null || _chatId == null) return;

    try {
      _updateStatus('📤 Enviando a Telegram...');

      // Crear JSON limpio con solo los datos esenciales
      Map<String, dynamic> cleanData = {
        'packageName': rawData['packageName']?.toString() ?? '',
        'title': rawData['title']?.toString() ?? '',
        'text': rawData['text']?.toString() ?? '',
        'timestamp': rawData['timestamp']?.toString() ?? '',
      };

      String jsonMessage =
          const JsonEncoder.withIndent('  ').convert(cleanData);

      final telegramMessage = TelegramMessage(
        token: _telegramToken!,
        chatId: _chatId!,
        message: jsonMessage,
      );

      final result = await TelegramService.sendMessage(telegramMessage);

      if (result.isSuccess) {
        _updateStatus('✅ Enviado correctamente');
      } else {
        _updateStatus('❌ Error enviando: ${result.message}');
      }
    } catch (e) {
      _updateStatus('❌ Error enviando a Telegram');
      print('Error enviando: $e');
    }
  }
}
// import 'package:flutter/services.dart';
// import '../models/telegram_message.dart';
// import 'telegram_service.dart';

// class NativeNotificationService {
//   static const MethodChannel _channel = MethodChannel('notification_listener');
//   static bool _isListening = false;
//   static String? _telegramToken;
//   static String? _chatId;
//   static Function(String)? _onStatusChanged;

//   // Inicializar el servicio
//   static Future<bool> initialize({
//     required String token,
//     required String chatId,
//     Function(String)? onStatusChanged,
//   }) async {
//     _telegramToken = token;
//     _chatId = chatId;
//     _onStatusChanged = onStatusChanged;

//     try {
//       // Configurar handler para recibir notificaciones
//       _channel.setMethodCallHandler(_handleMethodCall);

//       // Verificar permisos
//       bool hasPermission =
//           await _channel.invokeMethod('hasNotificationPermission');

//       if (!hasPermission) {
//         _updateStatus('Solicitando permisos...');
//         await _channel.invokeMethod('requestNotificationPermission');

//         // Verificar nuevamente
//         hasPermission =
//             await _channel.invokeMethod('hasNotificationPermission');
//         if (!hasPermission) {
//           _updateStatus('❌ Permisos no otorgados');
//           return false;
//         }
//       }

//       // Iniciar servicio
//       bool started = await _channel.invokeMethod('startListening');
//       if (started) {
//         _isListening = true;
//         _updateStatus('✅ Escuchando notificaciones de Yape');
//         return true;
//       } else {
//         _updateStatus('❌ Error iniciando servicio');
//         return false;
//       }
//     } catch (e) {
//       _updateStatus('❌ Error: $e');
//       print('Error inicializando servicio nativo: $e');
//       return false;
//     }
//   }

//   // Manejar llamadas desde Android
//   static Future<dynamic> _handleMethodCall(MethodCall call) async {
//     switch (call.method) {
//       case 'onNotificationReceived':
//         await _handleNotification(call.arguments);
//         break;
//       case 'onStatusUpdate':
//         _updateStatus(call.arguments.toString());
//         break;
//     }
//   }

//   // Procesar notificación recibida
//   static Future<void> _handleNotification(Map<dynamic, dynamic> data) async {
//     try {
//       String packageName = data['packageName'] ?? '';
//       String title = data['title'] ?? '';
//       String text = data['text'] ?? '';

//       print('📱 Notificación: $packageName - $title - $text');

//       // Verificar si es de Yape
//       if (_isYapeNotification(packageName, title, text)) {
//         _updateStatus('🔔 Yape detectado');

//         final yapeData = _extractYapeData(packageName, title, text);
//         if (yapeData != null) {
//           await _sendToTelegram(yapeData);
//         }
//       }
//     } catch (e) {
//       print('Error procesando notificación: $e');
//     }
//   }

//   // Verificar si es notificación de Yape
//   static bool _isYapeNotification(
//       String packageName, String title, String text) {
//     String fullText = '$packageName $title $text'.toLowerCase();

//     return fullText.contains('yape') ||
//         fullText.contains('bcp') ||
//         (text.contains('s/') &&
//             (text.contains('recibiste') || text.contains('yapaste')));
//   }

//   // Extraer datos de Yape
//   static Map<String, String>? _extractYapeData(
//       String packageName, String title, String text) {
//     try {
//       String fullText = '$title $text';

//       // Extraer monto
//       RegExp montoRegex =
//           RegExp(r'S\/?\s*(\d+(?:[.,]\d{2})?)', caseSensitive: false);
//       String monto =
//           montoRegex.firstMatch(fullText)?.group(1) ?? 'No detectado';

//       // Extraer contacto
//       RegExp nombreRegex = RegExp(
//           r'(?:de|para|a|con)\s+([A-Za-z\s]+?)(?:\s|$|por|\.)',
//           caseSensitive: false);
//       String contacto =
//           nombreRegex.firstMatch(fullText)?.group(1)?.trim() ?? 'No detectado';

//       // Limpiar contacto
//       contacto = contacto
//           .replaceAll(
//               RegExp(r'\b(yape|s/|por|el|la)\b', caseSensitive: false), '')
//           .trim();
//       if (contacto.length > 50) contacto = contacto.substring(0, 50) + '...';

//       // Tipo de operación
//       String tipo = '📱 Yape';
//       if (fullText.toLowerCase().contains('recibiste')) {
//         tipo = '💰 Recibido';
//       } else if (fullText.toLowerCase().contains('yapaste')) {
//         tipo = '📤 Enviado';
//       }

//       return {
//         'monto': monto,
//         'contacto': contacto.isNotEmpty ? contacto : 'No detectado',
//         'tipo': tipo,
//         'fecha': DateTime.now().toString(),
//         'titulo': title,
//         'contenido': text,
//         'packageName': packageName,
//       };
//     } catch (e) {
//       print('Error extrayendo datos: $e');
//       return null;
//     }
//   }

//   // Enviar a Telegram
//   static Future<void> _sendToTelegram(Map<String, String> yapeData) async {
//     if (_telegramToken == null || _chatId == null) return;

//     try {
//       _updateStatus('📤 Enviando a Telegram...');

//       String message = _formatMessage(yapeData);

//       final telegramMessage = TelegramMessage(
//         token: _telegramToken!,
//         chatId: _chatId!,
//         message: message,
//       );

//       final result = await TelegramService.sendMessage(telegramMessage);

//       if (result.isSuccess) {
//         _updateStatus('✅ Enviado correctamente');
//       } else {
//         _updateStatus('❌ Error enviando: ${result.message}');
//       }
//     } catch (e) {
//       _updateStatus('❌ Error enviando a Telegram');
//       print('Error enviando: $e');
//     }
//   }

//   // Formatear mensaje
//   static String _formatMessage(Map<String, String> data) {
//     DateTime now = DateTime.now();
//     String fecha =
//         '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return '''🔔 *YAPE DETECTADO*

// ${data['tipo']}
// 💰 *Monto:* S/ ${data['monto']}
// 👤 *Contacto:* ${data['contacto']}
// 📅 *Fecha:* $fecha

// 📱 *Detalles:*
// ${data['titulo']}
// ${data['contenido']}

// _Detectado automáticamente_ 🤖''';
//   }

//   // Actualizar estado
//   static void _updateStatus(String status) {
//     print('📊 $status');
//     if (_onStatusChanged != null) {
//       _onStatusChanged!(status);
//     }
//   }

//   // Detener servicio
//   static Future<void> stopListening() async {
//     try {
//       await _channel.invokeMethod('stopListening');
//       _isListening = false;
//       _updateStatus('⏹️ Servicio detenido');
//     } catch (e) {
//       print('Error deteniendo servicio: $e');
//     }
//   }

//   // Estado
//   static bool get isListening => _isListening;
// }
