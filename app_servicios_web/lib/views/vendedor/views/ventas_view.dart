import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';

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

  /// Solo tintas para valores de `estado` que el seed/API ya usa.
  /// Si llega otro valor, se muestra el texto tal cual (sin inventar significado).
  Color _estadoColor(String estado) {
    switch (estado.toLowerCase().trim()) {
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black38),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bugambilia,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
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
            'Registros de la tabla ventas de tu tienda.',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: Colors.black26),
                  SizedBox(height: 10),
                  Text(
                    'No hay ventas para tu tienda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryText, fontSize: 14),
                  ),
                ],
              ),
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

  Widget _buildVentaCard(Venta v) {
    final estado = v.estado.trim();
    final tieneEstado = estado.isNotEmpty;
    final color = _estadoColor(estado);

    return Container(
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
              // estado: string crudo del backend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              // id real
              Text(
                'Venta #${v.id}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // total real
          Text(
            _fmtMoney(v.total),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: bugambilia,
            ),
          ),
          const SizedBox(height: 10),
          // Solo campos presentes en el modelo/API
          _kv('created_at', _fmtDate(v.createdAt)),
          if (v.userId > 0) _kv('user_id (cliente)', '#${v.userId}'),
          if (v.detalleCount > 0)
            _kv('detalle_ventas', '${v.detalleCount}')
          else
            _kv('detalle_ventas', '0'),
          // forma_pago_id existe pero sin nombre de forma: no se inventa label de método
          if (v.formaPagoId != null && v.formaPagoId! > 0)
            _kv('forma_pago_id', '#${v.formaPagoId}'),
        ],
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
