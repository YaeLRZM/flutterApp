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
        'No se pudieron cargar tus opiniones (${response.statusCode})',
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
}
