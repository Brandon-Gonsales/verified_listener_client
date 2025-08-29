class TelegramMessage {
  final String chatId;
  final String token;
  final String message;

  TelegramMessage({
    required this.chatId,
    required this.token,
    required this.message,
  });

  // Método para validar que todos los campos estén completos
  bool get isValid =>
      chatId.isNotEmpty && token.isNotEmpty && message.isNotEmpty;

  // Convertir a Map para enviar en la petición HTTP
  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'text': message,
    };
  }

  // Crear desde Map (útil para futuras funciones)
  factory TelegramMessage.fromJson(Map<String, dynamic> json) {
    return TelegramMessage(
      chatId: json['chat_id'] ?? '',
      token: '', // El token no viene en la respuesta
      message: json['text'] ?? '',
    );
  }
}
