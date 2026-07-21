import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onMenuPressed;
  final bool isDrawerOpen;
  final bool isSeller;

  const GlobalBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onMenuPressed,
    required this.isDrawerOpen,
    this.isSeller = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildNavItems(),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    if (isSeller) {
      // FAB central = Mis ventas (notch). Índices: 0 home, 1 productos, 3 tienda.
      return [
        _buildNavItem(Icons.home_outlined, 'Inicio', 0),
        _buildNavItem(Icons.inventory_2_outlined, 'Productos', 1),
        const SizedBox(width: 48),
        _buildNavItem(Icons.storefront_outlined, 'Mi tienda', 3),
        _buildMenuButton(),
      ];
    } else {
      // FAB central = carrito. Índices: 0 home, 1 colecciones, 2 favoritos.
      return [
        _buildNavItem(Icons.home_outlined, 'Inicio', 0),
        _buildNavItem(Icons.grid_view_rounded, 'Colecciones', 1),
        const SizedBox(width: 48),
        _buildNavItem(Icons.favorite_border, 'Favoritos', 2),
        _buildMenuButton(),
      ];
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    // Usamos un padding más reducido para evitar overflow en vendedor
    const double padding = 6.0;
    return InkWell(
      onTap: () => onTabSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFD81B60) : Colors.black54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: isSeller ? 10 : 11, // texto más pequeño en vendedor
                color: isSelected ? const Color(0xFFD81B60) : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    const double padding = 6.0;
    return InkWell(
      onTap: onMenuPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu,
              color: isDrawerOpen ? const Color(0xFFD81B60) : Colors.black54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Más',
              style: GoogleFonts.dmSans(
                fontSize: isSeller ? 10 : 11,
                color: isDrawerOpen ? const Color(0xFFD81B60) : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}