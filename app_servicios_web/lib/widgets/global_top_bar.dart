import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum UserType { client, seller }

class GlobalTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;

  const GlobalTopBar({
    super.key,
    this.title = 'Ixé Moda',
    this.showSearch = true,
  });

  // Constructor para vendedor
  const GlobalTopBar.seller({
    super.key,
    this.title = 'Ixé Moda - Vendedor',
  }) : showSearch = false;

  // Factory según tipo de usuario
  factory GlobalTopBar.forUserType({
    required UserType userType,
    String title = 'Ixé Moda',
  }) {
    switch (userType) {
      case UserType.client:
        return GlobalTopBar(title: title, showSearch: true);
      case UserType.seller:
        return GlobalTopBar.seller(title: title);
    }
  }

  @override
  Size get preferredSize {
    // Altura dinámica según si hay buscador o no
    return Size.fromHeight(showSearch ? 130 : 85);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: safeTop + 12,
        left: 20,
        right: 20,
        bottom: showSearch ? 20 : 16, // menos padding inferior si no hay buscador
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFD81B60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Stack(
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Buscador solo si está activado
          if (showSearch) ...[
            const SizedBox(height: 18),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar en Ixé Moda',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8), // pequeño espacio cuando no hay buscador
        ],
      ),
    );
  }
}