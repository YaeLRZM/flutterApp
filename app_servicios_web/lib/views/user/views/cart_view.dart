import 'package:flutter/material.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F5F2), // Fondo principal
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          // 1. Productos en el carrito
          _buildCartItem(
            title: 'Huipil Gala Bugambilia',
            subtitle: 'SEDA ORGÁNICA • TALLA M',
            price: '\$3,450 MXN',
          ),
          const SizedBox(height: 16),

          _buildCartItem(
            title: 'Bolso Tehuantepec Cuero',
            subtitle: 'CUERO VACUNO • COGNAC',
            price: '\$1,890 MXN',
          ),
          const SizedBox(height: 16),

          _buildCartItem(
            title: 'Pendientes Filigrana Plata',
            subtitle: 'PLATA .925 • HECHO A MANO',
            price: '\$1,200 MXN',
          ),
          const SizedBox(height: 24),

          // 2. Resumen de Compra
          _buildOrderSummary(),
          const SizedBox(height: 16),

          // 3. Badge de Compra Segura
          _buildSecurityBadge(),

          // Espacio extra al final
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- Tarjeta de Producto en Carrito ---
  Widget _buildCartItem({
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300], // Placeholder de imagen
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              // image: DecorationImage(image: AssetImage('assets/tu_imagen.jpg'), fit: BoxFit.cover),
            ),
          ),

          // Detalles del producto
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Controles de cantidad y Precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Selector de cantidad
                    Row(
                      children: [
                        _buildQuantityButton(Icons.remove),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(Icons.add),
                      ],
                    ),

                    // Precio y Eliminar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD81B60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: Colors.red[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Botón circular de cantidad ---
  Widget _buildQuantityButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.3)),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFFD81B60)),
    );
  }

  // --- Tarjeta de Resumen de Compra ---
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Compra',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryRow('Subtotal (3 productos)', '\$6,540.00'),
          const SizedBox(height: 12),
          _buildSummaryRow('Envío (Nacional)', '\$150.00'),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Descuento Artesanal',
            '-\$250.00',
            isDiscount: true,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.black12, height: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '\$6,440.00 MXN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'IVA incluido',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón Continuar Compra
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuar compra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón Elegir más productos
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Elegir más productos',
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Fila individual del resumen ---
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDiscount ? const Color(0xFF00BFA5) : Colors.black54,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDiscount ? const Color(0xFF00BFA5) : Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- Badge de Compra Segura ---
  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEef4fb), // Fondo azul muy claro
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFFD81B60), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Compra Segura',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Protección de datos garantizada',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
