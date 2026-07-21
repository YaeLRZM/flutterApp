import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Línea de carrito con reserva temporal (backend).
class CarritoLinea {
  final int articuloId;
  final int cantidad;
  final DateTime? expiresAt;
  final String? nombre;
  final double? precioUnitario;

  const CarritoLinea({
    required this.articuloId,
    required this.cantidad,
    this.expiresAt,
    this.nombre,
    this.precioUnitario,
  });

  Duration? get tiempoRestante {
    if (expiresAt == null) return null;
    final left = expiresAt!.toLocal().difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get vencida {
    final t = tiempoRestante;
    return t != null && t == Duration.zero;
  }
}

/// Carrito: local (invitado) o remoto con reserva de stock (usuario auth).
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instance = CarritoService._();

  static const _guestKey = 'carrito_guest_v1';

  final Map<int, int> _cantidades = {};
  final Map<int, DateTime?> _expiresAt = {};
  final Map<int, String?> _nombres = {};

  int? _ownerUserId;
  bool _ready = false;
  int _ultimaLiberacion = 0;

  bool get isReady => _ready;
  bool get usaReservaRemota => _ownerUserId != null;
  int get reservasLiberadasRecientes => _ultimaLiberacion;

  Map<int, int> get cantidades => Map.unmodifiable(_cantidades);

  int get totalArticulos =>
      _cantidades.values.fold<int>(0, (acc, c) => acc + c);

  bool contiene(int articuloId) => _cantidades.containsKey(articuloId);

  int cantidadDe(int articuloId) => _cantidades[articuloId] ?? 0;

  DateTime? expiresAtDe(int articuloId) => _expiresAt[articuloId];

  List<CarritoLinea> get lineas {
    return _cantidades.entries
        .map(
          (e) => CarritoLinea(
            articuloId: e.key,
            cantidad: e.value,
            expiresAt: _expiresAt[e.key],
            nombre: _nombres[e.key],
          ),
        )
        .toList();
  }

  String _storageKey(int? userId) =>
      userId == null ? _guestKey : 'carrito_u_${userId}_v1';

  Future<void> init() async {
    await _loadFor(null);
    _ready = true;
    notifyListeners();
  }

  Future<void> bindUser(int? userId) async {
    if (!_ready) await init();

    if (userId == null) {
      if (_ownerUserId != null) {
        // Logout: no tocar carrito remoto; volver a guest local.
        await _loadFor(null);
        notifyListeners();
      }
      return;
    }

    if (userId == _ownerUserId) {
      await sincronizarRemoto();
      return;
    }

    // Login: migrar guest → remoto si aplica.
    final guestMap = Map<int, int>.from(_cantidades);
    _ownerUserId = userId;
    _cantidades.clear();
    _expiresAt.clear();
    _nombres.clear();

    try {
      await sincronizarRemoto();
      if (_cantidades.isEmpty && guestMap.isNotEmpty) {
        for (final e in guestMap.entries) {
          try {
            await agregar(e.key, cantidad: e.value);
          } catch (_) {
            // Stock insuficiente u otro: se omite ese ítem.
          }
        }
      }
      await _writeMap(_guestKey, {});
    } catch (_) {
      // Si falla red, al menos guarda local del usuario.
      _cantidades.addAll(guestMap);
      await _persistLocal();
    }
    notifyListeners();
  }

  /// Sincroniza con backend. [notify] false evita bucles cuando la vista
  /// ya está en medio de un reload y solo necesita el snapshot.
  Future<void> sincronizarRemoto({bool notify = true}) async {
    if (_ownerUserId == null) return;
    final headers =
        await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/mi-carrito'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) return sincronizarRemoto(notify: notify);
      return;
    }
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el carrito');
    }
    _applyRemoteBody(response.body);
    if (notify) notifyListeners();
  }

  void _applyRemoteBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return;
    final map = Map<String, dynamic>.from(decoded);
    final data = map['data'];
    final meta = map['meta'];
    if (meta is Map) {
      _ultimaLiberacion = meta['liberados'] is int
          ? meta['liberados'] as int
          : int.tryParse(meta['liberados']?.toString() ?? '') ?? 0;
    } else {
      _ultimaLiberacion = 0;
    }

    _cantidades.clear();
    _expiresAt.clear();
    _nombres.clear();
    if (data is List) {
      for (final raw in data) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final id = item['articulo_id'] is int
            ? item['articulo_id'] as int
            : int.tryParse(item['articulo_id']?.toString() ?? '');
        final qty = item['cantidad'] is int
            ? item['cantidad'] as int
            : int.tryParse(item['cantidad']?.toString() ?? '') ?? 0;
        if (id == null || qty <= 0) continue;
        _cantidades[id] = qty;
        final exp = item['expires_at']?.toString();
        _expiresAt[id] = exp != null ? DateTime.tryParse(exp) : null;
        final art = item['articulo'];
        if (art is Map) {
          _nombres[id] = art['nombre']?.toString();
        }
      }
    }
  }

  Future<void> _loadFor(int? userId) async {
    _ownerUserId = userId;
    _cantidades
      ..clear()
      ..addAll(await _readMap(_storageKey(userId)));
    _expiresAt.clear();
    _nombres.clear();
  }

  Future<Map<int, int>> _readMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <int, int>{};
      decoded.forEach((k, v) {
        final id = int.tryParse(k.toString());
        final qty = v is int ? v : int.tryParse(v.toString());
        if (id != null && qty != null && qty > 0) out[id] = qty;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMap(String key, Map<int, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    if (map.isEmpty) {
      await prefs.remove(key);
      return;
    }
    final encoded = <String, int>{
      for (final e in map.entries) e.key.toString(): e.value,
    };
    await prefs.setString(key, jsonEncode(encoded));
  }

  Future<void> _persistLocal() async {
    if (_ownerUserId != null) return; // remoto es fuente de verdad
    await _writeMap(_storageKey(null), _cantidades);
  }

  String _errFromBody(String body, int status) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        final msg = decoded['message'] ?? decoded['mensaje'];
        if (msg != null) return msg.toString();
      }
    } catch (_) {}
    return 'No se pudo actualizar el carrito ($status)';
  }

  Future<void> agregar(int articuloId, {int cantidad = 1}) async {
    if (cantidad <= 0) return;

    // Guard central: cuentas vendedor no usan el carrito de compra.
    if (await ApiService().isVendedor()) {
      throw Exception(ApiService.msgAccionNoPermitidaVendedor);
    }

    if (_ownerUserId == null) {
      _cantidades[articuloId] = (_cantidades[articuloId] ?? 0) + cantidad;
      notifyListeners();
      await _persistLocal();
      return;
    }

    final headers = await ApiService().getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/mi-carrito/items'),
          headers: headers,
          body: jsonEncode({
            'articulo_id': articuloId,
            'cantidad': cantidad,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) return agregar(articuloId, cantidad: cantidad);
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_errFromBody(response.body, response.statusCode));
    }
    _applyRemoteBody(response.body);
    notifyListeners();
  }

  Future<void> actualizarCantidad(int articuloId, int nuevaCantidad) async {
    if (_ownerUserId == null) {
      if (nuevaCantidad <= 0) {
        _cantidades.remove(articuloId);
      } else {
        _cantidades[articuloId] = nuevaCantidad;
      }
      notifyListeners();
      await _persistLocal();
      return;
    }

    final headers = await ApiService().getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('${ApiService.baseUrl}/mi-carrito/items/$articuloId'),
          headers: headers,
          body: jsonEncode({'cantidad': nuevaCantidad}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) {
        return actualizarCantidad(articuloId, nuevaCantidad);
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception(_errFromBody(response.body, response.statusCode));
    }
    _applyRemoteBody(response.body);
    notifyListeners();
  }

  Future<void> quitar(int articuloId) async {
    if (_ownerUserId == null) {
      _cantidades.remove(articuloId);
      notifyListeners();
      await _persistLocal();
      return;
    }

    final headers = await ApiService().getAuthHeaders();
    final response = await http
        .delete(
          Uri.parse('${ApiService.baseUrl}/mi-carrito/items/$articuloId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) return quitar(articuloId);
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception(_errFromBody(response.body, response.statusCode));
    }
    _applyRemoteBody(response.body);
    notifyListeners();
  }

  Future<void> vaciar() async {
    if (_ownerUserId == null) {
      _cantidades.clear();
      notifyListeners();
      await _persistLocal();
      return;
    }

    final headers = await ApiService().getAuthHeaders();
    final response = await http
        .delete(
          Uri.parse('${ApiService.baseUrl}/mi-carrito'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) return vaciar();
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception(_errFromBody(response.body, response.statusCode));
    }
    _applyRemoteBody(response.body);
    notifyListeners();
  }
}
