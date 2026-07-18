import 'package:flutter/material.dart';

class HomeViewVendedor extends StatelessWidget {
  const HomeViewVendedor({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          const Text(
            '¡Hola, Ixé Vendedor!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu tienda ha crecido un 12% esta semana.\nRevisa tus pedidos pendientes.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // TARJETAS DE ESTADÍSTICAS
          _buildStatCard(
            title: 'VENTAS DIARIAS',
            value: '\$4,250',
            subtitleWidget: Row(
              children: const [
                Icon(Icons.arrow_upward, color: Color(0xFF2ECC71), size: 14),
                SizedBox(width: 4),
                Text('+15% hoy', style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.w600)),
              ],
            ),
            icon: Icons.trending_up,
            iconBg: const Color(0xFFF3E5F5),
            iconColor: const Color(0xFF8E24AA),
          ),
          const SizedBox(height: 16),

          _buildStatCard(
            title: 'PEDIDOS ACTIVOS',
            value: '18',
            subtitle: '8 listos para enviar',
            icon: Icons.local_shipping_outlined,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFF57C00),
          ),
          const SizedBox(height: 16),

          _buildStatCard(
            title: 'VISITAS',
            value: '1,240',
            subtitle: 'Alcance en Ciudad de México',
            icon: Icons.visibility_outlined,
            iconBg: const Color(0xFFECEFF1),
            iconColor: const Color(0xFF546E7A),
          ),
          const SizedBox(height: 24),

          // SECCIÓN DE GRÁFICA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Crecimiento\nde Ventas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        // BOTÓN "SEMANA" CON EL COLOR SOLICITADO
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Semana',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Mes',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // SIMULACIÓN DE GRÁFICA DE BARRAS
                SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(height: 60, isHighlighted: false), // Lun
                      _buildBar(height: 90, isHighlighted: false), // Mar
                      _buildBar(height: 50, isHighlighted: true), // Mié
                      _buildBar(height: 120, isHighlighted: false), // Jue
                      _buildBar(height: 80, isHighlighted: true), // Vie
                      _buildBar(height: 150, isHighlighted: true), // Sáb
                      _buildBar(height: 110, isHighlighted: true), // Dom
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lun', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Mar', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Mié', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Jue', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Vie', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Sáb', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('Dom', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN DE ENVÍOS PENDIENTES
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Envíos Pendientes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        color: const Color(0xFFD81B60),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOrderItem('Huipil de Gala', 'Orden #4421 • Juan Pérez', Icons.more_horiz),
                _buildOrderItem('Barro Negro Jarra', 'Orden #4419 • Maria G.', Icons.more_horiz),
                _buildOrderItem('Huaraches Premium', 'Orden #4415 • Roberto S.', Icons.check_circle_outline,
                    iconColor: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 80), // Espacio para que el FloatingActionButton no tape contenido
        ],
      ),
    );
  }

  // WIDGET REUTILIZABLE PARA TARJETAS DE ESTADÍSTICAS
  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    Widget? subtitleWidget,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              if (subtitleWidget != null) subtitleWidget,
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
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
    );
  }

  // WIDGET REUTILIZABLE PARA BARRAS DE LA GRÁFICA
  Widget _buildBar({required double height, required bool isHighlighted}) {
    return Container(
      width: 32,
      height: height,
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFD81B60) : const Color(0xFFE8BAC8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }

  // WIDGET REUTILIZABLE PARA LOS ITEMS DE ENVÍOS PENDIENTES
  Widget _buildOrderItem(
    String title,
    String subtitle,
    IconData trailingIcon, {
    Color iconColor = Colors.orangeAccent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Placeholder para la imagen del producto
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(trailingIcon, color: iconColor),
        ],
      ),
    );
  }
}