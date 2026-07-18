/// Representa al artesano/artesana dueño(a) de un `Articulo`.
///
/// NOTA: tu migración de `articulos` solo tiene `artesano_id` como FK,
/// pero no compartiste la migración de la tabla `artesanos`. Este modelo
/// se arma con los campos que la vista de detalle necesita mostrar; en
/// cuanto tengas esa migración, ajustamos los nombres de columna aquí y
/// en `Artesano.fromJson`.
class Artesano {
  final int id;
  final String nombre;

  /// Ej. "Maestra Artesana" / "Maestro Artesano".
  final String titulo;
  final String region;
  final bool verificado;

  /// TODO: API -> vendrá de una tabla de imágenes o de un storage.
  final String avatarUrl;

  const Artesano({
    required this.id,
    required this.nombre,
    required this.titulo,
    required this.region,
    this.verificado = false,
    required this.avatarUrl,
  });

  factory Artesano.fromJson(Map<String, dynamic> json) {
    return Artesano(
      id: json['id'],
      nombre: json['nombre'],
      titulo: json['titulo'] ?? 'Artesano',
      region: json['region'] ?? '',
      verificado: json['verificado'] ?? false,
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}
