/// Representa un registro de la tabla `articulos`.
///
/// `fromJson` acepta el shape de `ArticuloResource` (Laravel) y también
/// el shape plano de mocks locales.
class Articulo {
  final int id;
  final int categoriaId;
  final String categoriaNombre;
  final int artesanoId;
  final String artesanoNombre;
  final int tiendaId;
  final String tiendaNombre;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;

  /// Disponibilidad comercial del vendedor (API: `disponible`).
  final bool disponible;

  final String talla;
  final String color;
  final String bordado;
  final String tela;
  final String region;

  /// Porcentaje de descuento activo (0-100). `null` = sin descuento.
  final double? descuentoPorcentaje;

  final int vendidos;

  /// URL principal o vacío si no hay imágenes (la UI usa fallback).
  final String imagenUrl;

  const Articulo({
    required this.id,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.artesanoId,
    this.artesanoNombre = '',
    required this.tiendaId,
    this.tiendaNombre = '',
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.disponible = true,
    required this.talla,
    required this.color,
    required this.bordado,
    required this.tela,
    required this.region,
    this.descuentoPorcentaje,
    this.vendidos = 0,
    required this.imagenUrl,
  });

  bool get tieneDescuento =>
      descuentoPorcentaje != null && descuentoPorcentaje! > 0;

  double get precioFinal {
    if (!tieneDescuento) return precio;
    return precio - (precio * (descuentoPorcentaje! / 100));
  }

  /// Parte entera del precio final, ej. "641" en "$641.68"
  String get precioFinalEntero => precioFinal.floor().toString();

  /// Parte decimal del precio final, ej. "68" en "$641.68"
  String get precioFinalDecimal {
    final cents = ((precioFinal - precioFinal.floor()) * 100).round();
    return cents.toString().padLeft(2, '0');
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _asDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Primera imagen principal, o la primera de la lista, o `imagen_url`.
  static String _resolveImagenUrl(Map<String, dynamic> json) {
    final imagenes = json['imagenes'];
    if (imagenes is List && imagenes.isNotEmpty) {
      Map<String, dynamic>? principal;
      Map<String, dynamic>? first;
      for (final raw in imagenes) {
        final img = _asMap(raw);
        if (img == null) continue;
        first ??= img;
        if (img['es_principal'] == true) {
          principal = img;
          break;
        }
      }
      final chosen = principal ?? first;
      final url = chosen?['url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    final flat = json['imagen_url']?.toString();
    if (flat != null && flat.isNotEmpty) return flat;
    return '';
  }

  factory Articulo.fromJson(Map<String, dynamic> json) {
    final categoria = _asMap(json['categoria']);
    final artesano = _asMap(json['artesano']);
    final tienda = _asMap(json['tienda']);

    final descripcionRaw = json['descripcion']?.toString();
    final descripcion =
        (descripcionRaw == null || descripcionRaw.isEmpty) ? null : descripcionRaw;

    return Articulo(
      id: _asInt(json['id']),
      categoriaId: _asInt(json['categoria_id'] ?? categoria?['id']),
      categoriaNombre:
          categoria?['nombre']?.toString() ??
          json['categoria_nombre']?.toString() ??
          '',
      artesanoId: _asInt(json['artesano_id'] ?? artesano?['id']),
      artesanoNombre: artesano?['nombre']?.toString() ??
          json['artesano_nombre']?.toString() ??
          '',
      tiendaId: _asInt(json['tienda_id'] ?? tienda?['id']),
      tiendaNombre: tienda?['nombre']?.toString() ??
          json['tienda_nombre']?.toString() ??
          '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: descripcion,
      precio: _asDouble(json['precio']),
      stock: _asInt(json['stock']),
      disponible: json['disponible'] == null
          ? true
          : json['disponible'] == true ||
              json['disponible'] == 1 ||
              json['disponible']?.toString() == '1',
      talla: json['talla']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      bordado: json['bordado']?.toString() ?? '',
      tela: json['tela']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      descuentoPorcentaje: json['descuento_porcentaje'] != null
          ? _asDouble(json['descuento_porcentaje'])
          : null,
      vendidos: _asInt(json['vendidos']),
      imagenUrl: _resolveImagenUrl(json),
    );
  }
}
