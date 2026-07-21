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
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = _tryDecodeMap(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['access_token'] is String &&
          (data['access_token'] as String).isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token'] as String);

        return {
          'success': true,
          'role': data['role'],
          'user': data['user'],
          'data': data,
        };
      }

      return {
        'success': false,
        'message': _extractErrorMessage(
          data,
          statusCode: response.statusCode,
          fallback: 'Error de credenciales',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Registro público de comprador: POST /api/register.
  ///
  /// Payload: nombre, apellido_paterno, apellido_materno?, email,
  /// password, password_confirmation.
  /// Éxito (201): guarda JWT y devuelve role `user`.
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final body = <String, dynamic>{
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
      if (apellidoMaterno != null && apellidoMaterno.trim().isNotEmpty) {
        body['apellido_materno'] = apellidoMaterno.trim();
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = _tryDecodeMap(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true &&
          data['access_token'] is String &&
          (data['access_token'] as String).isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token'] as String);

        return {
          'success': true,
          'role': data['role'] ?? 'user',
          'user': data['user'],
          'data': data,
        };
      }

      return {
        'success': false,
        'message': _extractErrorMessage(
          data,
          statusCode: response.statusCode,
          fallback: 'No se pudo crear la cuenta',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Map<String, dynamic> _tryDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  /// Mensaje legible desde Laravel (error / message / errors 422).
  String _extractErrorMessage(
    Map<String, dynamic> data, {
    required int statusCode,
    required String fallback,
  }) {
    final errors = data['errors'];
    if (errors is Map) {
      final parts = <String>[];
      for (final entry in errors.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) {
          parts.add(v.first.toString());
        } else if (v != null) {
          parts.add(v.toString());
        }
      }
      if (parts.isNotEmpty) return parts.join(' ');
    }

    final err = data['error'];
    if (err is String && err.trim().isNotEmpty) return err.trim();

    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();

    if (statusCode == 401) return 'Credenciales inválidas';
    if (statusCode == 403) return 'Acceso no permitido';
    if (statusCode == 422) return 'Datos inválidos';
    if (statusCode == 404) return 'Servicio no disponible';
    if (statusCode >= 500) return 'Error del servidor ($statusCode)';
    return fallback;
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

  /// Perfil del usuario autenticado: GET /api/me.
  ///
  /// Retorna:
  /// - `{success: true, user: {...}}`
  /// - `{success: false, message: '...'}`
  Future<Map<String, dynamic>> fetchMe() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sin sesión'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/me'),
            headers: await getAuthHeaders(includeContentType: false),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        return {'success': false, 'message': 'Sesión expirada'};
      }
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'No se pudo cargar el perfil (${response.statusCode})',
        };
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return {'success': true, 'user': data};
      }
      if (data is Map) {
        return {'success': true, 'user': Map<String, dynamic>.from(data)};
      }
      return {'success': false, 'message': 'Respuesta de perfil inválida'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
