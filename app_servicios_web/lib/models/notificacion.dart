DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

class NotificacionApp {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;
  final DateTime? leidaAt;
  final bool leida;

  const NotificacionApp({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.data,
    this.createdAt,
    this.leidaAt,
    this.leida = false,
  });

  factory NotificacionApp.fromJson(Map<String, dynamic> json) {
    final leidaAt = _asDate(json['leida_at']);
    final leidaFlag = json['leida'];
    return NotificacionApp(
      id: _asInt(json['id']),
      tipo: json['tipo']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Aviso',
      mensaje: json['mensaje']?.toString() ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      createdAt: _asDate(json['created_at']),
      leidaAt: leidaAt,
      leida: leidaFlag is bool ? leidaFlag : leidaAt != null,
    );
  }
}

class NotificacionesListResult {
  final List<NotificacionApp> items;
  final int count;
  final int noLeidas;

  const NotificacionesListResult({
    required this.items,
    required this.count,
    required this.noLeidas,
  });
}
