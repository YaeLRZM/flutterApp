import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carrito de compras en memoria + **persistencia local durable**.
///
/// - Invitado: clave `carrito_guest_v1`
/// - Usuario autenticado: `carrito_u_{id}_v1`
///
/// Regla de merge al iniciar sesión:
/// - Si el usuario ya tiene carrito guardado → se usa el del usuario.
/// - Si el usuario no tiene carrito y el invitado sí → se migra el del invitado
///   al usuario y se limpia el de invitado.
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instance = CarritoService._();

  static const _guestKey = 'carrito_guest_v1';

  final Map<int, int> _cantidades = {};

  /// null = sesión invitada; si no, id de usuario autenticado.
  int? _ownerUserId;

  bool _ready = false;
  bool get isReady => _ready;

  /// Copia inmutable: articuloId -> cantidad.
  Map<int, int> get cantidades => Map.unmodifiable(_cantidades);

  int get totalArticulos =>
      _cantidades.values.fold<int>(0, (acc, c) => acc + c);

  bool contiene(int articuloId) => _cantidades.containsKey(articuloId);

  int cantidadDe(int articuloId) => _cantidades[articuloId] ?? 0;

  String _storageKey(int? userId) =>
      userId == null ? _guestKey : 'carrito_u_${userId}_v1';

  /// Carga el carrito de invitado (arranque de app).
  Future<void> init() async {
    await _loadFor(null);
    _ready = true;
    notifyListeners();
  }

  /// Tras login/registro/logout: cambia el “dueño” del carrito en disco.
  Future<void> bindUser(int? userId) async {
    if (!_ready) {
      await init();
    }

    // Persistir lo que haya en memoria bajo el dueño actual.
    await _persist();

    if (userId == _ownerUserId) {
      return;
    }

    if (userId != null) {
      final guestMap = await _readMap(_guestKey);
      await _loadFor(userId);
      // Merge: solo si el usuario no tenía carrito y el invitado sí.
      if (_cantidades.isEmpty && guestMap.isNotEmpty) {
        _cantidades.addAll(guestMap);
        await _persist();
        await _writeMap(_guestKey, {});
      }
    } else {
      // Logout: volver al carrito de invitado (no borrar el del usuario).
      await _loadFor(null);
    }

    notifyListeners();
  }

  Future<void> _loadFor(int? userId) async {
    _ownerUserId = userId;
    _cantidades
      ..clear()
      ..addAll(await _readMap(_storageKey(userId)));
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
        if (id != null && qty != null && qty > 0) {
          out[id] = qty;
        }
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

  Future<void> _persist() async {
    await _writeMap(_storageKey(_ownerUserId), _cantidades);
  }

  Future<void> agregar(int articuloId, {int cantidad = 1}) async {
    if (cantidad <= 0) return;
    _cantidades[articuloId] = (_cantidades[articuloId] ?? 0) + cantidad;
    notifyListeners();
    await _persist();
  }

  Future<void> actualizarCantidad(int articuloId, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      _cantidades.remove(articuloId);
    } else {
      _cantidades[articuloId] = nuevaCantidad;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> quitar(int articuloId) async {
    _cantidades.remove(articuloId);
    notifyListeners();
    await _persist();
  }

  Future<void> vaciar() async {
    _cantidades.clear();
    notifyListeners();
    await _persist();
  }
}
