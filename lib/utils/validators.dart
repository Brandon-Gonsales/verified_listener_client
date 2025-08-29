class Validators {
  // Validador para el token de Telegram
  static String? validateTelegramToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'El token es obligatorio';
    }

    // Formato básico de token de Telegram: XXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    final tokenRegex = RegExp(r'^\d+:[A-Za-z0-9_-]{35}$');

    if (!tokenRegex.hasMatch(value)) {
      return 'Formato de token inválido';
    }

    return null;
  }

  // Validador para Chat ID
  static String? validateChatId(String? value) {
    if (value == null || value.isEmpty) {
      return 'El Chat ID es obligatorio';
    }

    // Puede ser un número o empezar con @
    if (value.startsWith('@')) {
      if (value.length < 2) {
        return 'Username inválido';
      }
    } else {
      // Verificar que sea un número válido
      if (int.tryParse(value) == null) {
        return 'Chat ID debe ser un número o @username';
      }
    }

    return null;
  }

  // Validador para mensajes
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'El mensaje no puede estar vacío';
    }

    if (value.length > 4096) {
      return 'El mensaje no puede exceder 4096 caracteres';
    }

    return null;
  }

  // Validador genérico para campos obligatorios
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }
}
