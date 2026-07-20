class Venta {
  final int id;
  final int userId;
  final int tiendaId;
  final int? formaPagoId;
  final double total;
  final String estado;
  final DateTime? createdAt;
  final int detalleCount;

  const Venta({
    required this.id,
    required this.userId,
    required this.tiendaId,
    this.formaPagoId,
    required this.total,
    required this.estado,
    this.createdAt,
    this.detalleCount = 0,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    double asDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return Venta(
      id: asInt(json['id']),
      userId: asInt(json['user_id']),
      tiendaId: asInt(json['tienda_id']),
      formaPagoId: json['forma_pago_id'] == null
          ? null
          : asInt(json['forma_pago_id']),
      total: asDouble(json['total']),
      estado: json['estado']?.toString() ?? '',
      createdAt: asDate(json['created_at']),
      detalleCount: asInt(
        json['detalle_ventas_count'] ??
            (json['detalle_ventas'] is List
                ? (json['detalle_ventas'] as List).length
                : 0),
      ),
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
