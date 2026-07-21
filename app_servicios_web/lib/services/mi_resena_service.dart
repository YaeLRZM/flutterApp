import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class MiResenaItem {
  final int id;
  final int articuloId;
  final String articuloNombre;
  final int calificacion;
  final String comentario;
  final DateTime? createdAt;

  const MiResenaItem({
    required this.id,
    required this.articuloId,
    required this.articuloNombre,
    required this.calificacion,
    required this.comentario,
    this.createdAt,
  });

  MiResenaItem copyWith({
    int? calificacion,
    String? comentario,
    String? articuloNombre,
  }) {
    return MiResenaItem(
      id: id,
      articuloId: articuloId,
      articuloNombre: articuloNombre ?? this.articuloNombre,
      calificacion: calificacion ?? this.calificacion,
      comentario: comentario ?? this.comentario,
      createdAt: createdAt,
    );
  }

  factory MiResenaItem.fromJson(Map<String, dynamic> json) {
    final art = json['articulo'];
    String nombre = 'Artículo';
    int artId = 0;
    if (art is Map) {
      nombre = (art['nombre'] ?? 'Artículo').toString();
      final aid = art['id'];
      artId = aid is int ? aid : int.tryParse(aid?.toString() ?? '') ?? 0;
    }
    if (artId == 0) {
      final raw = json['articulo_id'];
      artId = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
    }
    final id = json['id'];
    final cal = json['calificacion'];
    return MiResenaItem(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      articuloId: artId,
      articuloNombre: nombre,
      calificacion:
          cal is int ? cal : int.tryParse(cal?.toString() ?? '') ?? 0,
      comentario: (json['comentario'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class MiResenaService {
  String _err(String body, int status, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
        final msg = decoded['message'] ?? decoded['mensaje'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
    } catch (_) {}
    return '$fallback ($status)';
  }

  Future<List<MiResenaItem>> fetchMias({bool alreadyRetried = false}) async {
    final headers =
        await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/mis-resenas'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) return fetchMias(alreadyRetried: true);
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        _err(response.body, response.statusCode, 'No se pudieron cargar tus opiniones'),
      );
    }

    final decoded = jsonDecode(response.body);
    final raw = decoded is Map && decoded['data'] is List
        ? decoded['data'] as List
        : (decoded is List ? decoded : const []);
    final out = <MiResenaItem>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(MiResenaItem.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }

  /// PUT /api/opiniones/{id}
  Future<MiResenaItem> actualizar({
    required int id,
    required int calificacion,
    required String comentario,
    bool alreadyRetried = false,
  }) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/opiniones/$id'),
      headers: headers,
      body: jsonEncode({
        'calificacion': calificacion,
        'comentario': comentario,
      }),
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return actualizar(
            id: id,
            calificacion: calificacion,
            comentario: comentario,
            alreadyRetried: true,
          );
        }
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No puedes editar esta opinión.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        _err(response.body, response.statusCode, 'No se pudo actualizar la opinión'),
      );
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['resena'] is Map) {
      map = Map<String, dynamic>.from(decoded['resena'] as Map);
    } else if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) {
      throw Exception('Respuesta de actualización inválida');
    }
    return MiResenaItem.fromJson(map);
  }

  /// DELETE /api/opiniones/{id}
  Future<void> eliminar(int id, {bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/opiniones/$id'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) return eliminar(id, alreadyRetried: true);
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No puedes eliminar esta opinión.');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        _err(response.body, response.statusCode, 'No se pudo eliminar la opinión'),
      );
    }
  }
}
