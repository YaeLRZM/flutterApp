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

  /// Regresa las categorías para la vista de Colecciones: visibles y sin
  /// el agregador "Todo" (`esGeneral`), con las destacadas primero.
  ///
  /// TODO: API -> GET /api/categorias?es_general=0
  Future<List<Categoria>> fetchCategoriasColecciones() async {
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      final categorias =
          mockCategorias.where((c) => c.visible && !c.esGeneral).toList()
            ..sort((a, b) {
              if (a.destacada == b.destacada) return 0;
              return a.destacada ? -1 : 1;
            });
      return categorias;
    }

    throw UnimplementedError(
      'Conectar CategoriaService.fetchCategoriasColecciones() a la API de Laravel',
    );
  }
}
