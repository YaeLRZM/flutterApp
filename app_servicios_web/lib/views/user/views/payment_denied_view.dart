import 'package:flutter/material.dart';

import '../../../widgets/app_ui.dart';
import 'checkout_view.dart';

/// Rechazo de **pago simulado**. No hubo intento de cobro real ni venta creada.
class PaymentDeniedView extends StatelessWidget {
  final Map<int, int> items;

  const PaymentDeniedView({super.key, required this.items});

  void _volverACheckout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CheckoutView(items: items)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  children: [
                    AppStatusBadge.pagoSimulado(),
                    const SizedBox(height: 28),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          const Color(0xFFC62828).withValues(alpha: 0.12),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFC62828),
                        child: Icon(Icons.close, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pago de prueba no completado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Resultado de prueba: no se cobró dinero. '
                      'No se registró ninguna compra ni se reservó inventario.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _volverACheckout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD81B60),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Volver al checkout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: const Text('Volver al inicio'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
