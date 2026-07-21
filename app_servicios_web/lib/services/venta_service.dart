import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/venta.dart';
import 'api_service.dart';

class VentaService {
  /// GET /api/ventas — ownership por rol:
  /// vendedor → su tienda; user → sus compras (user_id).
  Future<VentasListResult> fetchMisVentas({bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ventas'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) return fetchMisVentas(alreadyRetried: true);
      } else {
        await ApiService().onUnauthorized();
      }
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

  /// Compra real mínima: POST /api/ventas
  /// Body: { items: [{ articulo_id, cantidad }, ...], forma_pago_id? }
  /// El backend calcula total, tienda_id, user_id y decrementa stock.
  Future<Venta> crearCompra({
    required Map<int, int> items,
    int? formaPagoId,
    bool alreadyRetried = false,
  }) async {
    if (await ApiService().isVendedor()) {
      throw Exception(ApiService.msgAccionNoPermitidaVendedor);
    }
    if (items.isEmpty) {
      throw Exception('El carrito está vacío.');
    }

    final payloadItems = items.entries
        .where((e) => e.value > 0)
        .map((e) => {
              'articulo_id': e.key,
              'cantidad': e.value,
            })
        .toList();

    if (payloadItems.isEmpty) {
      throw Exception('No hay artículos válidos para comprar.');
    }

    final body = <String, dynamic>{
      'items': payloadItems,
      if (formaPagoId != null) 'forma_pago_id': formaPagoId,
    };

    final headers = await ApiService().getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/ventas'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) {
          return crearCompra(
            items: items,
            formaPagoId: formaPagoId,
            alreadyRetried: true,
          );
        }
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Inicia sesión para comprar.');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para realizar compras.');
    }
    if (response.statusCode == 422) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final errors = decoded['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final first = errors.values.first;
            if (first is List && first.isNotEmpty) {
              throw Exception(first.first.toString());
            }
          }
          final msg = decoded['message']?.toString();
          if (msg != null && msg.isNotEmpty) {
            throw Exception(msg);
          }
        }
      } catch (e) {
        if (e is Exception && e.toString().startsWith('Exception:')) rethrow;
      }
      throw Exception('Datos de compra inválidos.');
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al registrar la compra (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['venta'] is Map) {
      map = Map<String, dynamic>.from(decoded['venta'] as Map);
    } else if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    }
    if (map == null) {
      throw Exception('Respuesta de compra inválida');
    }
    return Venta.fromJson(map);
  }

  /// Cancela compra del comprador: POST /api/ventas/{id}/cancelar
  /// Solo si el backend acepta (dueño + estado pendiente).
  Future<Venta> cancelarCompra(int id, {bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/ventas/$id/cancelar'),
      headers: headers,
      body: '{}',
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) return cancelarCompra(id, alreadyRetried: true);
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No puedes cancelar esta compra.');
    }
    if (response.statusCode == 422) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final msg = decoded['message']?.toString();
          if (msg != null && msg.isNotEmpty) throw Exception(msg);
          final errors = decoded['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final first = errors.values.first;
            if (first is List && first.isNotEmpty) {
              throw Exception(first.first.toString());
            }
          }
        }
      } catch (e) {
        if (e is Exception && e.toString().startsWith('Exception:')) rethrow;
      }
      throw Exception('Esta compra ya no se puede cancelar.');
    }
    if (response.statusCode != 200) {
      throw Exception('No se pudo cancelar la compra (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['venta'] is Map) {
      map = Map<String, dynamic>.from(decoded['venta'] as Map);
    } else if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    }
    if (map == null) {
      throw Exception('Respuesta de cancelación inválida');
    }
    return Venta.fromJson(map);
  }

  /// GET /api/ventas/{id} — ownership en backend (tienda o user_id).
  Future<Venta> fetchVentaPorId(int id, {bool alreadyRetried = false}) async {
    final headers = await ApiService().getAuthHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ventas/$id'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (!alreadyRetried) {
        final recovered = await ApiService().recoverFromUnauthorized();
        if (recovered) return fetchVentaPorId(id, alreadyRetried: true);
      } else {
        await ApiService().onUnauthorized();
      }
      throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para ver esta venta.');
    }
    if (response.statusCode == 404) {
      throw Exception('Venta no encontrada.');
    }
    if (response.statusCode != 200) {
      throw Exception('Error al cargar venta (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    Map<String, dynamic>? map;
    if (decoded is Map && decoded['venta'] is Map) {
      map = Map<String, dynamic>.from(decoded['venta'] as Map);
    } else if (decoded is Map && decoded['data'] is Map) {
      map = Map<String, dynamic>.from(decoded['data'] as Map);
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    }
    if (map == null) {
      throw Exception('Respuesta de venta inválida');
    }
    return Venta.fromJson(map);
  }
}
