import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/data_config.dart';
import '../mock/mock_artesanos.dart';
import '../models/artesano.dart';
import 'api_service.dart';

class ArtesanoService {
  /// Misma política que el catálogo principal de artículos.
  bool get _useApi => kUseRealArticulosApi || !kUseMockData;

  Future<List<Artesano>> fetchTodos() async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 150));
      return List<Artesano>.from(mockArtesanos);
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/artesanos'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar artesanos (${response.statusCode})',
      );
    }
    return _parseList(response.body);
  }

  Future<Artesano?> fetchArtesanoPorId(int id) async {
    if (!_useApi) {
      await Future.delayed(const Duration(milliseconds: 150));
      try {
        return mockArtesanos.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/artesanos/$id'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar artesano $id (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) return null;
    return Artesano.fromJson(map);
  }

  List<Artesano> _parseList(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      raw = decoded['data'] as List<dynamic>;
    } else {
      return const [];
    }
    final out = <Artesano>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(Artesano.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }
}
