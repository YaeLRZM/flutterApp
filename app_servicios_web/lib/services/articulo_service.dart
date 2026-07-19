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

  /// Regresa cuántos artículos hay por cada categoría, ej. {2: 5, 4: 3}.
  /// Se usa en CollectionsView para mostrar "+N artículos" por categoría
  /// y las estadísticas del encabezado.
  ///
  /// TODO: API -> esto normalmente vendría ya calculado desde Laravel,
  /// ej. `Categoria::withCount('articulos')->get()`, en vez de contar en
  /// el cliente sobre la lista completa.
  Future<Map<int, int>> contarArticulosPorCategoria() async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      final conteo = <int, int>{};
      for (final articulo in mockArticulos) {
        conteo[articulo.categoriaId] = (conteo[articulo.categoriaId] ?? 0) + 1;
      }
      return conteo;
    }

    throw UnimplementedError(
      'Conectar ArticuloService.contarArticulosPorCategoria() a la API de Laravel',
    );
  }

  /// Regresa los artículos correspondientes a una lista de ids, en el
  /// mismo orden en que se pidieron. Usado por `FavoritesView`.
  ///
  /// TODO: API -> GET /api/articulos?ids=1,2,3
  Future<List<Articulo>> fetchArticulosPorIds(Iterable<int> ids) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      final idsList = ids.toList();
      final porId = {for (final a in mockArticulos) a.id: a};
      return idsList.map((id) => porId[id]).whereType<Articulo>().toList();
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchArticulosPorIds() a la API de Laravel',
    );
  }

  /// Regresa los artículos de una categoría (para CategoryDetailView).
  ///
  /// TODO: API -> GET /api/categorias/{categoriaId}/articulos?page=1
  Future<List<Articulo>> fetchArticulosPorCategoria(
    int categoriaId, {
    int limit = kMaxArticulosCategoria,
  }) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockArticulos
          .where((a) => a.categoriaId == categoriaId)
          .take(limit)
          .toList();
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchArticulosPorCategoria() a la API de Laravel',
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

  /// Regresa cuántos artículos hay por categoría, ej. {2: 14, 3: 8, ...}.
  /// Usado en las tarjetas de la vista de Colecciones ("+14 artículos").
  ///
  /// TODO: API -> GET /api/categorias/conteo-articulos
  /// (o venir ya incluido como `articulos_count` en `GET /api/categorias`
  /// si usan `withCount('articulos')` en el backend).
  Future<Map<int, int>> fetchConteoArticulosPorCategoria() async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      final conteo = <int, int>{};
      for (final articulo in mockArticulos) {
        conteo[articulo.categoriaId] = (conteo[articulo.categoriaId] ?? 0) + 1;
      }
      return conteo;
    }

    throw UnimplementedError(
      'Conectar ArticuloService.fetchConteoArticulosPorCategoria() a la API de Laravel',
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
