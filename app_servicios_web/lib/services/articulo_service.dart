import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/data_config.dart';
import '../mock/mock_articulos.dart';
import '../models/articulo.dart';
import 'api_service.dart';

/// Punto único de acceso a los artículos. La UI SIEMPRE llama a este
/// servicio, nunca a `mock_articulos.dart` directamente.
class ArticuloService {
  /// API real solo para artículos (no apaga mocks globales).
  bool get _useApi => kUseRealArticulosApi || !kUseMockData;

  List<Articulo> _parseCollection(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> raw;
    if (decoded is Map && decoded['data'] is List) {
      raw = decoded['data'] as List<dynamic>;
    } else if (decoded is List) {
      raw = decoded;
    } else {
      return const [];
    }
    final out = <Articulo>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(Articulo.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }

  Articulo? _parseOne(String body) {
    final decoded = jsonDecode(body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) return null;
    return Articulo.fromJson(map);
  }

  Future<List<Articulo>> _getArticulos({
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/articulos').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar artículos (${response.statusCode})',
      );
    }
    return _parseCollection(response.body);
  }

  /// Feed principal de artículos (Inicio / home).
  /// Siempre usa Laravel (`GET /api/articulos`); no hay fallback a mock.
  Future<List<Articulo>> fetchArticulos({int limit = kMaxArticulosHome}) async {
    final list = await _getArticulos();
    if (list.isEmpty) {
      throw Exception('La API no devolvió artículos');
    }
    return list.take(limit).toList();
  }

  /// Cuántos artículos hay por cada categoría, ej. {2: 5, 4: 3}.
  Future<Map<int, int>> contarArticulosPorCategoria() async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 150));
      final conteo = <int, int>{};
      for (final articulo in mockArticulos) {
        conteo[articulo.categoriaId] = (conteo[articulo.categoriaId] ?? 0) + 1;
      }
      return conteo;
    }

    final list = await _getArticulos();
    final conteo = <int, int>{};
    for (final articulo in list) {
      conteo[articulo.categoriaId] = (conteo[articulo.categoriaId] ?? 0) + 1;
    }
    return conteo;
  }

  /// Artículos por ids (mismo orden). Usado por FavoritesView.
  Future<List<Articulo>> fetchArticulosPorIds(Iterable<int> ids) async {
    final idsList = ids.toList();
    if (idsList.isEmpty) return const [];

    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      final porId = {for (final a in mockArticulos) a.id: a};
      return idsList.map((id) => porId[id]).whereType<Articulo>().toList();
    }

    final list = await _getArticulos();
    final porId = {for (final a in list) a.id: a};
    return idsList.map((id) => porId[id]).whereType<Articulo>().toList();
  }

  /// Artículos de una categoría.
  Future<List<Articulo>> fetchArticulosPorCategoria(
    int categoriaId, {
    int limit = kMaxArticulosCategoria,
  }) async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockArticulos
          .where((a) => a.categoriaId == categoriaId)
          .take(limit)
          .toList();
    }

    final list = await _getArticulos(
      query: {'categoria': categoriaId.toString()},
    );
    return list.take(limit).toList();
  }

  /// Un artículo por id.
  Future<Articulo?> fetchArticuloPorId(int id) async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        return mockArticulos.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/articulos/$id'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar artículo $id (${response.statusCode})',
      );
    }
    return _parseOne(response.body);
  }

  /// Otros artículos del mismo artesano.
  Future<List<Articulo>> fetchArticulosPorArtesano(
    int artesanoId, {
    int excludeId = -1,
    int limit = 4,
  }) async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return mockArticulos
          .where((a) => a.artesanoId == artesanoId && a.id != excludeId)
          .take(limit)
          .toList();
    }

    final list = await _getArticulos(
      query: {'artesano': artesanoId.toString()},
    );
    return list.where((a) => a.id != excludeId).take(limit).toList();
  }

  /// Conteo por categoría (Colecciones).
  Future<Map<int, int>> fetchConteoArticulosPorCategoria() async {
    return contarArticulosPorCategoria();
  }

  /// Ofertas relámpago (caja superior de Inicio).
  /// Siempre consulta Laravel; sin descuento en API → lista vacía (no mock).
  Future<List<Articulo>> fetchOfertasRelampago({int limit = 2}) async {
    final list = await _getArticulos();
    final conDescuento = list.where((a) => a.tieneDescuento).toList()
      ..sort(
        (a, b) =>
            (b.descuentoPorcentaje ?? 0).compareTo(a.descuentoPorcentaje ?? 0),
      );
    return conDescuento.take(limit).toList();
  }

  /// Artículos con descuento (banner). Sin descuento en API → vacío.
  Future<List<Articulo>> fetchArticulosConDescuento({int limit = 2}) async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return mockArticulos.where((a) => a.tieneDescuento).take(limit).toList();
    }

    final list = await _getArticulos();
    return list.where((a) => a.tieneDescuento).take(limit).toList();
  }
}
