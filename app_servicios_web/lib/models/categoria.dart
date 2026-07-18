/// Representa un registro de la tabla `categorias`.
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagen;
  final bool visible;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagen,
    this.visible = true,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      visible: json['visible'] ?? true,
    );
  }
}
