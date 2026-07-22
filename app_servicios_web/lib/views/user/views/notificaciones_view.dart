import 'package:flutter/material.dart';

import '../../../models/notificacion.dart';
import '../../../services/articulo_service.dart';
import '../../../services/notificacion_service.dart';
import '../../../widgets/app_ui.dart';
import 'detalle_pedido_view.dart';
import 'product_detail_view.dart';

/// Notificaciones reales (GET /api/notificaciones).
/// Al tocar un aviso: marca leída y navega al apartado/detalle útil.
class NotificacionesView extends StatefulWidget {
  final VoidCallback? onIrAInicio;
  final VoidCallback? onIrAMisCompras;
  final VoidCallback? onIrAMisVentas;
  /// Vendedor: ir a Mis ventas filtrado en pagos por activar.
  final VoidCallback? onIrAActivarEfectivo;
  final VoidCallback? onIrAColecciones;
  final VoidCallback? onIrAProductos;
  final ValueChanged<int>? onNoLeidasChanged;
  final bool esVendedor;

  const NotificacionesView({
    super.key,
    this.onIrAInicio,
    this.onIrAMisCompras,
    this.onIrAMisVentas,
    this.onIrAActivarEfectivo,
    this.onIrAColecciones,
    this.onIrAProductos,
    this.onNoLeidasChanged,
    this.esVendedor = false,
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
      widget.onNoLeidasChanged?.call(result.noLeidas);
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

  int? _idFromData(NotificacionApp n, String key) {
    final raw = n.data?[key];
    if (raw is int) return raw > 0 ? raw : null;
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> _abrirProducto(int articuloId) async {
    try {
      final art = await ArticuloService().fetchArticuloPorId(articuloId);
      if (!mounted) return;
      if (art == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esa prenda ya no está disponible')),
        );
        widget.onIrAInicio?.call();
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailView(articuloId: articuloId),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la prenda')),
      );
      widget.onIrAInicio?.call();
    }
  }

  Future<void> _abrirCompra(int ventaId) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetallePedidoView(ventaId: ventaId),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      widget.onIrAMisCompras?.call();
    }
  }

  /// Destino según tipo + data real (sin inventar ids).
  Future<void> _abrir(NotificacionApp n) async {
    if (!n.leida) {
      await _service.marcarLeida(n.id);
    }

    final tipo = n.tipo.trim().toLowerCase();
    final ventaId = _idFromData(n, 'venta_id');
    final articuloId = _idFromData(n, 'articulo_id');

    if (widget.esVendedor) {
      await _abrirComoVendedor(tipo, ventaId, articuloId);
    } else {
      await _abrirComoComprador(tipo, ventaId, articuloId);
    }

    if (mounted) _cargar();
  }

  Future<void> _abrirComoComprador(
    String tipo,
    int? ventaId,
    int? articuloId,
  ) async {
    // Prenda concreta.
    if (articuloId != null &&
        (tipo == 'nueva_publicacion' ||
            tipo.contains('oferta') ||
            tipo.contains('producto') ||
            tipo.contains('articulo') ||
            tipo.contains('prenda'))) {
      await _abrirProducto(articuloId);
      return;
    }

    // Compra / estados de flujo.
    final esCompra = tipo.contains('compra') ||
        tipo.contains('pago') ||
        tipo.contains('pedido') ||
        tipo.contains('efectivo_activado') ||
        tipo == 'compra_efectivo_solicitud' ||
        tipo == 'pago_acreditado' ||
        tipo == 'pedido_en_curso' ||
        tipo == 'pedido_entregado' ||
        tipo == 'efectivo_activado';

    if (esCompra) {
      if (ventaId != null && ventaId > 0) {
        await _abrirCompra(ventaId);
        return;
      }
      widget.onIrAMisCompras?.call();
      return;
    }

    // Ofertas / catálogo general.
    if (tipo.contains('oferta') ||
        tipo.contains('promocion') ||
        tipo.contains('promoción') ||
        tipo == 'nueva_publicacion') {
      if (articuloId != null) {
        await _abrirProducto(articuloId);
        return;
      }
      if (widget.onIrAColecciones != null) {
        widget.onIrAColecciones!();
      } else {
        widget.onIrAInicio?.call();
      }
      return;
    }

    // Reseña / genérico → inicio o compras si hay venta.
    if (ventaId != null && ventaId > 0) {
      await _abrirCompra(ventaId);
      return;
    }
    if (articuloId != null) {
      await _abrirProducto(articuloId);
      return;
    }
    if (widget.onIrAMisCompras != null) {
      widget.onIrAMisCompras!();
    } else {
      widget.onIrAInicio?.call();
    }
  }

  Future<void> _abrirComoVendedor(
    String tipo,
    int? ventaId,
    int? articuloId,
  ) async {
    // Solicitud de pago en efectivo → filtro activar + ventas.
    if (tipo == 'solicitud_efectivo' ||
        tipo.contains('solicitud_efectivo') ||
        (tipo.contains('efectivo') && tipo.contains('solicitud'))) {
      if (widget.onIrAActivarEfectivo != null) {
        widget.onIrAActivarEfectivo!();
      } else {
        widget.onIrAMisVentas?.call();
      }
      return;
    }

    // Ventas / entregas / pedidos del vendedor.
    if (tipo.startsWith('venta') ||
        tipo.contains('venta') ||
        tipo == 'pedido_entregado' ||
        tipo == 'pago_acreditado') {
      widget.onIrAMisVentas?.call();
      return;
    }

    // Nueva reseña → productos (gestión de catálogo).
    if (tipo == 'nueva_resena' || tipo.contains('resena')) {
      if (articuloId != null) {
        await _abrirProducto(articuloId);
        return;
      }
      if (widget.onIrAProductos != null) {
        widget.onIrAProductos!();
      } else {
        widget.onIrAMisVentas?.call();
      }
      return;
    }

    if (articuloId != null) {
      await _abrirProducto(articuloId);
      return;
    }

    if (widget.onIrAMisVentas != null) {
      widget.onIrAMisVentas!();
    } else {
      widget.onIrAInicio?.call();
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  IconData _iconFor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'compra_completada':
      case 'venta_completada':
      case 'venta_entregada':
      case 'pedido_entregado':
        return Icons.check_circle_outline;
      case 'compra_pendiente':
      case 'venta_pendiente':
      case 'pendiente_activacion':
        return Icons.hourglass_top_outlined;
      case 'solicitud_efectivo':
      case 'compra_efectivo_solicitud':
        return Icons.payments_outlined;
      case 'efectivo_activado':
      case 'listo_pagar':
        return Icons.qr_code_2_outlined;
      case 'pago_acreditado':
        return Icons.account_balance_wallet_outlined;
      case 'pedido_en_curso':
        return Icons.local_shipping_outlined;
      case 'nueva_publicacion':
        return Icons.storefront_outlined;
      case 'nueva_resena':
        return Icons.star_outline;
      default:
        if (tipo.contains('oferta')) return Icons.local_offer_outlined;
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
          const SizedBox(height: 8),
          const Text(
            'Toca un aviso para ir al apartado correspondiente.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            AppEmptyView(
              icon: Icons.notifications_none_outlined,
              title: 'No tienes notificaciones',
              subtitle: widget.esVendedor
                  ? 'Aquí verás avisos de ventas de tu tienda y reseñas de tus productos.'
                  : 'Aquí verás avisos de tus compras y de nuevas publicaciones.',
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
