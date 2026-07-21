int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

/// Parsea fechas de Laravel/MySQL a DateTime usable en UI.
/// - ISO con Z / offset → respeta zona y se convierte con toLocal() al calcular.
/// - "yyyy-MM-dd HH:mm:ss" sin zona (APP_TZ suele ser UTC) → se interpreta como UTC.
DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;

  var s = v.toString().trim();
  if (s.isEmpty || s == 'null') return null;

  // "2026-07-21 05:00:07.000000" → ISO UTC si no trae zona.
  final naive = RegExp(
    r'^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})(\.\d+)?$',
  ).firstMatch(s);
  if (naive != null) {
    final frac = naive.group(3) ?? '';
    s = '${naive.group(1)}T${naive.group(2)}${frac}Z';
  }

  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  // Normalizar a instante absoluto (UTC) y dejar toLocal() al mostrar/restar.
  return parsed.isUtc ? parsed : parsed.toUtc();
}

String? _nestedNombre(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is! Map) return null;
  final n = raw['nombre']?.toString().trim();
  if (n == null || n.isEmpty) return null;
  return n;
}

/// Línea de detalle de venta (campos reales de `detalle_ventas`).
class DetalleVentaLinea {
  final int id;
  final int articuloId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  /// Nombre real del artículo si el backend lo envía en `articulo.nombre`.
  final String? articuloNombre;

  const DetalleVentaLinea({
    required this.id,
    required this.articuloId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.articuloNombre,
  });

  factory DetalleVentaLinea.fromJson(Map<String, dynamic> json) {
    return DetalleVentaLinea(
      id: _asInt(json['id']),
      articuloId: _asInt(json['articulo_id']),
      cantidad: _asInt(json['cantidad']),
      precioUnitario: _asDouble(
        json['precio_unitario'] ?? json['precio'],
      ),
      subtotal: _asDouble(json['subtotal']),
      articuloNombre: _nestedNombre(json, 'articulo'),
    );
  }

  /// Nombre del producto si viene en la respuesta; si no, etiqueta neutra.
  String get etiquetaArticulo {
    final n = articuloNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Artículo #$articuloId';
  }
}

class Venta {
  final int id;
  final int userId;
  final int tiendaId;
  final int? formaPagoId;
  final double total;
  final String estado;
  final DateTime? createdAt;
  /// Momento en que el backend confirmará la compra (pendiente → completada).
  final DateTime? autoCompleteAt;
  final int detalleCount;
  final List<DetalleVentaLinea> lineas;

  /// `user.nombre` si el backend lo envía en el show.
  final String? userNombre;

  /// `forma_pago.nombre` si el backend lo envía en el show.
  final String? formaPagoNombre;

  const Venta({
    required this.id,
    required this.userId,
    required this.tiendaId,
    this.formaPagoId,
    required this.total,
    required this.estado,
    this.createdAt,
    this.autoCompleteAt,
    this.detalleCount = 0,
    this.lineas = const [],
    this.userNombre,
    this.formaPagoNombre,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    final rawDetalles = json['detalle_ventas'];
    final lineas = <DetalleVentaLinea>[];
    if (rawDetalles is List) {
      for (final item in rawDetalles) {
        if (item is Map) {
          lineas.add(
            DetalleVentaLinea.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return Venta(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      tiendaId: _asInt(json['tienda_id']),
      formaPagoId: json['forma_pago_id'] == null
          ? null
          : _asInt(json['forma_pago_id']),
      total: _asDouble(json['total']),
      estado: json['estado']?.toString() ?? '',
      createdAt: _asDate(json['created_at']),
      autoCompleteAt: _asDate(json['auto_complete_at']),
      detalleCount: _asInt(
        json['detalle_ventas_count'] ??
            (lineas.isNotEmpty ? lineas.length : 0),
      ),
      lineas: lineas,
      userNombre: _nestedNombre(json, 'user'),
      formaPagoNombre: _nestedNombre(json, 'forma_pago'),
    );
  }

  String get etiquetaCliente {
    final n = userNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (userId > 0) return 'Cliente #$userId';
    return 'No disponible';
  }

  String get etiquetaFormaPago {
    final n = formaPagoNombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (formaPagoId != null && formaPagoId! > 0) {
      return 'Método #$formaPagoId';
    }
    return 'No disponible';
  }

  /// Clave de estado normalizada (backend: pendiente|completada|cancelada).
  String get estadoClave => estado.trim().toLowerCase();

  /// Etiqueta legible para UI de producto.
  String get estadoEtiqueta {
    switch (estadoClave) {
      case 'pendiente':
        return 'Pendiente';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        final e = estado.trim();
        return e.isEmpty ? 'Sin estado' : e;
    }
  }

  /// Solo compras pendientes se pueden cancelar (regla backend).
  bool get sePuedeCancelar => estadoClave == 'pendiente';

  /// Hay temporizador de confirmación (pendiente + auto_complete_at).
  bool get tieneTemporizadorConfirmacion =>
      estadoClave == 'pendiente' && autoCompleteAt != null;

  /// Debe mostrarse el bloque de contador (solo depende del estado real).
  bool get debeMostrarContadorConfirmacion => estadoClave == 'pendiente';

  /// Tiempo restante hasta auto-confirmación (null si no hay auto_complete_at).
  Duration? get tiempoRestanteAutoCompletar {
    if (estadoClave != 'pendiente' || autoCompleteAt == null) return null;
    final target = autoCompleteAt!.toLocal();
    final left = target.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Reloj corto "M:SS" / "S s" para chip de UI (null si no hay fecha).
  String? get relojRestanteTexto {
    final left = tiempoRestanteAutoCompletar;
    if (left == null) return null;
    if (left == Duration.zero) return '0 s';
    final m = left.inMinutes;
    final s = left.inSeconds % 60;
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
    return '$s s';
  }

  /// Mensaje de reloj legible (misma verdad de datos; enfoque por rol).
  /// Nunca devuelve vacío si estado == pendiente (fallback visible).
  String mensajeTiempoConfirmacion({bool esVendedor = false}) {
    if (estadoClave != 'pendiente') return '';

    final left = tiempoRestanteAutoCompletar;
    if (left == null) {
      // Pendiente sin auto_complete_at (legacy o parse fallido): no silenciar.
      return 'Se completará automáticamente';
    }
    if (left == Duration.zero) {
      return esVendedor
          ? 'Esta venta se está confirmando… se actualizará en un momento.'
          : 'Tu compra se está confirmando… actualiza en un momento.';
    }
    final m = left.inMinutes;
    final s = left.inSeconds % 60;
    final reloj = m > 0
        ? '$m min ${s.toString().padLeft(2, '0')} s'
        : '$s s';
    return esVendedor
        ? 'Se confirmará automáticamente en aproximadamente $reloj.'
        : 'Tu compra está en proceso y se confirmará en aproximadamente $reloj.';
  }
}

class VentasListResult {
  final List<Venta> ventas;
  final int count;
  final double sumaTotales;

  const VentasListResult({
    required this.ventas,
    required this.count,
    required this.sumaTotales,
  });
}
