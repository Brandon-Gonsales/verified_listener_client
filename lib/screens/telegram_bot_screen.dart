import 'package:flutter/material.dart';
import '../models/telegram_message.dart';
import '../services/telegram_service.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_button.dart';
import '../utils/validators.dart';

class TelegramBotScreen extends StatefulWidget {
  const TelegramBotScreen({Key? key}) : super(key: key);

  @override
  State<TelegramBotScreen> createState() => _TelegramBotScreenState();
}

class _TelegramBotScreenState extends State<TelegramBotScreen> {
  // Controladores
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Clave del formulario para validaciones
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Estado
  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;

  // Método principal para enviar mensaje
  Future<void> _sendMessage() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      // Crear modelo de mensaje
      final telegramMessage = TelegramMessage(
        token: _tokenController.text.trim(),
        chatId: _chatIdController.text.trim(),
        message: _messageController.text.trim(),
      );

      // Enviar mensaje usando el servicio
      final result = await TelegramService.sendMessage(telegramMessage);

      // Actualizar UI con el resultado
      setState(() {
        _resultMessage = result.message;
        _isSuccess = result.isSuccess;
      });

      // Mostrar SnackBar
      _showSnackBar(result.message, isError: !result.isSuccess);

      // Limpiar mensaje si fue exitoso
      if (result.isSuccess) {
        _messageController.clear();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para validar bot (opcional)
  Future<void> _validateBot() async {
    if (_tokenController.text.trim().isEmpty) {
      _showSnackBar('Ingresa un token primero', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result =
          await TelegramService.validateBot(_tokenController.text.trim());
      _showSnackBar(result.message, isError: !result.isSuccess);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mostrar SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card informativo
              _buildInfoCard(),

              const SizedBox(height: 24),

              // Campos del formulario
              CustomTextField(
                controller: _tokenController,
                labelText: 'Token del Bot',
                hintText: '123456789:ABCdef123456...',
                prefixIcon: Icons.key,
                obscureText: true,
                validator: Validators.validateTelegramToken,
              ),

              const SizedBox(height: 16),

              // // Botón para validar bot (opcional)
              // TextButton.icon(
              //   onPressed: _isLoading ? null : _validateBot,
              //   icon: const Icon(Icons.verified),
              //   label: const Text('Validar Bot'),
              // ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _chatIdController,
                labelText: 'Chat ID',
                hintText: '123456789 o @username',
                prefixIcon: Icons.chat,
                validator: Validators.validateChatId,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _messageController,
                labelText: 'Mensaje',
                hintText: 'Escribe tu mensaje aquí...',
                prefixIcon: Icons.message,
                maxLines: 3,
                validator: Validators.validateMessage,
              ),

              const SizedBox(height: 24),

              // Botón enviar
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _sendMessage,
                text: 'Enviar Mensaje',
                loadingText: 'Enviando...',
                icon: Icons.send,
              ),

              const SizedBox(height: 20),

              // Mensaje de resultado
              if (_resultMessage != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la tarjeta informativa
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Configuración del Bot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar el resultado
  Widget _buildResultCard() {
    return Card(
      elevation: 2,
      color: _isSuccess ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _isSuccess ? Icons.check_circle : Icons.error,
              color: _isSuccess ? Colors.green[700] : Colors.red[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _resultMessage!,
                style: TextStyle(
                  color: _isSuccess ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
