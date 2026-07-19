import '../config/data_config.dart';
import '../mock/mock_artesanos.dart';
import '../models/artesano.dart';

class ArtesanoService {
  /// Regresa todos los artesanos (para armar un mapa id -> Artesano y
  /// evitar hacer una llamada por cada artículo de un listado).
  ///
  /// TODO: API -> lo ideal es que el propio endpoint de artículos venga
  /// con la relación `artesano` ya cargada (`with('artesano')` en
  /// Laravel), y así no haga falta este segundo fetch.
  Future<List<Artesano>> fetchTodos() async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return List<Artesano>.from(mockArtesanos);
    }

    throw UnimplementedError(
      'Conectar ArtesanoService.fetchTodos() a la API de Laravel',
    );
  }

  /// TODO: API -> GET /api/artesanos/{id}
  Future<Artesano?> fetchArtesanoPorId(int id) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      try {
        return mockArtesanos.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }

    throw UnimplementedError(
      'Conectar ArtesanoService.fetchArtesanoPorId() a la API de Laravel',
    );
  }
}
