import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalSideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final bool isSeller;
  final String currentRoute;
  final Function(String) onNavigate;

  const GlobalSideMenu({
    super.key,
    required this.onClose,
    this.isSeller = false,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        height: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del perfil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=47',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Elena García',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Opciones del menú
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Inicio',
                    isSelected: currentRoute == 'home',
                    onTap: () => onNavigate('home'),
                  ),

                  // Versión Vendedor
                  if (isSeller) ...[
                    _buildDrawerItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Productos',
                      isSelected: currentRoute == 'productos',
                      onTap: () => onNavigate('productos'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.storefront_outlined,
                      title: 'Mi tienda',
                      isSelected: currentRoute == 'mi_tienda',
                      onTap: () => onNavigate('mi_tienda'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Ventas realizadas',
                      isSelected: currentRoute == 'ventas',
                      onTap: () => onNavigate('ventas'),
                    ),
                  ]
                  // Versión Usuario Normal
                  else ...[
                    _buildDrawerItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Mis compras',
                      isSelected: currentRoute == 'mis_compras',
                      onTap: () => onNavigate('mis_compras'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.favorite_border,
                      title: 'Favoritos',
                      isSelected: currentRoute == 'favoritos',
                      onTap: () => onNavigate('favoritos'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notificaciones',
                      badge: '3',
                      isSelected: currentRoute == 'notificaciones',
                      onTap: () => onNavigate('notificaciones'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Mis opiniones',
                      isSelected: currentRoute == 'mis_opiniones',
                      onTap: () => onNavigate('mis_opiniones'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Forma de pago',
                      isSelected: currentRoute == 'forma_pago',
                      onTap: () => onNavigate('forma_pago'),
                    ),
                  ],

                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    isSelected: currentRoute == 'configuracion',
                    onTap: () => onNavigate('configuracion'),
                  ),
                ],
              ),
            ),

            // Botón cerrar sesión (CORREGIDO)
            SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                child: InkWell(
                  onTap: () => _logout(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: Color(0xFFD81B60)),
                      const SizedBox(width: 10),
                      Text(
                        'Cerrar sesión',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFFD81B60),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para manejar el cierre de sesión
  void _logout(BuildContext context) async {
    // Cierra el menú lateral
    onClose();

    // Diálogo de confirmación
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Aquí debes poner tu lógica real de logout
      await _performLogout(context);
    }
  }

  // Lógica real de cierre de sesión
  Future<void> _performLogout(BuildContext context) async {
    // ================== AQUÍ VA TU LÓGICA ==================
    // Ejemplos:

    // 1. Limpiar SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();

    // 2. Si usas flutter_secure_storage
    // await secureStorage.delete(key: 'auth_token');

    // 3. Si usas Provider, Riverpod, Bloc, etc.
    // context.read<AuthProvider>().logout();

    // ======================================================

    // Navegar a login y eliminar todas las pantallas anteriores
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login', // Cambia esta ruta si tu login tiene otro nombre
        (route) => false,
      );
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    String? badge,
  }) {
    return Container(
      color: isSelected
          ? const Color(0xFFD81B60).withOpacity(0.1)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFD81B60) : Colors.black54,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? const Color(0xFFD81B60) : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: badge != null
            ? CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFD81B60),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
