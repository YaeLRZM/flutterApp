import '../config/data_config.dart';
import '../models/resena_resumen.dart';

class ResenaService {
  /// Genera un resumen determinístico (mismo articuloId -> mismo
  /// resultado) para que no "brinque" cada vez que se reconstruye la UI.
  ///
  /// TODO: API -> GET /api/articulos/{id}/resenas/resumen
  Future<ResenaResumen> fetchResumenPorArticulo(int articuloId) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      final promedio = 4.0 + (articuloId % 10) / 10; // entre 4.0 y 4.9
      final total = 8 + (articuloId % 7) * 5; // entre 8 y 38
      return ResenaResumen(
        promedio: double.parse(promedio.toStringAsFixed(1)),
        total: total,
      );
    }

    throw UnimplementedError(
      'Conectar ResenaService.fetchResumenPorArticulo() a la API de Laravel',
    );
  }
}
