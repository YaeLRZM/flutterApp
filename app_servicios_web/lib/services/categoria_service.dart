import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/data_config.dart';
import '../mock/mock_categorias.dart';
import '../models/categoria.dart';
import 'api_service.dart';

class CategoriaService {
  /// API real para categorías (flujo principal catálogo).
  bool get _useApi => kUseRealCategoriasApi || !kUseMockData;

  List<Categoria> _parseList(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      raw = decoded['data'] as List<dynamic>;
    } else {
      return const [];
    }

    final out = <Categoria>[];
    for (final e in raw) {
      if (e is Map) {
        final cat = Categoria.fromJson(Map<String, dynamic>.from(e));
        if (cat.visible) out.add(cat);
      }
    }
    return out;
  }

  Future<List<Categoria>> _fetchFromApi() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/categorias'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar categorías (${response.statusCode})',
      );
    }
    return _parseList(response.body);
  }

  /// Agregador local "Todo" (id 0) para el menú del Home; no existe en Laravel.
  Categoria get _todoAgregador => const Categoria(
        id: 0,
        nombre: 'Todo',
        esGeneral: true,
        visible: true,
      );

  /// GET /api/categorias (visibles) + chip "Todo" al inicio.
  Future<List<Categoria>> fetchCategorias() async {
    if (!_useApi) {
      // FALLBACK AISLADO (mock) — solo si se desactiva kUseRealCategoriasApi.
      await Future.delayed(const Duration(milliseconds: 150));
      return mockCategorias.where((c) => c.visible).toList();
    }

    final cats = await _fetchFromApi();
    return [_todoAgregador, ...cats];
  }

  /// Colecciones: sin "Todo", destacadas primero (si el flag viene en JSON).
  Future<List<Categoria>> fetchCategoriasColecciones() async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 150));
      final categorias =
          mockCategorias.where((c) => c.visible && !c.esGeneral).toList()
            ..sort((a, b) {
              if (a.destacada == b.destacada) return 0;
              return a.destacada ? -1 : 1;
            });
      return categorias;
    }

    final cats = await _fetchFromApi();
    final list = cats.where((c) => !c.esGeneral).toList()
      ..sort((a, b) {
        if (a.destacada == b.destacada) return a.nombre.compareTo(b.nombre);
        return a.destacada ? -1 : 1;
      });
    return list;
  }
}
