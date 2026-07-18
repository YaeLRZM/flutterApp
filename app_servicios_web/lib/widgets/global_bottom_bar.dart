import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onMenuPressed;
  final bool isDrawerOpen;

  const GlobalBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onMenuPressed,
    required this.isDrawerOpen,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(icon: Icons.home_outlined, label: 'Inicio', index: 0),
            _buildNavItem(
              icon: Icons.grid_view_rounded,
              label: 'Colecciones',
              index: 1,
            ),
            const SizedBox(width: 48), // Espacio para el botón flotante central
            _buildNavItem(
              icon: Icons.favorite_border,
              label: 'Favoritos',
              index: 2,
            ),

            // Botón de Menú Hamburguesa
            InkWell(
              onTap: onMenuPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu,
                      color: isDrawerOpen
                          ? const Color(0xFFD81B60)
                          : Colors.black54,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Más',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: isDrawerOpen
                            ? const Color(0xFFD81B60)
                            : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFD81B60) : Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: isSelected ? const Color(0xFFD81B60) : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
