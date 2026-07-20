import 'package:flutter/material.dart';

import 'compra_exitosa_view.dart';

/// Vista de "pago exitoso". Recibe los artículos y el total que vienen
/// de `PaymentProcessingView` para tenerlos disponibles cuando se arme
/// el pedido real contra la API.
///
/// TODO: API -> `items`/`total` hoy solo se reciben y se reenvían; en
/// cuanto exista GET /api/pedidos/{id} esta vista debería mostrar el
/// número de orden y el resumen reales en vez de los valores de muestra.
class PaymentSuccessView extends StatelessWidget {
  final Map<int, int> items;
  final double total;

  const PaymentSuccessView({
    super.key,
    required this.items,
    required this.total,
  });

  void _continuar(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompraExitosaView(items: items),
      ),
    );
  }

  void _descargarComprobante() {
    // TODO: API -> generar/descargar el comprobante real (PDF) del
    // pedido una vez que exista el endpoint correspondiente.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Icono Verde Exitoso
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00BFA5).withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFF00BFA5).withOpacity(0.24),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF00BFA5),
                    child: Icon(Icons.check, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pago Exitoso',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Tarjeta informativa blanca
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '¡Gracias por tu confianza en Ixé Moda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    // Banner del Número de Orden
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD81B60).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'NÚMERO DE ORDEN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD81B60),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '#IXE-92841',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD81B60),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu pedido de \$${total.toStringAsFixed(2)} MXN ha sido '
                      'procesado exitosamente y pronto comenzaremos la '
                      'preparación de tus piezas artesanales.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continuar(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Descargar comprobante
              TextButton.icon(
                onPressed: _descargarComprobante,
                icon: const Icon(
                  Icons.download_outlined,
                  size: 16,
                  color: Color(0xFFD81B60),
                ),
                label: const Text(
                  'Descargar comprobante (PDF)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD81B60),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'ARTESANÍA PREMIUM OAXAQUEÑA',
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
    );
  }
}
