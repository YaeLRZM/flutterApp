import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class FormaPagoItem {
  final int id;
  final String nombre;

  const FormaPagoItem({required this.id, required this.nombre});

  factory FormaPagoItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return FormaPagoItem(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      nombre: (json['nombre'] ?? 'Sin nombre').toString().trim().isEmpty
          ? 'Sin nombre'
          : (json['nombre'] ?? 'Sin nombre').toString().trim(),
    );
  }
}

/// Catálogo de formas de pago: GET /api/formas-pago (lectura pública).
/// Envía JWT si hay sesión (consistente con otros clientes); no inventa datos.
class FormaPagoService {
  Future<List<FormaPagoItem>> fetchFormasPago({
    bool alreadyRetried = false,
  }) async {
    // Mismo patrón que otros listados: Accept + token si existe.
    final headers = await ApiService().getAuthHeaders(includeContentType: false);
    // getAuthHeaders siempre pone Accept; Authorization solo si hay token.
    // Si no hay sesión, igual es válido (endpoint público).

    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/formas-pago'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return fetchFormasPago(alreadyRetried: true);
        }
      }
      // Si el catálogo es público y aun así 401, no inventar datos.
      throw Exception(
        'No se pudieron cargar las formas de pago. Vuelve a iniciar sesión e intenta de nuevo.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para ver las formas de pago.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar las formas de pago (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final list = <FormaPagoItem>[];
    final raw = decoded is List
        ? decoded
        : (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : const [];
    for (final e in raw) {
      if (e is Map) {
        final item = FormaPagoItem.fromJson(Map<String, dynamic>.from(e));
        if (item.id > 0) list.add(item);
      }
    }
    return list;
  }
}
