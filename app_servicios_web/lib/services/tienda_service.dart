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

  /// Actualiza la tienda del vendedor autenticado.
  /// PUT /api/tiendas/{id} — backend exige ownership (no tiendas ajenas).
  Future<Tienda> updateTienda(
    int id,
    Map<String, dynamic> fields, {
    bool alreadyRetried = false,
  }) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/tiendas/$id'),
      headers: headers,
      body: jsonEncode(fields),
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return updateTienda(id, fields, alreadyRetried: true);
        }
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para editar esta tienda.');
    }
    if (response.statusCode == 422) {
      throw Exception('Datos inválidos. Revisa nombre y descripción.');
    }
    if (response.statusCode != 200) {
      throw Exception('Error al guardar tienda (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['tienda'] is Map) {
      map = Map<String, dynamic>.from(decoded['tienda'] as Map);
    } else if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) {
      throw Exception('Respuesta de tienda inválida');
    }
    return Tienda.fromJson(map);
  }
}
