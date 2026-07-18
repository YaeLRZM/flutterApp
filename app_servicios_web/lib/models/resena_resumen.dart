/// Resumen de calificación de un artículo (promedio + total de reseñas).
///
/// TODO: API -> probablemente vendrá de una tabla `resenas` con
/// `articulo_id`, `usuario_id`, `calificacion`, `comentario`. Por ahora
/// solo necesitamos el agregado para pintar las estrellas del detalle.
class ResenaResumen {
  final double promedio; // 0.0 - 5.0
  final int total;

  const ResenaResumen({required this.promedio, required this.total});

  factory ResenaResumen.fromJson(Map<String, dynamic> json) {
    return ResenaResumen(
      promedio: double.parse(json['promedio'].toString()),
      total: json['total'],
    );
  }
}
