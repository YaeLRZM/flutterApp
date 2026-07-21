import 'package:flutter/material.dart';

import '../../../widgets/app_ui.dart';
import '../user_layout.dart';
import 'detalle_pedido_view.dart';

/// Éxito de **pago simulado**. Muestra Compra/Venta #id real.
/// No implica cobro bancario.
///
/// Tras un alta real (POST /api/ventas) se ofrece ir a **Mis compras**
/// con layout fresco para forzar GET /api/ventas (sin lista cacheada).
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePedidoView(ventaId: ventaId),
      ),
    );
  }

  /// Limpia el stack de checkout/pago y abre Mis compras recargando la API.
  void _verMisCompras(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const UserLayout(initialPage: 'mis_compras'),
      ),
      (route) => false,
    );
  }

  String get _estadoLabel {
    switch (estado.trim().toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        final e = estado.trim();
        return e.isEmpty ? 'Pendiente' : e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoLabel = _estadoLabel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
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
                      '¡Listo! Compra registrada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fue un pago de prueba: no se cobró dinero real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
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
                            'Total: \$${total.toStringAsFixed(2)}\n'
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
                            'Tu compra quedó registrada como pendiente. '
                            'Puedes cancelarla desde Mis compras mientras siga pendiente. '
                            'Este fue un pago de prueba: no se cobró dinero real.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Empuja CTAs abajo en pantallas altas; en bajas el scroll
                    // evita overflow (sin Spacer rígido).
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _verMisCompras(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD81B60),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ver mis compras',
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
                        onPressed: () => _verDetalle(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD81B60),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFD81B60)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Ver detalle de esta compra',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
