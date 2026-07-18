/// Representa un registro de la tabla `articulos`.
///
/// Los campos siguen la migración de Laravel. Se agregaron un par de
/// campos "denormalizados" (nombreCategoria, imagenUrl, vendidos) que en
/// el backend real probablemente vengan de relaciones/joins
/// (categoria, articulo_imagenes, pedidos) — se dejan aquí planos para
/// simplificar el consumo desde la UI mientras trabajamos con mocks.
class Articulo {
  final int id;
  final int categoriaId;
  final String categoriaNombre;
  final int artesanoId;
  final int tiendaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String talla;
  final String color;
  final String bordado;
  final String tela;
  final String region;

  /// Porcentaje de descuento activo (0-100). `null` = sin descuento.
  /// TODO: API -> esto normalmente vendrá calculado desde el cupón /
  /// promoción vigente de la tienda, no como columna directa de articulos.
  final double? descuentoPorcentaje;

  /// TODO: API -> vendrá de un conteo sobre `pedidos`/`detalle_pedidos`.
  final int vendidos;

  /// TODO: API -> vendrá de una tabla de imágenes (articulo_imagenes) o de
  /// un storage (S3 / Laravel Storage). Por ahora solo guardamos un color
  /// para simular una imagen distinta por artículo.
  final String imagenUrl;

  const Articulo({
    required this.id,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.artesanoId,
    required this.tiendaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
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

  factory Articulo.fromJson(Map<String, dynamic> json) {
    // TODO: API -> ajustar nombres de llaves a lo que realmente regrese
    // el endpoint de Laravel (ej. Resource/Fractal), incluyendo relaciones
    // cargadas como `categoria.nombre`.
    return Articulo(
      id: json['id'],
      categoriaId: json['categoria_id'],
      categoriaNombre: json['categoria']?['nombre'] ?? '',
      artesanoId: json['artesano_id'],
      tiendaId: json['tienda_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: double.parse(json['precio'].toString()),
      stock: json['stock'],
      talla: json['talla'] ?? '',
      color: json['color'] ?? '',
      bordado: json['bordado'] ?? '',
      tela: json['tela'] ?? '',
      region: json['region'] ?? '',
      descuentoPorcentaje: json['descuento_porcentaje'] != null
          ? double.parse(json['descuento_porcentaje'].toString())
          : null,
      vendidos: json['vendidos'] ?? 0,
      imagenUrl: json['imagen_url'] ?? '',
    );
  }
}
