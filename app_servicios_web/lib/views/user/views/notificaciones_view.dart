import 'package:flutter/material.dart';

import '../../../models/notificacion.dart';
import '../../../services/notificacion_service.dart';
import '../../../widgets/app_ui.dart';
import 'detalle_pedido_view.dart';

/// Notificaciones reales del comprador autenticado.
class NotificacionesView extends StatefulWidget {
  final VoidCallback? onIrAInicio;
  final VoidCallback? onIrAMisCompras;

  const NotificacionesView({
    super.key,
    this.onIrAInicio,
    this.onIrAMisCompras,
  });

  @override
  State<NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<NotificacionesView> {
  final _service = NotificacionService();
  bool _loading = true;
  String? _error;
  List<NotificacionApp> _items = [];
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchNotificaciones();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _noLeidas = result.noLeidas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _marcarTodas() async {
    await _service.marcarTodasLeidas();
    await _cargar();
  }

  Future<void> _abrir(NotificacionApp n) async {
    if (!n.leida) {
      await _service.marcarLeida(n.id);
    }

    final ventaId = n.data?['venta_id'];
    final id = ventaId is int
        ? ventaId
        : int.tryParse(ventaId?.toString() ?? '');
    if (id != null && id > 0 && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetallePedidoView(ventaId: id)),
      );
    } else if (widget.onIrAMisCompras != null &&
        (n.tipo.contains('compra') || n.tipo.contains('publicacion') == false)) {
      widget.onIrAMisCompras?.call();
    }

    if (mounted) _cargar();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'compra_completada':
        return Icons.check_circle_outline;
      case 'compra_pendiente':
        return Icons.hourglass_top_outlined;
      case 'nueva_publicacion':
        return Icons.storefront_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingView();
    }
    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargar);
    }

    return RefreshIndicator(
      color: const Color(0xFFD81B60),
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD81B60),
                  ),
                ),
              ),
              if (_noLeidas > 0)
                TextButton(
                  onPressed: _marcarTodas,
                  child: const Text('Marcar leídas'),
                ),
            ],
          ),
          if (_noLeidas > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$_noLeidas sin leer',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const AppEmptyView(
              icon: Icons.notifications_none_outlined,
              title: 'No tienes notificaciones',
              subtitle:
                  'Aquí verás avisos de tus compras y de nuevas publicaciones.',
            )
          else
            ..._items.map(_buildTile),
        ],
      ),
    );
  }

  Widget _buildTile(NotificacionApp n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrir(n),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.leida ? Colors.white : const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.leida
                  ? const Color(0xFFE8E0DC)
                  : const Color(0xFFD81B60).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(n.tipo),
                color: const Color(0xFFD81B60),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            n.leida ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.mensaje,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    if (n.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _fmtDate(n.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!n.leida)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD81B60),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
