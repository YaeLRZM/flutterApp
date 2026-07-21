import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Favoritos del catálogo.
///
/// - **Autenticado (comprador):** fuente de verdad = API / base de datos
///   (`GET/POST/DELETE /api/favoritos`).
/// - **Invitado:** solo almacenamiento local del dispositivo.
/// - **Vendedor:** no puede marcar/desmarcar (UI + servicio + backend).
class FavoritosService extends ChangeNotifier {
  FavoritosService._();
  static final FavoritosService instance = FavoritosService._();

  static const _guestKey = 'favoritos_guest_v1';

  final Set<int> _favoritos = {};
  int? _ownerUserId;
  bool _ready = false;
  bool _syncing = false;

  bool get isReady => _ready;
  bool get usaBackend => _ownerUserId != null;

  bool esFavorito(int articuloId) => _favoritos.contains(articuloId);

  Set<int> get ids => Set.unmodifiable(_favoritos);

  Future<void> init() async {
    // Arranque: invitado local hasta que haya sesión.
    await _loadGuestLocal();
    _ready = true;
    notifyListeners();
  }

  /// Tras login/restore: carga favoritos reales del backend.
  /// Si había favoritos de invitado y el usuario no tiene aún, se migran a BD.
  Future<void> bindUser(int? userId) async {
    if (!_ready) {
      await init();
    }

    if (userId == null) {
      _ownerUserId = null;
      await _loadGuestLocal();
      notifyListeners();
      return;
    }

    _ownerUserId = userId;
    final guest = await _readSet(_guestKey);

    try {
      await _syncFromApi();
      // Migrar favoritos de invitado al backend (solo los que falten).
      if (guest.isNotEmpty) {
        for (final id in guest) {
          if (!_favoritos.contains(id)) {
            try {
              await _apiAgregar(id);
              _favoritos.add(id);
            } catch (_) {
              // No bloquear login por un ítem fallido.
            }
          }
        }
        await _writeSet(_guestKey, {});
        notifyListeners();
      }
    } catch (_) {
      // Sin red: no inventar; dejar set vacío o lo último sincronizado.
      // Si falló sync, no rellenar con local de usuario (evita “fantasmas”).
      if (_favoritos.isEmpty && guest.isNotEmpty) {
        // Offline post-login: mostrar guest temporalmente hasta poder sync.
        _favoritos
          ..clear()
          ..addAll(guest);
      }
      notifyListeners();
    }
  }

  Future<void> _loadGuestLocal() async {
    _ownerUserId = null;
    _favoritos
      ..clear()
      ..addAll(await _readSet(_guestKey));
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

  /// Recarga favoritos desde GET /api/favoritos (usuario autenticado).
  Future<void> refrescarDesdeApi() async {
    if (_ownerUserId == null) return;
    if (_syncing) return;
    await _syncFromApi();
    notifyListeners();
  }

  Future<void> _syncFromApi({bool alreadyRetried = false}) async {
    if (_ownerUserId == null) return;
    _syncing = true;
    try {
      final headers =
          await ApiService().getAuthHeaders(includeContentType: false);
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/favoritos'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        if (!alreadyRetried) {
          final recovered = await ApiService().recoverFromUnauthorized();
          if (recovered) {
            return _syncFromApi(alreadyRetried: true);
          }
        }
        throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      }
      if (response.statusCode == 403) {
        _favoritos.clear();
        return;
      }
      if (response.statusCode != 200) {
        throw Exception(
          'No se pudieron cargar favoritos (${response.statusCode})',
        );
      }

      final ids = <int>{};
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final meta = decoded['meta'];
        if (meta is Map && meta['articulo_ids'] is List) {
          for (final e in meta['articulo_ids'] as List) {
            final id = e is int ? e : int.tryParse(e.toString());
            if (id != null && id > 0) ids.add(id);
          }
        } else {
          final data = decoded['data'];
          if (data is List) {
            for (final e in data) {
              if (e is Map) {
                final id = e['id'] is int
                    ? e['id'] as int
                    : int.tryParse(e['id']?.toString() ?? '') ??
                        int.tryParse(e['articulo_id']?.toString() ?? '');
                if (id != null && id > 0) ids.add(id);
              }
            }
          }
        }
      }

      _favoritos
        ..clear()
        ..addAll(ids);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _apiAgregar(int articuloId, {bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/favoritos'),
          headers: headers,
          body: jsonEncode({'articulo_id': articuloId}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return _apiAgregar(articuloId, alreadyRetried: true);
        }
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception(ApiService.msgAccionNoPermitidaVendedor);
    }
    if (response.statusCode == 422) {
      throw Exception('No se pudo guardar el favorito.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al guardar favorito (${response.statusCode})',
      );
    }
  }

  Future<void> _apiQuitar(int articuloId, {bool alreadyRetried = false}) async {
    final headers =
        await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http
        .delete(
          Uri.parse('${ApiService.baseUrl}/favoritos/$articuloId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return _apiQuitar(articuloId, alreadyRetried: true);
        }
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception(ApiService.msgAccionNoPermitidaVendedor);
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Error al quitar favorito (${response.statusCode})',
      );
    }
  }

  /// Alterna favorito. Con sesión: API primero (optimistic UI con rollback).
  Future<void> toggle(int articuloId) async {
    if (await ApiService().isVendedor()) {
      throw Exception(ApiService.msgAccionNoPermitidaVendedor);
    }
    if (articuloId <= 0) return;

    final wasFav = _favoritos.contains(articuloId);

    // Optimistic UI
    if (wasFav) {
      _favoritos.remove(articuloId);
    } else {
      _favoritos.add(articuloId);
    }
    notifyListeners();

    try {
      if (_ownerUserId != null) {
        if (wasFav) {
          await _apiQuitar(articuloId);
        } else {
          await _apiAgregar(articuloId);
        }
      } else {
        // Invitado: solo local.
        await _writeSet(_guestKey, _favoritos);
      }
    } catch (e) {
      // Revertir UI si falló la API.
      if (wasFav) {
        _favoritos.add(articuloId);
      } else {
        _favoritos.remove(articuloId);
      }
      notifyListeners();
      rethrow;
    }
  }
}
