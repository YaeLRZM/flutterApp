int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String? _nestedNombre(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is! Map) return null;
  final n = raw['nombre']?.toString().trim();
  if (n == null || n.isEmpty) return null;
  return n;
}

/// Línea de detalle de venta (campos reales de `detalle_ventas`).
class DetalleVentaLinea {
  final int id;
  final int articuloId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  /// Nombre real del artículo si el backend lo envía en `articulo.nombre`.
  final String? articuloNombre;

  const DetalleVentaLinea({
    required this.id,
    required this.articuloId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.articuloNombre,
  });

  factory DetalleVentaLinea.fromJson(Map<String, dynamic> json) {
    return DetalleVentaLinea(
      id: _asInt(json['id']),
      articuloId: _asInt(json['articulo_id']),
      cantidad: _asInt(json['cantidad']),
      precioUnitario: _asDouble(
        json['precio_unitario'] ?? json['precio'],
      ),
      subtotal: _asDouble(json['subtotal']),
      articuloNombre: _nestedNombre(json, 'articulo'),
    );
  }

  /// Nombre del backend si existe; si no, fallback neutro.
  String get etiquetaArticulo {
    final n = articuloNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Artículo #$articuloId';
  }
}

class Venta {
  final int id;
  final int userId;
  final int tiendaId;
  final int? formaPagoId;
  final double total;
  final String estado;
  final DateTime? createdAt;
  final int detalleCount;
  final List<DetalleVentaLinea> lineas;

  /// `user.nombre` si el backend lo envía en el show.
  final String? userNombre;

  /// `forma_pago.nombre` si el backend lo envía en el show.
  final String? formaPagoNombre;

  const Venta({
    required this.id,
    required this.userId,
    required this.tiendaId,
    this.formaPagoId,
    required this.total,
    required this.estado,
    this.createdAt,
    this.detalleCount = 0,
    this.lineas = const [],
    this.userNombre,
    this.formaPagoNombre,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    final rawDetalles = json['detalle_ventas'];
    final lineas = <DetalleVentaLinea>[];
    if (rawDetalles is List) {
      for (final item in rawDetalles) {
        if (item is Map) {
          lineas.add(
            DetalleVentaLinea.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return Venta(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      tiendaId: _asInt(json['tienda_id']),
      formaPagoId: json['forma_pago_id'] == null
          ? null
          : _asInt(json['forma_pago_id']),
      total: _asDouble(json['total']),
      estado: json['estado']?.toString() ?? '',
      createdAt: _asDate(json['created_at']),
      detalleCount: _asInt(
        json['detalle_ventas_count'] ??
            (lineas.isNotEmpty ? lineas.length : 0),
      ),
      lineas: lineas,
      userNombre: _nestedNombre(json, 'user'),
      formaPagoNombre: _nestedNombre(json, 'forma_pago'),
    );
  }

  String get etiquetaCliente {
    final n = userNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (userId > 0) return 'Usuario #$userId';
    return 'No disponible';
  }

  String get etiquetaFormaPago {
    final n = formaPagoNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (formaPagoId != null && formaPagoId! > 0) {
      return 'Forma de pago #$formaPagoId';
    }
    return 'No disponible';
  }
}

class VentasListResult {
  final List<Venta> ventas;
  final int count;
  final double sumaTotales;

  const VentasListResult({
    required this.ventas,
    required this.count,
    required this.sumaTotales,
  });
}
