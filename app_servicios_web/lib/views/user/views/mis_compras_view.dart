import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/api_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';
import 'detalle_pedido_view.dart';

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
  String? _error;
  List<Venta> _compras = [];
  int _count = 0;
  double _sumaTotales = 0;
  int? _cancelandoId;

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
    return '$dd/$mm/${local.year}';
  }

  Color _estadoColor(Venta v) {
    switch (v.estadoClave) {
      case 'pendiente':
        return const Color(0xFFE65100);
      case 'cancelada':
        return const Color(0xFF6D4C41);
      case 'completada':
        return bugambilia;
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
              if (v.sePuedeCancelar) ...[
                const SizedBox(height: 12),
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
