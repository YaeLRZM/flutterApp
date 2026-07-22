/// Tienda del catálogo.
///
/// API real: `id`, `nombre`, `descripcion` (opcional).
/// Imagen y otros campos solo si el backend los envía.
class Tienda {
  final int id;
  final String nombre;
  final String? descripcion;

  /// Portada / logo si el API la expone.
  final String imagenUrl;

  /// Ubicación o procedencia opcional.
  final String ubicacion;

  /// Estilo o enfoque opcional.
  final String estilo;

  const Tienda({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl = '',
    this.ubicacion = '',
    this.estilo = '',
  });

  bool get tieneDescripcion =>
      descripcion != null && descripcion!.trim().isNotEmpty;
  bool get tieneImagen => imagenUrl.trim().isNotEmpty;
  bool get tieneUbicacion => ubicacion.trim().isNotEmpty;
  bool get tieneEstilo => estilo.trim().isNotEmpty;

  factory Tienda.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    String? optionalText(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty || s == 'null') return null;
      return s;
    }

    final desc = optionalText(json['descripcion']);
    final imagen = optionalText(json['imagen_url']) ??
        optionalText(json['logo_url']) ??
        optionalText(json['foto_url']) ??
        optionalText(json['portada_url']) ??
        '';

    return Tienda(
      id: id,
      nombre: json['nombre']?.toString().trim() ?? '',
      descripcion: desc,
      imagenUrl: imagen,
      ubicacion: optionalText(json['ubicacion']) ??
          optionalText(json['region']) ??
          optionalText(json['origen']) ??
          '',
      estilo: optionalText(json['estilo']) ??
          optionalText(json['tipo']) ??
          '',
    );
  }
}
