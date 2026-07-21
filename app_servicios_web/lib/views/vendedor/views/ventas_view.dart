import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';

/// Mis ventas: UI alineada al modelo real `Venta`
/// (id, total, estado, created_at, user_id, detalle_ventas_count).
/// Sin cliente nombre, sin guías, sin exportar, sin mock.
class VentasView extends StatefulWidget {
  const VentasView({super.key});

  @override
  State<VentasView> createState() => _VentasViewState();
}

class _VentasViewState extends State<VentasView> {
  static const Color bugambilia = Color(0xFFD81B60);
  static const Color background = Color(0xFFF8F5F2);
  static const Color secondaryText = Color(0xFF5E6668);

  final _ventaService = VentaService();

  bool _loading = true;
  String? _error;
  List<Venta> _ventas = [];
  int _count = 0;
  double _sumaTotales = 0;

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
      final result = await _ventaService.fetchMisVentas();
      if (!mounted) return;
      setState(() {
        _ventas = result.ventas;
        _count = result.count;
        _sumaTotales = result.sumaTotales;
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

  /// Tintas por estado de venta.
  /// Si llega otro valor, se muestra el texto tal cual (sin inventar significado).
  Color _estadoColor(String estado) {
    switch (estado.toLowerCase().trim()) {
      case 'pendiente':
        return const Color(0xFFE65100);
      case 'cancelada':
        return const Color(0xFF6D4C41);
      case 'completada':
        return const Color(0xFF2ECC71);
      case 'cancelada':
        return const Color(0xFFE74C3C);
      case 'pendiente':
        return const Color(0xFFF39C12);
      default:
        return secondaryText;
    }
  }

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtDate(DateTime? d) {
    if (d == null) return 'No disponible';
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargar);
    }

    return RefreshIndicator(
      color: bugambilia,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Text(
            'Mis ventas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: bugambilia,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ventas de tu tienda. Toca una para ver el detalle.',
            style: TextStyle(fontSize: 13, color: secondaryText),
          ),
          const SizedBox(height: 20),

          // meta.count / meta.suma_totales (calculados del listado filtrado)
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: 'VENTAS',
                  value: '$_count',
                  accent: bugambilia,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  label: 'SUMA DE TOTAL',
                  value: _fmtMoney(_sumaTotales),
                  accent: const Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_ventas.isEmpty)
            const AppEmptyView(
              icon: Icons.inbox_outlined,
              title: 'Aún no hay ventas en tu tienda.',
              subtitle:
                  'Cuando un comprador complete una compra de tus productos, aparecerá aquí.',
            )
          else
            ..._ventas.map(_buildVentaCard),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirDetalle(Venta v) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: _VentaDetalleSheet(
            ventaId: v.id,
            ventaService: _ventaService,
          ),
        );
      },
    );
  }

  Widget _buildVentaCard(Venta v) {
    final estado = v.estadoEtiqueta;
    final tieneEstado = v.estado.trim().isNotEmpty;
    final color = _estadoColor(v.estado);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirDetalle(v),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (tieneEstado ? color : secondaryText)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tieneEstado ? estado : 'No disponible',
                      style: TextStyle(
                        color: tieneEstado ? color : secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Venta #${v.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _fmtMoney(v.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: bugambilia,
                ),
              ),
              const SizedBox(height: 10),
              _kv('Fecha', _fmtDate(v.createdAt)),
              if (v.userId > 0) _kv('Cliente', 'Cliente #${v.userId}'),
              _kv(
                'Artículos',
                v.detalleCount > 0 ? '${v.detalleCount}' : '0',
              ),
              if (v.formaPagoId != null && v.formaPagoId! > 0)
                _kv('Forma de pago', v.etiquetaFormaPago),
              const SizedBox(height: 4),
              const Text(
                'Toca para ver detalle',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalle mínimo: GET /api/ventas/{id} — solo campos reales del backend.
class _VentaDetalleSheet extends StatefulWidget {
  final int ventaId;
  final VentaService ventaService;

  const _VentaDetalleSheet({
    required this.ventaId,
    required this.ventaService,
  });

  @override
  State<_VentaDetalleSheet> createState() => _VentaDetalleSheetState();
}

class _VentaDetalleSheetState extends State<_VentaDetalleSheet> {
  static const Color secondaryText = Color(0xFF5E6668);

  bool _loading = true;
  String? _error;
  Venta? _venta;

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
      final v = await widget.ventaService.fetchVentaPorId(widget.ventaId);
      if (!mounted) return;
      setState(() {
        _venta = v;
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

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtDate(DateTime? d) {
    if (d == null) return 'No disponible';
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Detalle de la venta #${widget.ventaId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoadingView(),
                )
              else if (_error != null)
                AppErrorView(message: _error!, onRetry: _cargar)
              else if (_venta == null)
                const AppEmptyView(
                  title: 'No disponible',
                  subtitle: 'No se pudo mostrar el detalle de esta venta.',
                )
              else
                _buildDetalle(_venta!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalle(Venta v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row('Venta', 'Venta #${v.id}'),
        _row('Estado', v.estadoEtiqueta),
        _row('Total', _fmtMoney(v.total)),
        _row('Fecha', _fmtDate(v.createdAt)),
        _row('Cliente', v.etiquetaCliente),
        _row('Forma de pago', v.etiquetaFormaPago),
        const SizedBox(height: 16),
        const Text(
          'Artículos vendidos',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (v.lineas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No hay artículos en esta venta.',
              style: TextStyle(color: secondaryText, fontSize: 13),
            ),
          )
        else
          ...v.lineas.map(_buildLinea),
      ],
    );
  }

  Widget _buildLinea(DetalleVentaLinea line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Nombre real o "Artículo #id" — nunca inventado.
            line.etiquetaArticulo,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          _row('articulo_id', '${line.articuloId}'),
          _row('cantidad', '${line.cantidad}'),
          _row('precio_unitario', _fmtMoney(line.precioUnitario)),
          _row('subtotal', _fmtMoney(line.subtotal)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
