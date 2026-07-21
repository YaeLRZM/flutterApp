import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';

/// Detalle de una compra del usuario (GET /api/ventas/{id}).
class DetallePedidoView extends StatefulWidget {
  final int ventaId;

  const DetallePedidoView({super.key, required this.ventaId});

  @override
  State<DetallePedidoView> createState() => _DetallePedidoViewState();
}

class _DetallePedidoViewState extends State<DetallePedidoView> {
  static const Color secondaryText = Color(0xFF5E6668);

  final _ventaService = VentaService();

  bool _loading = true;
  bool _cancelando = false;
  String? _error;
  Venta? _venta;
  Timer? _tick;
  Timer? _poll;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_venta?.estadoClave != 'pendiente') return;
      setState(() {});
      final left = _venta?.tiempoRestanteAutoCompletar;
      if (left != null && left == Duration.zero) {
        _cargar(silencioso: true);
      }
    });
    // Misma fuente de verdad que el listado: GET detalle dispara completarVencidas.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || _reloading) return;
      if (_venta?.estadoClave == 'pendiente') {
        _cargar(silencioso: true);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
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
      final v = await _ventaService.fetchVentaPorId(widget.ventaId);
      if (!mounted) return;
      setState(() {
        _venta = v;
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

  Future<void> _confirmarCancelar() async {
    final v = _venta;
    if (v == null || !v.sePuedeCancelar) return;

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

    setState(() => _cancelando = true);
    try {
      final updated = await _ventaService.cancelarCompra(v.id);
      if (!mounted) return;
      setState(() {
        _venta = updated;
        _cancelando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra cancelada')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargar);
    }

    final v = _venta;
    if (v == null) {
      return const Center(
        child: Text('No disponible', style: TextStyle(color: secondaryText)),
      );
    }

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
                _row('Compra', 'Compra #${v.id}'),
                _row('Estado', v.estadoEtiqueta),
                _row('Total', _fmtMoney(v.total)),
                _row('Fecha', _fmtDate(v.createdAt)),
                _row('Forma de pago', v.etiquetaFormaPago),
              ],
            ),
          ),
          if (v.debeMostrarContadorConfirmacion) ...[
            const SizedBox(height: 12),
            Container(
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
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Color(0xFFE65100),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v.mensajeTiempoConfirmacion().trim().isEmpty
                          ? 'Se completará automáticamente'
                          : v.mensajeTiempoConfirmacion(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE65100),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (v.relojRestanteTexto != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      v.relojRestanteTexto!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (v.sePuedeCancelar) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancelando ? null : _confirmarCancelar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _cancelando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancelar compra'),
              ),
            ),
          ] else if (v.estadoClave == 'cancelada') ...[
            const SizedBox(height: 12),
            const Text(
              'Esta compra ya fue cancelada. Los artículos se liberaron.',
              style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.35),
            ),
          ] else if (v.estadoClave == 'completada') ...[
            const SizedBox(height: 12),
            const Text(
              'Esta compra ya está confirmada y no se puede cancelar.',
              style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.35),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Artículos de la compra',
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
                'Sin artículos en esta compra.',
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
            line.etiquetaArticulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _row('Cantidad', '${line.cantidad}'),
          _row('Precio unitario', _fmtMoney(line.precioUnitario)),
          _row('Subtotal', _fmtMoney(line.subtotal)),
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
