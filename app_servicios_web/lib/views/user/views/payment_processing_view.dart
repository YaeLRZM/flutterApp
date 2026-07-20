import 'package:flutter/material.dart';

import '../../../services/carrito_service.dart';
import 'payment_denied_view.dart';
import 'payment_success_view.dart';

/// Vista de "procesando pago". Recibe los artículos y el total que
/// vienen de `CheckoutView`, simula la validación con el banco y
/// navega automáticamente a `PaymentSuccessView` (o `PaymentDeniedView`,
/// dejado listo aunque hoy no se dispare) según el resultado.
///
/// TODO: API -> hoy simula el resultado del pago (siempre éxito, con un
/// retraso fijo vía `Future.delayed`). Cuando exista el endpoint real,
/// `_procesarPago` debe esperar la respuesta de POST /api/pedidos (o
/// consultar su estado) y navegar a PaymentSuccessView o
/// PaymentDeniedView según lo que regrese Laravel, en vez de simular
/// siempre éxito.
class PaymentProcessingView extends StatefulWidget {
  final Map<int, int> items;
  final double total;

  const PaymentProcessingView({
    super.key,
    required this.items,
    required this.total,
  });

  @override
  State<PaymentProcessingView> createState() => _PaymentProcessingViewState();
}

class _PaymentProcessingViewState extends State<PaymentProcessingView> {
  @override
  void initState() {
    super.initState();
    _procesarPago();
  }

  Future<void> _procesarPago() async {
    // TODO: API -> reemplazar por la llamada real y esperar su
    // resultado en vez de un retraso fijo simulado.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Simulación: el pago siempre es exitoso por ahora. `_irADenegado`
    // queda listo (sin usarse) para cuando el backend pueda regresar
    // un rechazo real.
    _irAExitoso();
  }

  void _irAExitoso() {
    // Quita del carrito los artículos que se acaban de comprar (si el
    // pedido venía de "Comprar ahora" y no del carrito, esto no hace
    // nada porque esos ids nunca estuvieron ahí).
    for (final articuloId in widget.items.keys) {
      CarritoService.instance.quitar(articuloId);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentSuccessView(items: widget.items, total: widget.total),
      ),
    );
  }

  // ignore: unused_element
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
      // Evita que el usuario interrumpa la validación a medias con el
      // botón/gesto de "atrás" mientras se simula el pago.
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5F2),
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Contenedor blanco central estilo tarjeta
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Artesania Premium',
                        style: TextStyle(
                          color: Color(0xFFD81B60),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logotipo abstracto simulado con formas concéntricas
                      _buildAbstractLoader(),

                      const SizedBox(height: 40),
                      const Text(
                        'Validando tu pago...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Estamos conectando con tu banco de forma segura para confirmar tu pedido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Badges de Seguridad
                      _buildSecurityBadge(
                        Icons.lock_outline,
                        'Cifrado SSL de 256 bits',
                        const Color(0xFF00BFA5),
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityBadge(
                        Icons.security,
                        'Pago Seguro',
                        const Color(0xFFD81B60),
                      ),

                      const SizedBox(height: 40),

                      // Barra de progreso inferior estática (15%)
                      _buildProgressBar(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Footer
              const Text(
                'IXÉ MODA - HERENCIA TEXTIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildAbstractLoader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD81B60).withOpacity(0.15),
              width: 2,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD81B60).withOpacity(0.08),
              width: 1.5,
            ),
          ),
        ),
        // Icono interno o vector que asemeja el logo del ojo/hoja estilizado
        Transform.rotate(
          angle: 0.7,
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              border: Border.all(color: const Color(0xFFD81B60), width: 2),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFD81B60),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        // Destello superior derecho
        const Positioned(
          top: 14,
          right: 14,
          child: Icon(Icons.auto_awesome, color: Color(0xFFD81B60), size: 16),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 50, // Representa el 15% visual
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD81B60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Verificando fondos',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),
            Text(
              '15%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD81B60),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
