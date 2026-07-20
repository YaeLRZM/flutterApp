import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = 'jwt_token';

  // Cambia esto dependiendo de si usas emulador o teléfono físico
  static const bool useAndroidEmulator =
      true; // true si usas el emulador de Android Studio

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    if (Platform.isAndroid) {
      if (useAndroidEmulator) {
        return 'http://10.0.2.2:8000/api'; // SIEMPRE así para el emulador en Android Studio
      } else {
        return 'http://127.0.0.1:8001/api'; // para usar el telefono en la mac, por que no queria funcionar
      }
    }

    return 'http://127.0.0.1:8000/api';
  }

  /// Lee el JWT guardado tras login. `null` si no hay sesión local.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  /// Elimina el JWT local (no llama a la API).
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Headers para requests autenticados.
  /// Sin token: devuelve solo Accept/Content-Type (sin Authorization).
  Future<Map<String, String>> getAuthHeaders({
    bool includeContentType = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token'] as String);

        return {'success': true, 'role': data['role'], 'data': data};
      } else {
        return {
          'success': false,
          'message':
              data['error'] ?? data['message'] ?? 'Error de credenciales',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cierra sesión: intenta POST /api/logout y siempre borra el token local.
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        try {
          await http
              .post(
                Uri.parse('$baseUrl/logout'),
                headers: await getAuthHeaders(),
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Red/timeout: igual se limpia la sesión local abajo.
        }
      }
    } finally {
      await clearToken();
    }
    return {'success': true};
  }
}
