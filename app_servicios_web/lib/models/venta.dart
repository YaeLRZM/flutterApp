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
  /// tarjeta | efectivo | vacío (legacy).
  final String? metodoPago;
  final String? codigoBarras;
  final DateTime? createdAt;
  /// Legacy: pendiente → entregado.
  final DateTime? autoCompleteAt;
  /// Nuevo flujo: siguiente paso de estado (2 min).
  final DateTime? nextStateAt;
  final int detalleCount;
  final List<DetalleVentaLinea> lineas;

  final String? userNombre;
  final String? formaPagoNombre;

  const Venta({
    required this.id,
    required this.userId,
    required this.tiendaId,
    this.formaPagoId,
    required this.total,
    required this.estado,
    this.metodoPago,
    this.codigoBarras,
    this.createdAt,
    this.autoCompleteAt,
    this.nextStateAt,
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

    final metodo = json['metodo_pago']?.toString().trim().toLowerCase();

    return Venta(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      tiendaId: _asInt(json['tienda_id']),
      formaPagoId: json['forma_pago_id'] == null
          ? null
          : _asInt(json['forma_pago_id']),
      total: _asDouble(json['total']),
      estado: json['estado']?.toString() ?? '',
      metodoPago: (metodo == null || metodo.isEmpty) ? null : metodo,
      codigoBarras: json['codigo_barras']?.toString(),
      createdAt: _asDate(json['created_at']),
      autoCompleteAt: _asDate(json['auto_complete_at']),
      nextStateAt: _asDate(json['next_state_at']),
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

  /// Clave de estado normalizada (API real).
  String get estadoClave => estado.trim().toLowerCase();

  String get metodoPagoClave => (metodoPago ?? '').trim().toLowerCase();

  String get metodoPagoEtiqueta {
    switch (metodoPagoClave) {
      case 'tarjeta':
        return 'Tarjeta';
      case 'efectivo':
        return 'Efectivo';
      default:
        return formaPagoNombre?.isNotEmpty == true
            ? formaPagoNombre!
            : 'No disponible';
    }
  }

  /// Etiquetas de producto (sin jerga técnica).
  String get estadoEtiqueta {
    switch (estadoClave) {
      case 'pendiente_activacion':
        return 'Pendiente de activación';
      case 'listo_pagar':
        return 'Listo para pagar';
      case 'pago_acreditado':
        return 'Pago acreditado';
      case 'en_curso':
        return 'En curso';
      case 'entregado':
        return 'Entregado';
      case 'cancelada':
      case 'cancelado':
        return 'Cancelado';
      case 'pendiente':
        return 'Pendiente';
      case 'completada':
        // Residuo de datos antiguos (migrados a entregado en BD).
        return 'Entregado';
      default:
        final e = estado.trim();
        return e.isEmpty ? 'Sin estado' : e;
    }
  }

  /// Cancelable según estados del backend.
  bool get sePuedeCancelar {
    const ok = {
      'pendiente',
      'pendiente_activacion',
      'listo_pagar',
      'pago_acreditado',
      'en_curso',
    };
    return ok.contains(estadoClave);
  }

  bool get esEfectivo => metodoPagoClave == 'efectivo';
  bool get esTarjeta => metodoPagoClave == 'tarjeta';

  bool get muestraCodigoBarras =>
      esEfectivo &&
      codigoBarras != null &&
      codigoBarras!.trim().isNotEmpty &&
      estadoClave != 'pendiente_activacion' &&
      estadoClave != 'cancelada' &&
      estadoClave != 'cancelado';

  bool get esperaActivacionVendedor =>
      esEfectivo && estadoClave == 'pendiente_activacion';

  bool get sePuedeActivarEfectivo =>
      esEfectivo && estadoClave == 'pendiente_activacion';

  /// Próximo avance automático (next_state_at o legacy auto_complete_at).
  DateTime? get momentoProximoEstado {
    if (nextStateAt != null) return nextStateAt;
    if (estadoClave == 'pendiente') return autoCompleteAt;
    return null;
  }

  bool get debeMostrarContadorConfirmacion {
    final m = momentoProximoEstado;
    if (m == null) return false;
    const conTimer = {
      'pendiente',
      'listo_pagar',
      'pago_acreditado',
      'en_curso',
    };
    return conTimer.contains(estadoClave);
  }

  Duration? get tiempoRestanteAutoCompletar {
    final m = momentoProximoEstado;
    if (m == null || !debeMostrarContadorConfirmacion) return null;
    final left = m.toLocal().difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String? get relojRestanteTexto {
    final left = tiempoRestanteAutoCompletar;
    if (left == null) return null;
    if (left == Duration.zero) return '0 s';
    final min = left.inMinutes;
    final s = left.inSeconds % 60;
    if (min > 0) return '$min:${s.toString().padLeft(2, '0')}';
    return '$s s';
  }

  String mensajeTiempoConfirmacion({bool esVendedor = false}) {
    if (!debeMostrarContadorConfirmacion) {
      if (esperaActivacionVendedor) {
        return esVendedor
            ? 'Activa el pago en efectivo para generar el código.'
            : 'Esperando activación del vendedor.';
      }
      return '';
    }

    final left = tiempoRestanteAutoCompletar;
    final nextLabel = switch (estadoClave) {
      'listo_pagar' => 'pago acreditado',
      'pago_acreditado' => 'en curso',
      'en_curso' => 'entregado',
      'pendiente' => 'confirmada',
      _ => 'siguiente paso',
    };

    if (left == null) {
      return esVendedor
          ? 'Esta venta avanzará automáticamente.'
          : 'Tu compra avanzará automáticamente.';
    }
    if (left == Duration.zero) {
      return esVendedor
          ? 'Actualizando estado…'
          : 'Tu compra se está actualizando…';
    }
    final min = left.inMinutes;
    final s = left.inSeconds % 60;
    final reloj = min > 0
        ? '$min min ${s.toString().padLeft(2, '0')} s'
        : '$s s';
    return esVendedor
        ? 'Pasará a $nextLabel en aproximadamente $reloj.'
        : 'Pasará a $nextLabel en aproximadamente $reloj.';
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
