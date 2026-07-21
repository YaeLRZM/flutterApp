import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';

/// Detalle de una compra del usuario.
/// Fuente real: GET /api/ventas/{id} (ownership por user_id).
/// Sin tracking, guías, repartidor ni folios inventados.
class DetallePedidoView extends StatefulWidget {
  final int ventaId;

  const DetallePedidoView({super.key, required this.ventaId});

  @override
  State<DetallePedidoView> createState() => _DetallePedidoViewState();
}

class _DetallePedidoViewState extends State<DetallePedidoView> {
  static const Color bugambilia = Color(0xFFD81B60);
  static const Color secondaryText = Color(0xFF5E6668);

  final _ventaService = VentaService();

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
      final v = await _ventaService.fetchVentaPorId(widget.ventaId);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Compra #${widget.ventaId}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

    final v = _venta;
    if (v == null) {
      return const Center(
        child: Text('No disponible', style: TextStyle(color: secondaryText)),
      );
    }

    final estado =
        v.estado.trim().isEmpty ? 'No disponible' : v.estado.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('id', 'Compra #${v.id}'),
                _row('estado', estado),
                _row('total', _fmtMoney(v.total)),
                _row('created_at', _fmtDate(v.createdAt)),
                _row('forma_pago', v.etiquetaFormaPago),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Líneas de la compra',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (v.lineas.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Sin líneas de detalle.',
                style: TextStyle(color: secondaryText),
              ),
            )
          else
            ...v.lineas.map(_buildLinea),
        ],
      ),
    );
  }

  Widget _buildLinea(DetalleVentaLinea line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Nombre real del backend o "Artículo #id".
            line.etiquetaArticulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
