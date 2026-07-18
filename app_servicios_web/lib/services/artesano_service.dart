import '../config/data_config.dart';
import '../mock/mock_artesanos.dart';
import '../models/artesano.dart';

class ArtesanoService {
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
