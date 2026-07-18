import '../config/data_config.dart';
import '../mock/mock_categorias.dart';
import '../models/categoria.dart';

class CategoriaService {
  /// TODO: API -> GET /api/categorias (solo `visible = true`)
  Future<List<Categoria>> fetchCategorias() async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return mockCategorias.where((c) => c.visible).toList();
    }

    throw UnimplementedError(
      'Conectar CategoriaService.fetchCategorias() a la API de Laravel',
    );
  }
}
