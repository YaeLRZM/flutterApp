/// Artesano/artesana vinculado a artículos del catálogo.
///
/// API real actual: `id`, `nombre`.
/// Campos opcionales se muestran solo si el backend (o mock) los envía;
/// no se inventan valores por defecto.
class Artesano {
  final int id;
  final String nombre;

  /// Ej. "Maestra Artesana" — solo si viene en la respuesta.
  final String titulo;

  /// Comunidad o región — solo si viene en la respuesta.
  final String region;

  final bool verificado;

  /// Foto del artesano si el backend la expone.
  final String avatarUrl;

  /// Historia / presentación breve (opcional).
  final String? biografia;

  /// Especialidad declarada (opcional).
  final String? especialidad;

  const Artesano({
    required this.id,
    required this.nombre,
    this.titulo = '',
    this.region = '',
    this.verificado = false,
    this.avatarUrl = '',
    this.biografia,
    this.especialidad,
  });

  bool get tieneTitulo => titulo.trim().isNotEmpty;
  bool get tieneRegion => region.trim().isNotEmpty;
  bool get tieneAvatar => avatarUrl.trim().isNotEmpty;
  bool get tieneBiografia =>
      biografia != null && biografia!.trim().isNotEmpty;
  bool get tieneEspecialidad =>
      especialidad != null && especialidad!.trim().isNotEmpty;

  factory Artesano.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    String? optionalText(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty || s == 'null') return null;
      return s;
    }

    final avatar = optionalText(json['avatar_url']) ??
        optionalText(json['foto_url']) ??
        optionalText(json['imagen_url']) ??
        '';

    return Artesano(
      id: id,
      nombre: json['nombre']?.toString().trim() ?? '',
      // Sin defaults inventados: vacío si el API no lo envía.
      titulo: optionalText(json['titulo']) ??
          optionalText(json['oficio']) ??
          '',
      region: optionalText(json['region']) ??
          optionalText(json['comunidad']) ??
          optionalText(json['origen']) ??
          '',
      verificado: json['verificado'] == true ||
          json['verificado'] == 1 ||
          json['verificado']?.toString() == '1',
      avatarUrl: avatar,
      biografia: optionalText(json['biografia']) ??
          optionalText(json['descripcion']) ??
          optionalText(json['historia']),
      especialidad: optionalText(json['especialidad']) ??
          optionalText(json['especialidad_principal']),
    );
  }
}
