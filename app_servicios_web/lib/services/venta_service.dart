import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/venta.dart';
import 'api_service.dart';

class VentaService {
  /// GET /api/ventas — el backend filtra por ownership (tienda del vendedor).
  Future<VentasListResult> fetchMisVentas() async {
    final headers = await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ventas'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para ver ventas.');
    }
    if (response.statusCode != 200) {
      throw Exception('Error al cargar ventas (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    List<dynamic> rawList = const [];
    int count = 0;
    double suma = 0;

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      if (data is List) {
        rawList = data;
      }
      final meta = map['meta'];
      if (meta is Map) {
        final m = Map<String, dynamic>.from(meta);
        count = m['count'] is int
            ? m['count'] as int
            : int.tryParse(m['count']?.toString() ?? '') ?? rawList.length;
        final s = m['suma_totales'];
        if (s is num) {
          suma = s.toDouble();
        } else {
          suma = double.tryParse(s?.toString() ?? '') ?? 0;
        }
      } else {
        count = rawList.length;
      }
    } else if (decoded is List) {
      // Compatibilidad con respuesta antigua (array plano).
      rawList = decoded;
      count = rawList.length;
    }

    final ventas = <Venta>[];
    for (final item in rawList) {
      if (item is Map) {
        ventas.add(Venta.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    if (suma == 0 && ventas.isNotEmpty) {
      suma = ventas.fold<double>(0, (acc, v) => acc + v.total);
    }
    if (count == 0) count = ventas.length;

    return VentasListResult(
      ventas: ventas,
      count: count,
      sumaTotales: suma,
    );
  }
}
