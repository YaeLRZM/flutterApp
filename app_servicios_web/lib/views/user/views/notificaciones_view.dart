import 'package:flutter/material.dart';

class NotificacionesView extends StatelessWidget {
  const NotificacionesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Blanco marfil
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ACTIVIDAD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD81B60), // Rosa bugambilia
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.checklist, color: Color(0xFFD81B60), size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Marcar\ntodas\ncomo\nleídas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjeta 1: Pedido Enviado (con marca de agua)
            _buildNotificationCard(
              icon: Icons.inventory_2,
              iconBgColor: const Color(0xFFD81B60).withOpacity(0.1),
              iconColor: const Color(0xFFD81B60),
              title: 'Tu pedido ha sido\nenviado',
              time: 'Hace 5 min',
              content:
                  '¡Excelentes noticias! Tu pedido artesanal ha salido del taller y está en camino a tu hogar.',
              isNew: true,
              watermarkIcon: Icons.local_shipping,
            ),
            const SizedBox(height: 16),

            // Tarjeta 2: Nueva Colección
            _buildNotificationCard(
              icon: Icons.storefront,
              iconBgColor: Colors.orange.withOpacity(0.15),
              iconColor: Colors.orange.shade700,
              title: 'Nueva colección de\nHuipiles',
              time: 'Hace 2 h',
              content:
                  'Descubre la esencia de Oaxaca en nuestra nueva colección de temporada. Piezas únicas hechas a mano.',
              hasAvatars: true,
            ),
            const SizedBox(height: 16),

            // Tarjeta 3: Recordatorio de Carrito
            _buildNotificationCard(
              icon: Icons.shopping_bag,
              iconBgColor: const Color(0xFFD81B60).withOpacity(0.1),
              iconColor: const Color(0xFFD81B60),
              title: 'Recordatorio de carrito',
              time: 'Ayer',
              content:
                  'Tus piezas favoritas te están esperando. Finaliza tu compra hoy y recibe un regalo sorpresa.',
              actionButtonText: 'Continuar Compra',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String time,
    required String content,
    bool isNew = false,
    IconData? watermarkIcon,
    bool hasAvatars = false,
    String? actionButtonText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Marca de agua (Icono grande de fondo)
            if (watermarkIcon != null)
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  watermarkIcon,
                  size: 100,
                  color: Colors.grey.withOpacity(0.05),
                ),
              ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFFD81B60),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Nuevo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD81B60),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (hasAvatars) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 45,
                                child: Stack(
                                  children: [
                                    _buildAvatarPlaceholder(
                                      Colors.pink.shade100,
                                    ),
                                    Positioned(
                                      left: 15,
                                      child: _buildAvatarPlaceholder(
                                        Colors.orange.shade100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '+12 modelos',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (actionButtonText != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD81B60),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                actionButtonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildAvatarPlaceholder(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.image, size: 10, color: Colors.black26),
    );
  }
}
