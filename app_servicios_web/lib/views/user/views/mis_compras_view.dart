import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';
import 'detalle_pedido_view.dart';

/// Historial de compras del usuario autenticado.
/// Fuente real: GET /api/ventas (scope user_id en backend).
/// Sin mock, sin tracking, sin filtros de envío inventados.
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
      // Mismo endpoint que vendedor; el backend filtra por rol (user_id).
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

  void _abrirDetalle(Venta v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoView(ventaId: v.id),
      ),
    );
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
            'Historial de tus compras reales (API). Toca una para ver el detalle.',
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
              subtitle: 'Cuando completes una compra real, aparecerá aquí.',
            )
          else
            ..._compras.map(_buildCard),
        ],
      ),
    );
  }

  Widget _buildCard(Venta v) {
    final estado =
        v.estado.trim().isEmpty ? 'No disponible' : v.estado.trim();

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
                      color: bugambilia.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: bugambilia,
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
                'created_at: ${_fmtDate(v.createdAt)}',
                style: const TextStyle(fontSize: 12, color: secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
