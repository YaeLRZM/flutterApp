/// Reseña de un artículo (`resenas` en Laravel).
class Resena {
  final int id;
  final int articuloId;
  final int userId;
  final int calificacion;
  final String comentario;
  final String? autorNombre;

  const Resena({
    required this.id,
    required this.articuloId,
    required this.userId,
    required this.calificacion,
    required this.comentario,
    this.autorNombre,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    final user = json['user'];
    String? autor;
    if (user is Map) {
      autor = user['nombre']?.toString();
    }

    return Resena(
      id: asInt(json['id']),
      articuloId: asInt(json['articulo_id']),
      userId: asInt(json['user_id']),
      calificacion: asInt(json['calificacion'] ?? json['puntuacion']),
      comentario: (json['comentario'] ?? json['contenido'] ?? '').toString(),
      autorNombre: autor,
    );
  }
}
