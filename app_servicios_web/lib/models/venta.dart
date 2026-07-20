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

/// Línea de detalle de venta (campos reales de `detalle_ventas`).
class DetalleVentaLinea {
  final int id;
  final int articuloId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DetalleVentaLinea({
    required this.id,
    required this.articuloId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
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
    );
  }

  /// Sin join de nombre en backend: etiqueta neutra.
  String get etiquetaArticulo => 'Artículo #$articuloId';
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
    );
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
