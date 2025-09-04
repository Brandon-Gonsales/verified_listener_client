import 'package:flutter/material.dart';
import '../services/native_notification_service.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_button.dart';
import '../utils/validators.dart';

class YapeListenerScreen extends StatefulWidget {
  const YapeListenerScreen({Key? key}) : super(key: key);

  @override
  State<YapeListenerScreen> createState() => _YapeListenerScreenState();
}

class _YapeListenerScreenState extends State<YapeListenerScreen> {
  final TextEditingController _tokenController = TextEditingController(
    text: "8377162015:AAEzhIYzpnqJggrLI3zrfQE5exuvMchNjXM", // Tu token
  );
  final TextEditingController _chatIdController = TextEditingController(
    text: "8334864928", // Tu chat ID
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isListening = false;
  bool _isLoading = false;
  String _status = '⏹️ Detenido';
  List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _isListening = NativeNotificationService.isListening;
    if (_isListening) {
      _status = '✅ Escuchando...';
    }
  }

  Future<void> _toggleListening() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_isListening) {
        // Iniciar servicio
        _addLogMessage('🚀 Iniciando servicio...');

        bool success = await NativeNotificationService.initialize(
          token: _tokenController.text.trim(),
          chatId: _chatIdController.text.trim(),
          onStatusChanged: _onStatusChanged,
        );

        if (success) {
          setState(() {
            _isListening = true;
            _status = '✅ Escuchando notificaciones de Yape';
          });
          _addLogMessage('✅ Servicio iniciado correctamente');
          _showSnackBar('Servicio iniciado - Ahora haz un Yape para probar',
              isError: false);
        } else {
          _addLogMessage('❌ Error: No se pudieron obtener los permisos');
          _showSnackBar(
              'Error: Otorga permisos de notificación en Configuración',
              isError: true);
        }
      } else {
        // Detener servicio
        NativeNotificationService.stopListening();
        setState(() {
          _isListening = false;
          _status = '⏹️ Detenido';
        });
        _addLogMessage('⏹️ Servicio detenido');
        _showSnackBar('Servicio detenido', isError: false);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _status = status;
    });
    _addLogMessage(status);
  }

  void _addLogMessage(String message) {
    setState(() {
      _logMessages.insert(
          0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_logMessages.length > 50) {
        _logMessages = _logMessages.take(50).toList();
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logMessages.clear();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
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
        title: const Text('Yape'),
        backgroundColor: Colors.purple,
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
              // // Información
              // _buildInfoCard(),
              // const SizedBox(height: 24),

              // Configuración
              _buildConfigCard(),
              const SizedBox(height: 24),

              // Estado actual
              _buildStatusCard(),
              const SizedBox(height: 24),

              // Botón principal
              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleListening,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(_isListening ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _isLoading
                        ? (_isListening ? 'Deteniendo...' : 'Iniciando...')
                        : (_isListening
                            ? 'Detener Servicio'
                            : 'Iniciar Servicio'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Log de actividad
              _buildLogCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Detector Automático de Yape',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Esta función escucha las notificaciones de Yape automáticamente\n'
              '• Cuando detecta un Yape, extrae los datos y los envía a Telegram\n'
              '• Debes otorgar permisos de acceso a notificaciones\n'
              '• Solo funciona con la app abierta o en segundo plano',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de Telegram',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _tokenController,
              labelText: 'Token del Bot',
              hintText: '123456789:ABCdef123456...',
              prefixIcon: Icons.key,
              obscureText: true,
              validator: Validators.validateTelegramToken,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _chatIdController,
              labelText: 'Chat ID',
              hintText: '123456789',
              prefixIcon: Icons.chat,
              validator: Validators.validateChatId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      color: _isListening ? Colors.green[50] : Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isListening
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _isListening ? Colors.green[700] : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estado: $_status',
                    style: TextStyle(
                      color:
                          _isListening ? Colors.green[700] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (_isListening) ...[
              const SizedBox(height: 8),
              const Text(
                'Haz un Yape para ver el detector en acción',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log de Actividad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (_logMessages.isNotEmpty)
                  TextButton(
                    onPressed: _clearLogs,
                    child: const Text('Limpiar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _logMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay actividad aún...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logMessages[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
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
    super.dispose();
  }
}
