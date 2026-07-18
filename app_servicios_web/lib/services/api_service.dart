import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cambia esto dependiendo de si usas emulador o teléfono físico
  static const bool useAndroidEmulator = false; // true si usas el emulador de Android Studio

static String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000/api';
  }

  if (Platform.isAndroid) {
    if (useAndroidEmulator) {
      return 'http://10.0.2.2:8000/api'; // SIEMPRE así para el emulador
    } else {
      return 'http://127.0.0.1:8001/api'; // requiere adb reverse (ver abajo)
    }
  }

  return 'http://127.0.0.1:8000/api';
}

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('access_token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', data['access_token']);
        }

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ??
              'Error de credenciales',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}