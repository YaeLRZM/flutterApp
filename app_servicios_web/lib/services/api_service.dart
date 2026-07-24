import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente HTTP + sesión JWT (login, register, me, logout, refresh).
///
/// - Token en [FlutterSecureStorage] (con migración desde SharedPreferences).
/// - TTL típico backend: 60 min (`expires_in` segundos).
/// - Refresh vía POST /api/refresh si el token está por expirar o en 401.
/// - 401 de sesión: limpia almacenamiento y redirige a `/login` (una vez).
class ApiService {
  static const String _tokenKey = 'jwt_token';
  static const String _expiresAtKey = 'jwt_expires_at_ms';
  static const String _roleKey = 'user_role';

  /// Mensaje único para acciones de catálogo bloqueadas a vendedores.
  static const String msgAccionNoPermitidaVendedor =
      'Acción no permitida para cuentas vendedor';

  /// Margen para refrescar antes del `exp` real (evita carrera al filo).
  static const Duration _refreshSkew = Duration(minutes: 2);

  /// Navigator global para redirigir al caducar sesión (configurado en main).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static bool _redirectingToLogin = false;
  static Future<bool>? _refreshInFlight;

  // Cambia esto dependiendo de si usas emulador o teléfono físico
  static const bool useAndroidEmulator =
      false; // true si usas el emulador de Android Studio

  static const bool isProduction = true; // Cambia a false cuando programes localmente

static String get baseUrl {
  if (isProduction) {
    return 'https://ixemoda.up.railway.app/api';
  }

  // Configuración de desarrollo local
  if (kIsWeb) return 'http://127.0.0.1:8000/api';
  if (Platform.isAndroid) {
    return useAndroidEmulator
        ? 'http://10.0.2.2:8000/api'
        : 'http://10.76.167.106:8000/api';
  }
  return 'http://127.0.0.1:8000/api';
}


  // ---------------------------------------------------------------------------
  // Almacenamiento de sesión
  // ---------------------------------------------------------------------------

  /// Lee el JWT (secure storage; migra legado de SharedPreferences una vez).
  Future<String?> getToken() async {
    try {
      final secure = await _secure.read(key: _tokenKey);
      if (secure != null && secure.trim().isNotEmpty) {
        return secure.trim();
      }
    } catch (_) {
      // Web/plataforma sin secure: cae a prefs abajo.
    }

    // Migración one-shot desde SharedPreferences (sesión previa).
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_tokenKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        await _persistToken(legacy.trim());
        await prefs.remove(_tokenKey);
        await prefs.remove(_expiresAtKey);
        return legacy.trim();
      }
    } catch (_) {}

    return null;
  }

  /// Elimina token y metadata local (no llama a la API).
  Future<void> clearToken() async {
    try {
      await _secure.delete(key: _tokenKey);
      await _secure.delete(key: _expiresAtKey);
      await _secure.delete(key: _roleKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_expiresAtKey);
      await prefs.remove(_roleKey);
    } catch (_) {}
  }

  Future<void> _persistToken(String token, {int? expiresInSeconds}) async {
    await _secure.write(key: _tokenKey, value: token);
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      final expiresAtMs =
          DateTime.now().millisecondsSinceEpoch + (expiresInSeconds * 1000);
      await _secure.write(key: _expiresAtKey, value: expiresAtMs.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Rol autenticado (fuente central para UI y guards de catálogo)
  // ---------------------------------------------------------------------------

  /// Normaliza un string de rol (login /me / Spatie).
  static String normalizeRole(String? raw) {
    return (raw ?? '').toLowerCase().trim();
  }

  /// Extrae rol desde payload de login o mapa de usuario de /me.
  static String roleFromPayload(dynamic payload) {
    if (payload is! Map) return '';
    final map = Map<String, dynamic>.from(payload);

    final top = normalizeRole(
      (map['role'] ?? map['rol'] ?? map['user_role'])?.toString(),
    );
    if (top.isNotEmpty) return top;

    final user = map['user'];
    if (user is Map) {
      final nested = roleFromUserMap(user);
      if (nested.isNotEmpty) return nested;
    }

    return roleFromUserMap(map);
  }

  /// Extrae rol desde el objeto user (GET /me o login.user).
  static String roleFromUserMap(dynamic user) {
    if (user is! Map) return '';
    final map = Map<String, dynamic>.from(user);

    final direct = normalizeRole(
      (map['role'] ?? map['rol'] ?? map['user_role'])?.toString(),
    );
    if (direct.isNotEmpty) return direct;

    final roles = map['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      if (first is Map) {
        final n = normalizeRole(
          (first['name'] ?? first['nombre'] ?? first['role'])?.toString(),
        );
        if (n.isNotEmpty) return n;
      } else {
        final n = normalizeRole(first?.toString());
        if (n.isNotEmpty) return n;
      }
    }
    return '';
  }

  static bool isVendedorRoleName(String? role) {
    final r = normalizeRole(role);
    return r == 'vendedor' || r.contains('seller');
  }

  Future<void> saveRole(String? role) async {
    final r = normalizeRole(role);
    try {
      if (r.isEmpty) {
        await _secure.delete(key: _roleKey);
      } else {
        await _secure.write(key: _roleKey, value: r);
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      if (r.isEmpty) {
        await prefs.remove(_roleKey);
      } else {
        await prefs.setString(_roleKey, r);
      }
    } catch (_) {}
  }

  /// Rol guardado en sesión local (vacío si invitado / sin dato).
  Future<String> getRole() async {
    try {
      final secure = await _secure.read(key: _roleKey);
      if (secure != null && secure.trim().isNotEmpty) {
        return normalizeRole(secure);
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_roleKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        final r = normalizeRole(legacy);
        await saveRole(r);
        return r;
      }
    } catch (_) {}
    return '';
  }

  /// true si la sesión actual es de vendedor (catálogo de compra bloqueado).
  Future<bool> isVendedor() async {
    return isVendedorRoleName(await getRole());
  }

  Future<void> _saveSessionFromAuthResponse(Map<String, dynamic> data) async {
    final token = data['access_token'];
    if (token is! String || token.isEmpty) return;

    int? expiresIn;
    final raw = data['expires_in'];
    if (raw is int) {
      expiresIn = raw;
    } else if (raw is num) {
      expiresIn = raw.toInt();
    } else if (raw != null) {
      expiresIn = int.tryParse(raw.toString());
    }

    await _persistToken(token, expiresInSeconds: expiresIn);

    final role = roleFromPayload(data);
    if (role.isNotEmpty) {
      await saveRole(role);
    }

    _redirectingToLogin = false;
  }

  Future<int?> _expiresAtMs() async {
    try {
      final raw = await _secure.read(key: _expiresAtKey);
      if (raw == null || raw.isEmpty) return null;
      return int.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  /// true si no hay expiry guardado, o si falta poco / ya venció.
  Future<bool> _shouldRefreshProactively() async {
    final at = await _expiresAtMs();
    if (at == null) return false; // sin metadata: no forzar; se confía en 401
    final deadline = DateTime.fromMillisecondsSinceEpoch(at);
    return DateTime.now().isAfter(deadline.subtract(_refreshSkew));
  }

  // ---------------------------------------------------------------------------
  // Headers + refresh
  // ---------------------------------------------------------------------------

  /// Headers autenticados. Intenta refresh silencioso si el token está por vencer.
  Future<Map<String, String>> getAuthHeaders({
    bool includeContentType = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await ensureValidToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Token usable: si está por expirar, intenta POST /api/refresh.
  /// Si el refresh falla, limpia sesión y devuelve null.
  Future<String?> ensureValidToken() async {
    final token = await getToken();
    if (token == null) return null;

    if (await _shouldRefreshProactively()) {
      final ok = await tryRefreshToken();
      if (!ok) {
        await onUnauthorized(navigate: false);
        return null;
      }
      return getToken();
    }
    return token;
  }

  /// POST /api/refresh con el JWT actual. Deduplica llamadas concurrentes.
  Future<bool> tryRefreshToken() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final completer = Completer<bool>();
    _refreshInFlight = completer.future;

    try {
      final token = await getToken();
      if (token == null) {
        completer.complete(false);
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/refresh'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));

      final data = _tryDecodeMap(response.body);
      if (response.statusCode == 200 &&
          data['access_token'] is String &&
          (data['access_token'] as String).isNotEmpty) {
        await _saveSessionFromAuthResponse(data);
        completer.complete(true);
        return true;
      }

      completer.complete(false);
      return false;
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }

  /// Tras un 401 de endpoint autenticado: limpia sesión y opcionalmente
  /// manda a `/login` (sin loops).
  Future<void> onUnauthorized({bool navigate = true}) async {
    await clearToken();
    if (!navigate) return;
    _redirectToLoginOnce();
  }

  void _redirectToLoginOnce() {
    if (_redirectingToLogin) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    _redirectingToLogin = true;
    // Post-frame: evita reentrar durante build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        nav.pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (_) {
        _redirectingToLogin = false;
      }
    });
  }

  /// Si un request autenticado devuelve 401: un intento de refresh + reintento
  /// del caller, o limpieza. Usar en servicios que reciben 401.
  ///
  /// Retorna true si se renovó el token (el caller puede reintentar 1 vez).
  Future<bool> recoverFromUnauthorized() async {
    final ok = await tryRefreshToken();
    if (ok) return true;
    await onUnauthorized(navigate: true);
    return false;
  }

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

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
        await _saveSessionFromAuthResponse(data);

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
        await _saveSessionFromAuthResponse(data);

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

    final msg = data['message'] ?? data['mensaje'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();

    if (statusCode == 401) return 'Credenciales inválidas';
    if (statusCode == 403) return 'Acceso no permitido';
    if (statusCode == 422) return 'Datos inválidos';
    if (statusCode == 404) return 'Servicio no disponible';
    if (statusCode >= 500) {
      return 'No pudimos completar la operación. Intenta de nuevo.';
    }
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
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Red/timeout: igual se limpia la sesión local abajo.
        }
      }
    } finally {
      await clearToken();
      _redirectingToLogin = false;
    }
    return {'success': true};
  }

  /// Actualiza perfil: PUT /api/me (nunca envía rol).
  Future<Map<String, dynamic>> updateProfile({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? email,
    String? telefono,
    String? direccion,
    String? fotoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (apellidoPaterno != null) body['apellido_paterno'] = apellidoPaterno;
      if (apellidoMaterno != null) body['apellido_materno'] = apellidoMaterno;
      if (email != null) body['email'] = email;
      if (telefono != null) body['telefono'] = telefono;
      if (direccion != null) body['direccion'] = direccion;
      if (fotoUrl != null) body['foto_url'] = fotoUrl;

      final response = await http
          .put(
            Uri.parse('$baseUrl/me'),
            headers: await getAuthHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = _tryDecodeMap(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = data['user'] ?? data;
        Map<String, dynamic> userMap = data;
        if (user is Map) {
          userMap = Map<String, dynamic>.from(user);
        }
        return {
          'success': true,
          'user': userMap,
          'message': data['message']?.toString() ?? 'Perfil actualizado',
        };
      }
      if (response.statusCode == 401) {
        await onUnauthorized(navigate: true);
        return {
          'success': false,
          'message': 'Sesión expirada',
          'unauthorized': true,
        };
      }
      return {
        'success': false,
        'message': _extractErrorMessage(
          data,
          statusCode: response.statusCode,
          fallback: 'No se pudo guardar el perfil',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Perfil del usuario autenticado: GET /api/me.
  ///
  /// Retorna:
  /// - `{success: true, user: {...}}`
  /// - `{success: false, message: '...', unauthorized: true?}`
  Future<Map<String, dynamic>> fetchMe() async {
    try {
      var token = await ensureValidToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Sin sesión',
          'unauthorized': true,
        };
      }

      Future<http.Response> doGet() {
        return http
            .get(
              Uri.parse('$baseUrl/me'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));
      }

      var response = await doGet();

      // Un reintento con refresh si 401 (token ya muerto antes del skew).
      if (response.statusCode == 401) {
        final recovered = await recoverFromUnauthorized();
        if (recovered) {
          token = await getToken();
          if (token != null) {
            response = await doGet();
          }
        } else {
          return {
            'success': false,
            'message': 'Sesión expirada',
            'unauthorized': true,
          };
        }
      }

      if (response.statusCode == 401) {
        await onUnauthorized(navigate: true);
        return {
          'success': false,
          'message': 'Sesión expirada',
          'unauthorized': true,
        };
      }
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'No se pudo cargar el perfil (${response.statusCode})',
        };
      }

      final data = jsonDecode(response.body);
      Map<String, dynamic>? userMap;
      if (data is Map<String, dynamic>) {
        userMap = data;
      } else if (data is Map) {
        userMap = Map<String, dynamic>.from(data);
      }
      if (userMap == null) {
        return {'success': false, 'message': 'Respuesta de perfil inválida'};
      }

      // Persistir rol para guards de catálogo (login también lo guarda).
      final role = roleFromUserMap(userMap);
      if (role.isNotEmpty) {
        await saveRole(role);
      }

      return {'success': true, 'user': userMap, 'role': role};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
