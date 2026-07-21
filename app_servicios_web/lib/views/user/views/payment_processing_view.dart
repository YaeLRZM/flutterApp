import 'package:flutter/material.dart';

import '../../../services/carrito_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';
import 'payment_denied_view.dart';
import 'payment_success_view.dart';

/// Procesamiento de **pago simulado** (no hay pasarela ni cobro real).
///
/// La venta real (POST /api/ventas) se crea **solo si** el resultado
/// simulado es éxito. En rechazo no se crea venta ni se toca stock.
class PaymentProcessingView extends StatefulWidget {
  final Map<int, int> items;
  final double totalEstimado;

  /// Si es true, al terminar la espera se fuerza éxito.
  /// Si es false, se fuerza rechazo.
  /// Si es null, se muestran botones para elegir el resultado de la simulación.
  final bool? forceSimulateSuccess;

  const PaymentProcessingView({
    super.key,
    required this.items,
    required this.totalEstimado,
    this.forceSimulateSuccess,
  });

  @override
  State<PaymentProcessingView> createState() => _PaymentProcessingViewState();
}

class _PaymentProcessingViewState extends State<PaymentProcessingView> {
  final _ventaService = VentaService();

  bool _esperando = true;
  bool _registrandoCompra = false;
  String? _errorRegistro;

  @override
  void initState() {
    super.initState();
    _iniciarSimulacion();
  }

  Future<void> _iniciarSimulacion() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final forced = widget.forceSimulateSuccess;
    if (forced == true) {
      await _resolverExito();
      return;
    }
    if (forced == false) {
      _irADenegado();
      return;
    }

    // Controlado por el usuario: elegir éxito o rechazo simulado.
    setState(() => _esperando = false);
  }

  Future<void> _resolverExito() async {
    setState(() {
      _registrandoCompra = true;
      _errorRegistro = null;
    });

    try {
      final venta = await _ventaService.crearCompra(items: widget.items);
      CarritoService.instance.vaciar();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessView(
            ventaId: venta.id,
            total: venta.total,
            estado: venta.estado,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registrandoCompra = false;
        _esperando = false;
        _errorRegistro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _irADenegado() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDeniedView(items: widget.items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_registrandoCompra && !_esperando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppStatusBadge.pagoSimulado(),
                        const SizedBox(height: 20),
                        const Text(
                          'Esta app usa un flujo de pago de prueba; '
                          'no se realizará ningún cobro real.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (_registrandoCompra) ...[
                          const CircularProgressIndicator(
                            color: Color(0xFFD81B60),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Registrando compra en el servidor…',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else if (_esperando) ...[
                          const CircularProgressIndicator(
                            color: Color(0xFFD81B60),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Simulando pago de prueba…',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total estimado: \$${widget.totalEstimado.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Elige el resultado de la simulación',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No hay banco ni pasarela. Solo controlas el resultado de prueba.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          if (_errorRegistro != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorRegistro!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _resolverExito,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BFA5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Simular éxito',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _irADenegado,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFC62828)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Simular rechazo',
                                style: TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'IXÉ · FLUJO DE PRUEBA SIN COBRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
