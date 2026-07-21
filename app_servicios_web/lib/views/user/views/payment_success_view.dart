import 'package:flutter/material.dart';

import '../../../widgets/app_ui.dart';
import 'detalle_pedido_view.dart';

/// Éxito de **pago simulado**. Muestra Compra/Venta #id real.
/// No implica cobro bancario.
class PaymentSuccessView extends StatelessWidget {
  final int ventaId;
  final double total;
  final String estado;

  const PaymentSuccessView({
    super.key,
    required this.ventaId,
    required this.total,
    this.estado = 'completada',
  });

  void _verDetalle(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoView(ventaId: ventaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoLabel =
        estado.trim().isEmpty ? 'completada' : estado.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              AppStatusBadge.pagoSimulado(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.12),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF00BFA5),
                  child: Icon(Icons.check, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pago simulado completado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No se realizó un cobro real; este resultado es de prueba.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'COMPRA REGISTRADA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD81B60),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Compra #$ventaId',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total (servidor): \$${total.toStringAsFixed(2)}\n'
                      'Estado: $estadoLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La venta se guardó en el backend. No hay pasarela ni folio inventado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _verDetalle(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ver detalle de la compra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
