import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoritos en memoria + **persistencia local durable**.
///
/// - Invitado: `favoritos_guest_v1`
/// - Usuario: `favoritos_u_{id}_v1`
///
/// Merge al login: si el usuario no tiene favoritos y el invitado sí,
/// se migran al usuario.
class FavoritosService extends ChangeNotifier {
  FavoritosService._();
  static final FavoritosService instance = FavoritosService._();

  static const _guestKey = 'favoritos_guest_v1';

  final Set<int> _favoritos = {};
  int? _ownerUserId;
  bool _ready = false;
  bool get isReady => _ready;

  bool esFavorito(int articuloId) => _favoritos.contains(articuloId);

  Set<int> get ids => Set.unmodifiable(_favoritos);

  String _storageKey(int? userId) =>
      userId == null ? _guestKey : 'favoritos_u_${userId}_v1';

  Future<void> init() async {
    await _loadFor(null);
    _ready = true;
    notifyListeners();
  }

  Future<void> bindUser(int? userId) async {
    if (!_ready) {
      await init();
    }

    await _persist();

    if (userId == _ownerUserId) {
      return;
    }

    if (userId != null) {
      final guest = await _readSet(_guestKey);
      await _loadFor(userId);
      if (_favoritos.isEmpty && guest.isNotEmpty) {
        _favoritos.addAll(guest);
        await _persist();
        await _writeSet(_guestKey, {});
      }
    } else {
      await _loadFor(null);
    }

    notifyListeners();
  }

  Future<void> _loadFor(int? userId) async {
    _ownerUserId = userId;
    _favoritos
      ..clear()
      ..addAll(await _readSet(_storageKey(userId)));
  }

  Future<Set<int>> _readSet(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      final out = <int>{};
      for (final e in decoded) {
        final id = e is int ? e : int.tryParse(e.toString());
        if (id != null && id > 0) out.add(id);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeSet(String key, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(ids.toList()..sort()));
  }

  Future<void> _persist() async {
    await _writeSet(_storageKey(_ownerUserId), _favoritos);
  }

  Future<void> toggle(int articuloId) async {
    if (_favoritos.contains(articuloId)) {
      _favoritos.remove(articuloId);
    } else {
      _favoritos.add(articuloId);
    }
    notifyListeners();
    await _persist();
  }
}
