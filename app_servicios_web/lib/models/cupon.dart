/// Representa un registro de la tabla `cupons`.
class Cupon {
  final int id;
  final int tiendaId;
  final String codigo;
  final int porcentajeDescuento;
  final int limiteUso;
  final DateTime fechaExpiracion;
  final double compraMinima;

  const Cupon({
    required this.id,
    required this.tiendaId,
    required this.codigo,
    required this.porcentajeDescuento,
    required this.limiteUso,
    required this.fechaExpiracion,
    required this.compraMinima,
  });

  bool get vigente => fechaExpiracion.isAfter(DateTime.now());

  /// Texto usado en las tarjetas de producto, ej. "Cupón del 15% disponible".
  String get textoCorto => 'Cupón del $porcentajeDescuento% disponible';

  factory Cupon.fromJson(Map<String, dynamic> json) {
    return Cupon(
      id: json['id'],
      tiendaId: json['tienda_id'],
      codigo: json['codigo'],
      porcentajeDescuento: json['porcentaje_descuento'],
      limiteUso: json['limite_uso'],
      fechaExpiracion: DateTime.parse(json['fecha_expiracion']),
      compraMinima: double.parse(json['compra_minima'].toString()),
    );
  }
}
