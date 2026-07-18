import 'package:flutter/material.dart';

class VentasView extends StatelessWidget {
  const VentasView({super.key});

  final Color bugambilia = const Color(0xFFD81B60);
  final Color background = const Color(0xFFF8F5F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Text(
              'Gestión de Ventas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: bugambilia,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Controla tus pedidos recientes y el estado de envíos.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // BUSCADOR Y BOTÓN DE EXPORTAR
            Row(
              children: [
                // Buscador
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar pedido...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: bugambilia, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Exportar
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.download_rounded, color: bugambilia, size: 20),
                  label: Text(
                    'Exportar',
                    style: TextStyle(color: bugambilia, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white, // Fondo blanco para que combine con el buscador
                    side: BorderSide(color: bugambilia),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // TARJETAS DE RESUMEN
            _buildSummaryCard(
              title: 'TOTAL VENTAS (MES)',
              value: '\$42,850.00',
              borderColor: bugambilia,
              icon: Icons.payments_outlined,
              iconColor: bugambilia,
              iconBg: bugambilia.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'PEDIDOS ENTREGADOS',
              value: '128',
              borderColor: const Color(0xFF2ECC71),
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF2ECC71),
              iconBg: const Color(0xFFE8F8F5),
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'PENDIENTES DE ENVÍO',
              value: '14',
              borderColor: const Color(0xFFF39C12),
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFFF39C12),
              iconBg: const Color(0xFFFEF5E7),
            ),
            const SizedBox(height: 32),

            // SECCIÓN PEDIDOS RECIENTES Y LEYENDA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Pedidos\nRecientes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: bugambilia,
                    height: 1.2,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendDot('Shipped', const Color(0xFF2ECC71)),
                    const SizedBox(width: 8),
                    _buildLegendDot('Paid', bugambilia),
                    const SizedBox(width: 8),
                    _buildLegendDot('Pending', const Color(0xFFF39C12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // LISTA DE PEDIDOS
            _buildOrderCard(
              status: 'Shipped',
              statusColor: const Color(0xFF2ECC71),
              orderId: '#ORD-4521',
              customerName: 'Elena Gómez',
              productName: 'Rebozo de Seda Artesanal x 1',
              price: '\$2,450.00',
              date: '12 Oct, 2023',
              primaryButtonText: 'Generar Guía',
              primaryButtonStyle: 'outlined',
              bottomActionIcon: Icons.delete_outline,
            ),
            _buildOrderCard(
              status: 'Paid',
              statusColor: bugambilia,
              orderId: '#ORD-4522',
              customerName: 'Marco Aurelio',
              productName: 'Jarrón Barro Negro Especial',
              price: '\$5,200.00',
              date: '13 Oct, 2023',
              primaryButtonText: 'Generar Guía',
              primaryButtonStyle: 'filled',
              bottomActionIcon: Icons.cancel_outlined,
            ),
            _buildOrderCard(
              status: 'Pending',
              statusColor: const Color(0xFFF39C12),
              orderId: '#ORD-4523',
              customerName: 'Sofía Ramírez',
              productName: 'Sandalias Tejidas Florales',
              price: '\$1,280.00',
              date: '14 Oct, 2023',
              primaryButtonText: 'Generar Guía',
              primaryButtonStyle: 'disabled',
              showCancelButton: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // WIDGET PARA LAS TARJETAS DE RESUMEN (Borde lateral)
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: borderColor == bugambilia ? bugambilia : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET PARA LOS PUNTOS DE LA LEYENDA
  Widget _buildLegendDot(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      ],
    );
  }

  // WIDGET PARA LA TARJETA DE CADA PEDIDO
  Widget _buildOrderCard({
    required String status,
    required Color statusColor,
    required String orderId,
    required String customerName,
    required String productName,
    required String price,
    required String date,
    required String primaryButtonText,
    required String primaryButtonStyle,
    IconData? bottomActionIcon,
    bool showCancelButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto (Placeholder)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(Icons.image, color: Colors.black26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de status y Order ID
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          orderId,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      productName,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Precio y Fecha
          Text(
            price,
            style: TextStyle(
              color: bugambilia,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  text: primaryButtonText,
                  style: primaryButtonStyle,
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.access_time, color: Colors.black54, size: 16),
                  label: const Text(
                    'Reprogramar',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
          
          if (bottomActionIcon != null || showCancelButton) ...[
            const SizedBox(height: 16),
            if (showCancelButton)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.cancel_outlined, color: bugambilia, size: 18),
                  label: Text(
                    'Cancelar Compra',
                    style: TextStyle(color: bugambilia, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: bugambilia.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(bottomActionIcon, color: bugambilia),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ]
        ],
      ),
    );
  }

  // WIDGET HELPER PARA ESTILOS DEL BOTÓN PRINCIPAL
  Widget _buildActionBtn({required String text, required String style, required IconData icon}) {
    if (style == 'filled') {
      return ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.white, size: 16),
        label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bugambilia,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } else if (style == 'outlined') {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: bugambilia, size: 16),
        label: Text(text, style: TextStyle(color: bugambilia, fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: bugambilia),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } else {
      // disabled
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_outline, color: Colors.black38, size: 16),
        label: Text(text, style: const TextStyle(color: Colors.black38, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }
  }
}