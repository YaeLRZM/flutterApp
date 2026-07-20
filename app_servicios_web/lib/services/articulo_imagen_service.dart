import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/data_config.dart';
import 'api_service.dart';

class ArticuloImagenService {
  /// URLs de galería del detalle. Con catálogo real: `GET /api/articulos/{id}`.
  bool get _useApi => kUseRealArticulosApi || !kUseMockData;

  Future<List<String>> fetchImagenesPorArticulo(int articuloId) async {
    if (!_useApi) {
      // FALLBACK mock aislado
      await Future.delayed(const Duration(milliseconds: 150));
      return List.generate(4, (i) => 'mock://articulo_${articuloId}_img_$i');
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/articulos/$articuloId'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar imágenes del artículo $articuloId (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) return const [];

    final imagenes = map['imagenes'];
    if (imagenes is! List || imagenes.isEmpty) {
      final flat = map['imagen_url']?.toString();
      if (flat != null && flat.isNotEmpty) return [flat];
      return const [];
    }

    final urls = <String>[];
    for (final raw in imagenes) {
      if (raw is Map && raw['url'] != null) {
        final u = raw['url'].toString();
        if (u.isNotEmpty) urls.add(u);
      }
    }
    return urls;
  }
}
