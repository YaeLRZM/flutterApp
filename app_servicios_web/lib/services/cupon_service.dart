import '../config/data_config.dart';
import '../mock/mock_cupones.dart';
import '../models/cupon.dart';

class CuponService {
  /// Regresa el cupón vigente de una tienda, si existe.
  ///
  /// TODO: API -> GET /api/tiendas/{tiendaId}/cupon-vigente
  Future<Cupon?> fetchCuponVigentePorTienda(int tiendaId) async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        return mockCupones.firstWhere(
          (c) => c.tiendaId == tiendaId && c.vigente,
        );
      } catch (_) {
        return null;
      }
    }

    throw UnimplementedError(
      'Conectar CuponService.fetchCuponVigentePorTienda() a la API de Laravel',
    );
  }
}
