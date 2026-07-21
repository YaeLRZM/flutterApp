import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notificacion.dart';
import 'api_service.dart';

class NotificacionService {
  Future<NotificacionesListResult> fetchNotificaciones({
    bool alreadyRetried = false,
  }) async {
    final headers =
        await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notificaciones'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return fetchNotificaciones(alreadyRetried: true);
        }
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar las notificaciones (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final items = <NotificacionApp>[];
    var count = 0;
    var noLeidas = 0;

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      if (data is List) {
        for (final e in data) {
          if (e is Map) {
            items.add(NotificacionApp.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      final meta = map['meta'];
      if (meta is Map) {
        final m = Map<String, dynamic>.from(meta);
        count = m['count'] is int
            ? m['count'] as int
            : int.tryParse(m['count']?.toString() ?? '') ?? items.length;
        noLeidas = m['no_leidas'] is int
            ? m['no_leidas'] as int
            : int.tryParse(m['no_leidas']?.toString() ?? '') ??
                items.where((n) => !n.leida).length;
      } else {
        count = items.length;
        noLeidas = items.where((n) => !n.leida).length;
      }
    }

    return NotificacionesListResult(
      items: items,
      count: count,
      noLeidas: noLeidas,
    );
  }

  Future<void> marcarLeida(int id, {bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/notificaciones/$id/leer'),
      headers: headers,
      body: '{}',
    );
    if (response.statusCode == 401 && !alreadyRetried) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) {
        return marcarLeida(id, alreadyRetried: true);
      }
    }
  }

  Future<void> marcarTodasLeidas({bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/notificaciones/leer-todas'),
      headers: headers,
      body: '{}',
    );
    if (response.statusCode == 401 && !alreadyRetried) {
      final recovered = await ApiService().recoverFromUnauthorized();
      if (recovered) {
        return marcarTodasLeidas(alreadyRetried: true);
      }
    }
  }
}
