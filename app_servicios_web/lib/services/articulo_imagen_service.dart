import '../config/data_config.dart';

class ArticuloImagenService {
  /// Regresa la lista de URLs de imágenes de un artículo para la galería
  /// de detalle. Mientras no exista la tabla real, se generan 4
  /// identificadores falsos por artículo (los widgets solo pintan un
  /// contenedor gris al ver que empiezan con "mock://").
  ///
  /// TODO: API -> GET /api/articulos/{id}/imagenes
  /// (probablemente una tabla `articulo_imagenes` con `orden`).
  Future<List<String>> fetchImagenesPorArticulo(int articuloId) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return List.generate(4, (i) => 'mock://articulo_${articuloId}_img_$i');
    }

    throw UnimplementedError(
      'Conectar ArticuloImagenService.fetchImagenesPorArticulo() a la API de Laravel',
    );
  }
}
