class Tienda {
  final int id;
  final String nombre;
  final String? descripcion;

  const Tienda({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory Tienda.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return Tienda(
      id: id,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
    );
  }
}
