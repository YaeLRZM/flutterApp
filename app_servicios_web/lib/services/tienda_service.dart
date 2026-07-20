import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tienda.dart';
import 'api_service.dart';

class TiendaService {
  Future<Tienda?> fetchTiendaPorId(int id) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/tiendas/$id'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Error al cargar tienda $id (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) return null;
    return Tienda.fromJson(map);
  }
}
