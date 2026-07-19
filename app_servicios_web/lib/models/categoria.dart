/// Representa un registro de la tabla `categorias`.
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagen;
  final bool visible;

  /// TODO: API -> no existe aún en la migración compartida. Se usa para
  /// destacar una categoría con la etiqueta "CURADURÍA PREMIUM" en la
  /// vista de Colecciones. Si no agregan la columna, se puede derivar de
  /// otra señal (ej. más artículos vendidos en esa categoría).
  final bool destacada;

  /// Marca la categoría "Todo" (agregador usado en el menú del Home).
  /// No debe mostrarse como tarjeta en la vista de Colecciones.
  final bool esGeneral;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagen,
    this.visible = true,
    this.destacada = false,
    this.esGeneral = false,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      visible: json['visible'] ?? true,
      destacada: json['destacada'] ?? false,
      esGeneral: json['es_general'] ?? false,
    );
  }
}
