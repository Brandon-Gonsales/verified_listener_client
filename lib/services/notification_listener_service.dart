// import 'package:flutter_notification_listener/flutter_notification_listener.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../models/telegram_message.dart';
// import 'telegram_service.dart';

// class NotificationListenerService {
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

//     // Verificar permisos
//     if (!await _checkPermissions()) {
//       _updateStatus('Error: Permisos no otorgados');
//       return false;
//     }

//     // Iniciar el listener
//     await _startListening();
//     return true;
//   }

//   // Verificar permisos necesarios
//   static Future<bool> _checkPermissions() async {
//     try {
//       // Verificar si el acceso a notificaciones está habilitado
//       bool isEnabled = await NotificationListener.isEnabled ?? false;

//       if (!isEnabled) {
//         _updateStatus('Abriendo configuración de permisos...');
//         // Abrir configuración para habilitar acceso
//         await NotificationListener.openPermissionSettings();
//         return false;
//       }

//       return true;
//     } catch (e) {
//       print('Error verificando permisos: $e');
//       return false;
//     }
//   }

//   // Iniciar escucha de notificaciones
//   static Future<void> _startListening() async {
//     if (_isListening) return;

//     try {
//       _isListening = true;
//       _updateStatus('Iniciando servicio...');

//       // Inicializar el listener
//       await NotificationListener.initialize(
//           callbackHandle: _onNotificationReceived);

//       // Escuchar notificaciones en tiempo real
//       NotificationListener.receivePort.listen((evt) {
//         _handleNotification(evt);
//       });

//       _updateStatus('✅ Escuchando notificaciones de Yape');
//     } catch (e) {
//       _isListening = false;
//       _updateStatus('❌ Error iniciando servicio: $e');
//       print('Error iniciando listener: $e');
//     }
//   }

//   // Callback estático para notificaciones (se ejecuta en background)
//   static void _onNotificationReceived(evt) {
//     _handleNotification(evt);
//   }

//   // Procesar notificación recibida
//   static void _handleNotification(dynamic evt) async {
//     try {
//       if (evt is ServiceNotificationEvent) {
//         print('📱 Notificación recibida de: ${evt.packageName}');
//         print('📄 Título: ${evt.title}');
//         print('📝 Contenido: ${evt.content}');

//         // Verificar si es de Yape
//         if (_isYapeNotification(evt)) {
//           _updateStatus('🔔 Notificación de Yape detectada');
//           final yapeData = _extractYapeData(evt);
//           if (yapeData != null) {
//             await _sendToTelegram(yapeData);
//           }
//         }
//       }
//     } catch (e) {
//       print('❌ Error procesando notificación: $e');
//       _updateStatus('❌ Error procesando notificación');
//     }
//   }

//   // Verificar si la notificación es de Yape
//   static bool _isYapeNotification(ServiceNotificationEvent evt) {
//     String packageName = evt.packageName?.toLowerCase() ?? '';
//     String title = evt.title?.toLowerCase() ?? '';
//     String content = evt.content?.toLowerCase() ?? '';

//     // Buscar indicadores de Yape
//     return packageName.contains('yape') ||
//         packageName.contains('bcp') ||
//         title.contains('yape') ||
//         content.contains('yape') ||
//         content.contains('yapaste') ||
//         content.contains('recibiste') && content.contains('s/');
//   }

//   // Extraer datos de la notificación de Yape
//   static Map<String, String>? _extractYapeData(ServiceNotificationEvent evt) {
//     try {
//       String title = evt.title ?? '';
//       String content = evt.content ?? '';
//       String fullText = '$title $content';

//       print('🔍 Extrayendo datos de: $fullText');

//       // Extraer monto (patrones: "S/ 50.00", "S/50", "S/ 50")
//       RegExp montoRegex =
//           RegExp(r'S\/?\s*(\d+(?:[.,]\d{2})?)', caseSensitive: false);
//       Match? montoMatch = montoRegex.firstMatch(fullText);
//       String monto = montoMatch?.group(1) ?? 'No detectado';

//       // Extraer nombre/contacto (después de "de", "para", "a")
//       RegExp nombreRegex = RegExp(
//           r'(?:de|para|a|con)\s+([A-Za-z\s]+?)(?:\s|$|por|\.)',
//           caseSensitive: false);
//       Match? nombreMatch = nombreRegex.firstMatch(fullText);
//       String contacto = nombreMatch?.group(1)?.trim() ?? 'No detectado';

//       // Limpiar nombre (quitar palabras comunes)
//       contacto = contacto
//           .replaceAll(
//               RegExp(r'\b(yape|s/|por|el|la|un|una)\b', caseSensitive: false),
//               '')
//           .trim();
//       if (contacto.length > 50) contacto = contacto.substring(0, 50) + '...';

//       // Detectar tipo de operación
//       String tipoOperacion = 'Desconocido';
//       if (fullText.toLowerCase().contains('recibiste') ||
//           fullText.toLowerCase().contains('recibió')) {
//         tipoOperacion = '💰 Recibido';
//       } else if (fullText.toLowerCase().contains('yapaste') ||
//           fullText.toLowerCase().contains('enviaste') ||
//           fullText.toLowerCase().contains('envió')) {
//         tipoOperacion = '📤 Enviado';
//       }

//       Map<String, String> data = {
//         'monto': monto,
//         'contacto': contacto.isNotEmpty ? contacto : 'No detectado',
//         'tipo': tipoOperacion,
//         'fecha': DateTime.now().toString(),
//         'titulo': title,
//         'contenido': content,
//         'packageName': evt.packageName ?? '',
//       };

//       print('✅ Datos extraídos: $data');
//       return data;
//     } catch (e) {
//       print('❌ Error extrayendo datos: $e');
//       return null;
//     }
//   }

//   // Enviar datos a Telegram
//   static Future<void> _sendToTelegram(Map<String, String> yapeData) async {
//     if (_telegramToken == null || _chatId == null) {
//       _updateStatus('❌ Token o Chat ID no configurados');
//       return;
//     }

//     try {
//       _updateStatus('📤 Enviando a Telegram...');

//       String message = _formatTelegramMessage(yapeData);

//       final telegramMessage = TelegramMessage(
//         token: _telegramToken!,
//         chatId: _chatId!,
//         message: message,
//       );

//       final result = await TelegramService.sendMessage(telegramMessage);

//       if (result.isSuccess) {
//         _updateStatus('✅ Enviado a Telegram correctamente');
//       } else {
//         _updateStatus('❌ Error enviando: ${result.message}');
//       }
//     } catch (e) {
//       print('❌ Error enviando a Telegram: $e');
//       _updateStatus('❌ Error enviando a Telegram');
//     }
//   }

//   // Formatear mensaje para Telegram
//   static String _formatTelegramMessage(Map<String, String> data) {
//     DateTime now = DateTime.now();
//     String fecha =
//         '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return '''🔔 *YAPE DETECTADO*

// ${data['tipo']} 
// 💰 *Monto:* S/ ${data['monto']}
// 👤 *Contacto:* ${data['contacto']}
// 📅 *Fecha:* $fecha

// 📱 *Detalles:*
// • App: ${data['packageName']}
// • Título: ${data['titulo']}
// • Mensaje: ${data['contenido']}

// _Mensaje enviado automáticamente desde tu app_ 🤖''';
//   }

//   // Actualizar estado
//   static void _updateStatus(String status) {
//     print('📊 Estado: $status');
//     if (_onStatusChanged != null) {
//       _onStatusChanged!(status);
//     }
//   }

//   // Detener el servicio
//   static void stopListening() {
//     if (_isListening) {
//       _isListening = false;
//       _updateStatus('⏹️ Servicio detenido');
//     }
//   }

//   // Verificar si está escuchando
//   static bool get isListening => _isListening;
// }
