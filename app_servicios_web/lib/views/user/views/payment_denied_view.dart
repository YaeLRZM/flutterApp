import 'package:flutter/material.dart';

class PaymentDeniedView extends StatelessWidget {
  const PaymentDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: Column(
          children: [
            // Línea superior decorativa roja que muestra la imagen de muestra
            Container(
              height: 4,
              width: double.infinity,
              color: const Color(0xFFC62828),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                children: [
                  // Icono Alerta Rojo
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(
                        0xFFC62828,
                      ).withOpacity(0.12),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFC62828),
                        child: Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Pago Denegado',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lo sentimos, el pago no pudo procesarse. Tu transacción ha sido interrumpida por motivos de seguridad o administrativos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tarjetas informativas de posibles errores
                  _buildErrorReasonCard(
                    icon: Icons.subtitles_off_outlined,
                    title: 'Fondos Insuficientes',
                    subtitle:
                        'Verifica el saldo disponible en tu cuenta antes de reintentar.',
                  ),
                  const SizedBox(height: 12),
                  _buildErrorReasonCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tarjeta Expirada',
                    subtitle:
                        'Asegúrate de que la fecha de vencimiento sea válida.',
                  ),
                  const SizedBox(height: 12),
                  _buildErrorReasonCard(
                    icon: Icons.lock_person_outlined,
                    title: 'Bloqueo Bancario',
                    subtitle:
                        'Tu banco podría haber pausado la compra por seguridad.',
                  ),
                  const SizedBox(height: 12),
                  _buildErrorReasonCard(
                    icon: Icons.wifi_off_outlined,
                    title: 'Error de Conexión',
                    subtitle: 'Hubo una interrupción técnica momentánea.',
                  ),

                  const SizedBox(height: 40),

                  // Botones de salida
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Reintentar Pago',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD81B60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.credit_card,
                        color: Color(0xFFD81B60),
                        size: 18,
                      ),
                      label: const Text(
                        'Cambiar método de pago',
                        style: TextStyle(
                          color: Color(0xFFD81B60),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFD81B60),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorReasonCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FB).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFC62828)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
