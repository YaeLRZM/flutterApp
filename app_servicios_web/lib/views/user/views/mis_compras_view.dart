import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';
import 'detalle_pedido_view.dart';
import 'product_detail_view.dart';

/// Historial de compras del usuario autenticado (GET /api/ventas).
class MisComprasView extends StatefulWidget {
  const MisComprasView({super.key});

  @override
  State<MisComprasView> createState() => _MisComprasViewState();
}

class _MisComprasViewState extends State<MisComprasView> {
  static const Color bugambilia = Color(0xFFD81B60);
  static const Color secondaryText = Color(0xFF5E6668);

  final _ventaService = VentaService();

  bool _loading = true;
  bool _reloading = false;
  String? _error;
  List<Venta> _compras = [];
  int _count = 0;
  double _sumaTotales = 0;
  int? _cancelandoId;
  Timer? _tick;
  Timer? _refreshPoll;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Solo refresca UI del reloj; el cambio de estado lo decide el backend.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final conTimer =
          _compras.where((c) => c.debeMostrarContadorConfirmacion);
      if (conTimer.isEmpty) return;
      setState(() {});
      if (conTimer.any((c) {
        final left = c.tiempoRestanteAutoCompletar;
        return left != null && left == Duration.zero;
      })) {
        _cargar(silencioso: true);
      }
    });
    // Reconsulta periódica: auto-completado del backend (GET ejecuta completarVencidas).
    _refreshPoll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _loading || _reloading) return;
      _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _refreshPoll?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (_reloading) return;
    _reloading = true;
    if (!silencioso && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await ApiService().getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Inicia sesión para ver tu historial de compras.';
          _compras = [];
          _count = 0;
          _sumaTotales = 0;
          _loading = false;
        });
        return;
      }

      final result = await _ventaService.fetchMisVentas();
      if (!mounted) return;
      setState(() {
        _compras = result.ventas;
        _count = result.count;
        _sumaTotales = result.sumaTotales;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _reloading = false;
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

  Color _estadoColor(Venta v) {
    switch (v.estadoClave) {
      case 'pendiente':
      case 'pendiente_activacion':
      case 'listo_pagar':
        return const Color(0xFFE65100);
      case 'pago_acreditado':
        return const Color(0xFF1565C0);
      case 'en_curso':
        return const Color(0xFF6A1B9A);
      case 'entregado':
        return const Color(0xFF2E7D32);
      case 'cancelada':
      case 'cancelado':
        return const Color(0xFF6D4C41);
      default:
        return secondaryText;
    }
  }

  Future<void> _abrirDetalle(Venta v) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoView(ventaId: v.id),
      ),
    );
    if (mounted) _cargar();
  }

  /// Abre el detalle de la prenda comprada (artículo real de la línea).
  Future<void> _abrirPrenda(DetalleVentaLinea line) async {
    final id = line.articuloId;
    if (id <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no disponible')),
      );
      return;
    }
    try {
      final art = await ArticuloService().fetchArticuloPorId(id);
      if (!mounted) return;
      if (art == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto no disponible')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailView(articuloId: id),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no disponible')),
      );
    }
  }

  Future<void> _confirmarCancelar(Venta v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar compra'),
        content: Text(
          '¿Deseas cancelar la compra #${v.id}? '
          'Se liberarán los artículos reservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelandoId = v.id);
    try {
      await _ventaService.cancelarCompra(v.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra cancelada')),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(child: _buildBody()),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Mis compras',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: bugambilia,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca una compra para ver el detalle. '
            'Las pendientes se pueden cancelar.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          if (_count > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$_count compra(s) · suma ${_fmtMoney(_sumaTotales)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_compras.isEmpty)
            const AppEmptyView(
              icon: Icons.shopping_bag_outlined,
              title: 'Aún no tienes compras',
              subtitle: 'Cuando completes una compra, aparecerá aquí.',
            )
          else
            ..._compras.map(_buildCard),
        ],
      ),
    );
  }

  Widget _buildCard(Venta v) {
    final color = _estadoColor(v);
    final cancelando = _cancelandoId == v.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirDetalle(v),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                  Expanded(
                    child: Text(
                      'Compra #${v.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      v.estadoEtiqueta,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _fmtMoney(v.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: bugambilia,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fecha: ${_fmtDate(v.createdAt)}',
                style: const TextStyle(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 4),
              Text(
                'Pago: ${v.metodoPagoEtiqueta}',
                style: const TextStyle(fontSize: 12, color: secondaryText),
              ),
              if (v.estadoClave == 'entregado') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Text(
                    'Tu pedido fue entregado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
              if (v.esperaActivacionVendedor) ...[
                const SizedBox(height: 8),
                const Text(
                  'Esperando activación del vendedor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
              if (v.muestraCodigoBarras) ...[
                const SizedBox(height: 8),
                _CodigoBarrasMini(codigo: v.codigoBarras!),
              ],
              if (v.lineas.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Prendas de esta compra',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                ...v.lineas.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            line.etiquetaArticulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: bugambilia,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            // Evitar que el InkWell de la tarjeta consuma el toque.
                            _abrirPrenda(line);
                          },
                          child: const Text(
                            'Ver prenda',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else if (v.detalleCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${v.detalleCount} prenda(s) · abre el detalle de la compra para verlas',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
              if (v.debeMostrarContadorConfirmacion) ...[
                const SizedBox(height: 10),
                _CompraCountdownChip(venta: v),
              ],
              if (v.sePuedeCancelar) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: cancelando ? null : () => _confirmarCancelar(v),
                    child: cancelando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Cancelar compra',
                            style: TextStyle(color: Colors.red),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CodigoBarrasMini extends StatelessWidget {
  final String codigo;

  const _CodigoBarrasMini({required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código para pagar',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          // Representación visual simple (simulación, no librería de escáner).
          Row(
            children: List.generate(28, (i) {
              final h = 18.0 + (codigo.codeUnitAt(i % codigo.length) % 12);
              return Container(
                width: 2,
                height: h,
                margin: const EdgeInsets.only(right: 1.5),
                color: Colors.black87,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            codigo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contador de auto-confirmación (next_state_at / auto_complete_at).
class _CompraCountdownChip extends StatelessWidget {
  final Venta venta;

  const _CompraCountdownChip({required this.venta});

  @override
  Widget build(BuildContext context) {
    final msg = venta.mensajeTiempoConfirmacion();
    final display =
        msg.trim().isEmpty ? 'Se completará automáticamente' : msg;
    final reloj = venta.relojRestanteTexto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.timer_outlined,
              size: 18,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFE65100),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (reloj != null) ...[
            const SizedBox(width: 8),
            Text(
              reloj,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE65100),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
