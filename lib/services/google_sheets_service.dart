import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  static const String _baseUrl =
      'https://sheets.googleapis.com/v4/spreadsheets';
  static String? _apiKey;
  static String? _spreadsheetId;

  // Inicializar con API Key y ID de la hoja
  static void initialize({
    required String apiKey,
    required String spreadsheetId,
  }) {
    _apiKey = apiKey;
    _spreadsheetId = spreadsheetId;
  }

  // Enviar datos de Yape a Google Sheets
  static Future<bool> sendYapeData(Map<String, String> yapeData) async {
    if (_apiKey == null || _spreadsheetId == null) {
      print('❌ Google Sheets no inicializado');
      return false;
    }

    try {
      // Preparar los datos en formato de fila
      List<String> rowData = [
        DateTime.now().toString(), // Timestamp
        yapeData['tipo'] ?? '',
        yapeData['monto'] ?? '',
        yapeData['contacto'] ?? '',
        yapeData['titulo'] ?? '',
        yapeData['contenido'] ?? '',
        yapeData['packageName'] ?? '',
      ];

      // Crear el body de la request
      Map<String, dynamic> requestBody = {
        'values': [rowData],
        'majorDimension': 'ROWS',
      };

      // URL para append (agregar al final)
      String url = '$_baseUrl/$_spreadsheetId/values/Sheet1!A:G:append'
          '?valueInputOption=USER_ENTERED&key=$_apiKey';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('✅ Datos enviados a Google Sheets');
        return true;
      } else {
        print('❌ Error enviando a Sheets: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en Google Sheets: $e');
      return false;
    }
  }

  // Crear headers en la hoja (ejecutar solo una vez)
  static Future<bool> setupHeaders() async {
    if (_apiKey == null || _spreadsheetId == null) return false;

    try {
      List<String> headers = [
        'Fecha/Hora',
        'Tipo',
        'Monto',
        'Contacto',
        'Título',
        'Contenido',
        'Package'
      ];

      Map<String, dynamic> requestBody = {
        'values': [headers],
        'majorDimension': 'ROWS',
      };

      String url = '$_baseUrl/$_spreadsheetId/values/Sheet1!A1:G1'
          '?valueInputOption=USER_ENTERED&key=$_apiKey';

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error configurando headers: $e');
      return false;
    }
  }

  // Método alternativo usando Google Apps Script (más fácil de configurar)
  static Future<bool> sendToGoogleAppsScript({
    required String scriptUrl,
    required Map<String, String> yapeData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'timestamp': DateTime.now().toIso8601String(),
          'tipo': yapeData['tipo'],
          'monto': yapeData['monto'],
          'contacto': yapeData['contacto'],
          'titulo': yapeData['titulo'],
          'contenido': yapeData['contenido'],
          'packageName': yapeData['packageName'],
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Datos enviados via Apps Script');
        return true;
      } else {
        print('❌ Error en Apps Script: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error enviando a Apps Script: $e');
      return false;
    }
  }
}
