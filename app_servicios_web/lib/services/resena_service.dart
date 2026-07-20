import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/resena.dart';
import '../models/resena_resumen.dart';
import 'api_service.dart';

class ResenaService {
  /// Lista reseñas de un artículo: GET /api/resenas?articulo_id=
  Future<List<Resena>> fetchPorArticulo(int articuloId) async {
    final uri = Uri.parse('${ApiService.baseUrl}/resenas').replace(
      queryParameters: {'articulo_id': articuloId.toString()},
    );
    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar reseñas (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      raw = decoded['data'] as List<dynamic>;
    } else {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((e) => Resena.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Resumen agregado a partir del listado real (sin endpoint extra).
  Future<ResenaResumen> fetchResumenPorArticulo(int articuloId) async {
    final list = await fetchPorArticulo(articuloId);
    if (list.isEmpty) {
      return const ResenaResumen(promedio: 0, total: 0);
    }
    final sum = list.fold<int>(0, (a, r) => a + r.calificacion);
    final promedio = sum / list.length;
    return ResenaResumen(
      promedio: double.parse(promedio.toStringAsFixed(1)),
      total: list.length,
    );
  }

  /// Crea reseña: POST /api/resenas (JWT + permiso crearResenas).
  Future<Map<String, dynamic>> crearResena({
    required int articuloId,
    required int calificacion,
    String? comentario,
  }) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/resenas'),
      headers: headers,
      body: jsonEncode({
        'articulo_id': articuloId,
        'calificacion': calificacion,
        if (comentario != null && comentario.trim().isNotEmpty)
          'comentario': comentario.trim(),
      }),
    );

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {'success': true, 'data': body};
    }

    return {
      'success': false,
      'message': body['message']?.toString() ??
          body['error']?.toString() ??
          'No se pudo publicar la reseña (${response.statusCode})',
    };
  }
}
