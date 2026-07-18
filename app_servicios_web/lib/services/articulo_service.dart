import '../config/data_config.dart';
import '../mock/mock_articulos.dart';
import '../models/articulo.dart';

/// Punto único de acceso a los artículos. La UI SIEMPRE llama a este
/// servicio, nunca a `mock_articulos.dart` directamente, para que el día
/// de mañana solo se edite este archivo.
class ArticuloService {
  /// Regresa el feed principal de artículos (home).
  ///
  /// TODO: API -> GET /api/articulos?page=1
  /// Debe regresar algo paginado desde Laravel; aquí simulamos cortando
  /// la lista mock a `limit`.
  Future<List<Articulo>> fetchArticulos({int limit = kMaxArticulosHome}) async {
    if (kUseMockData) {
      // Simula latencia de red para que los loaders/FutureBuilder se
      // comporten igual que con la API real.
      await Future.delayed(const Duration(milliseconds: 300));
      return mockArticulos.take(limit).toList();
    }

    // TODO: API -> reemplazar por una llamada http (dio/http package),
    // parseando con Articulo.fromJson por cada elemento de "data".
    throw UnimplementedError(
      'Conectar ArticuloService.fetchArticulos() a la API de Laravel',
    );
  }

  /// Regresa un artículo específico (para la vista de detalle).
  ///
  /// TODO: API -> GET /api/articulos/{id}
  Future<Articulo?> fetchArticuloPorId(int id) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        return mockArticulos.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchArticuloPorId() a la API de Laravel',
    );
  }

  /// Regresa otros artículos del mismo artesano (sección "Más obras de...").
  ///
  /// TODO: API -> GET /api/artesanos/{artesanoId}/articulos?exclude={excludeId}
  Future<List<Articulo>> fetchArticulosPorArtesano(
    int artesanoId, {
    int excludeId = -1,
    int limit = 4,
  }) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return mockArticulos
          .where((a) => a.artesanoId == artesanoId && a.id != excludeId)
          .take(limit)
          .toList();
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchArticulosPorArtesano() a la API de Laravel',
    );
  }

  /// Regresa los artículos en "oferta relámpago" (con mayor descuento).
  ///
  /// TODO: API -> GET /api/articulos/ofertas-relampago
  Future<List<Articulo>> fetchOfertasRelampago({int limit = 2}) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final conDescuento = mockArticulos.where((a) => a.tieneDescuento).toList()
        ..sort(
          (a, b) => b.descuentoPorcentaje!.compareTo(a.descuentoPorcentaje!),
        );
      return conDescuento.take(limit).toList();
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchOfertasRelampago() a la API de Laravel',
    );
  }

  /// Regresa artículos con descuento para el banner promocional
  /// "Prendas con descuento".
  ///
  /// TODO: API -> GET /api/articulos?con_descuento=1
  Future<List<Articulo>> fetchArticulosConDescuento({int limit = 2}) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      final conDescuento = mockArticulos
          .where((a) => a.tieneDescuento)
          .toList();
      return conDescuento.take(limit).toList();
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchArticulosConDescuento() a la API de Laravel',
    );
  }
}
