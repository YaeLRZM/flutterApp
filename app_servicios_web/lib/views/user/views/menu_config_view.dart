import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class MenuConfigView extends StatelessWidget {
  const MenuConfigView({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Blanco marfil
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // --- Cabecera del Perfil ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.grey.shade300,
                            // Aquí iría tu NetworkImage o AssetImage
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        // Botón de editar (Rosa Bugambilia)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mariana Gómez',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'mariana.g@ixemoda.com',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Sección: CUENTA & PREFERENCIAS ---
              _buildSectionTitle('CUENTA & PREFERENCIAS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildListItem(
                      icon: Icons.person_outline,
                      title: 'Perfil',
                      subtitle: 'Información personal, fotos',
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.notifications_none,
                      title: 'Notificaciones',
                      subtitle: 'Push, correo, promociones',
                      hasNotificationDot: true,
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.shield_outlined,
                      title: 'Seguridad',
                      subtitle: 'Contraseña, 2FA, dispositivos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Sección: LEGAL & SOPORTE ---
              _buildSectionTitle('LEGAL & SOPORTE'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildListItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacidad',
                      subtitle: 'Datos, términos de servicio',
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.help_outline,
                      title: 'Ayuda',
                      subtitle: 'Centro de soporte, FAQ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Botón Cerrar Sesión ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Color(0xFFD81B60)),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Color(0xFFD81B60),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFD81B60),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Footer ---
              const Text(
                'IXÉ MODA V2.4.0 • HECHO EN OAXACA',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widgets auxiliares
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool hasNotificationDot = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Icono con fondo rosa pálido
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD81B60).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD81B60), size: 22),
          ),
          const SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Indicador y Flecha
          if (hasNotificationDot)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFD81B60),
                shape: BoxShape.circle,
              ),
            ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
      indent: 64, // Para que la línea no pase debajo del icono
      endIndent: 16,
    );
  }
}
