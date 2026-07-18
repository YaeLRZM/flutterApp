import 'package:flutter/material.dart';

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Fondo principal
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildItemsSummary(),
          const SizedBox(height: 24),
          _buildPaymentMethods(),
          const SizedBox(height: 24),
          _buildOrderTotals(),
          const SizedBox(height: 40), // Espacio final
        ],
      ),
    );
  }

  // --- 1. Encabezado ---
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finalizar Pago',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Por favor, revisa tus artículos y selecciona un método de pago para completar tu adquisición de lujo.',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
      ],
    );
  }

  // --- 2. Resumen de Artículos ---
  Widget _buildItemsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen de\nCompra',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD81B60).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '3\nArtículos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD81B60),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSummaryItem(
            imageColor: Colors.pink[100],
            title: 'Huipil Gala',
            subtitle: 'OAXACA TRADICIONAL',
            price: '\$3,800.00',
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            imageColor: Colors.brown[200],
            title: 'Bolso Tehuantepec',
            subtitle: 'PIEL Y TELAR',
            price: '\$1,950.00',
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            imageColor: Colors.grey[300],
            title: 'Pendientes Filigrana',
            subtitle: 'PLATA .925',
            price: '\$690.00',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required Color? imageColor,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: imageColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60),
          ),
        ),
      ],
    );
  }

  // --- 3. Métodos de Pago ---
  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Método de Pago',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Opción Seleccionada (Tarjeta)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD81B60).withOpacity(0.03),
              border: Border.all(color: const Color(0xFFD81B60), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: Color(0xFFD81B60)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tarjeta Crédito/Débito',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Terminada en **** 4421',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Color(0xFFD81B60)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Opción Inactiva (PayPal)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.black54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PayPal Express',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Paga de forma segura',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'PayPal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botón Agregar Nuevo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFD81B60).withOpacity(0.3),
                style: BorderStyle.solid,
              ), // Usamos solid por simplicidad, dotted requiere package extra
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_circle_outline, color: Colors.black54, size: 20),
                SizedBox(width: 8),
                Text(
                  'Agregar nuevo método\nde pago',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Resumen Total y Botón Final ---
  Widget _buildOrderTotals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECEF), // Gris azulado claro de la imagen
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Orden',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD81B60),
            ),
          ),
          const SizedBox(height: 20),

          _buildTotalRow('Subtotal', '\$6,440.00'),
          const SizedBox(height: 12),
          _buildTotalRow('Envío Asegurado', 'GRATIS', isFree: true),
          const SizedBox(height: 12),
          _buildTotalRow('Impuestos (IVA)', 'Incluido'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.black12, height: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '\$6,440.00',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'MXN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Badge de Garantía
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu pago está protegido por nuestra garantía de autenticidad Ixé. Si no estás satisfecho con la calidad artesanal, devolvemos tu dinero.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón Pagar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Finalizar Pago',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.lock_outline, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isFree ? FontWeight.w900 : FontWeight.w600,
            color: isFree ? const Color(0xFF00BFA5) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
