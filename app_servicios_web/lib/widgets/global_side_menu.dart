import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalSideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const GlobalSideMenu({super.key, required this.onClose});

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
                    ), // Imagen de ejemplo
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
            _buildDrawerItem(
              icon: Icons.home_outlined,
              title: 'Inicio',
              isSelected: false,
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Mis compras',
              isSelected: true,
            ),
            _buildDrawerItem(
              icon: Icons.favorite_border,
              title: 'Favoritos',
              isSelected: false,
            ),
            _buildDrawerItem(
              icon: Icons.notifications_none_outlined,
              title: 'Notificaciones',
              badge: '3',
              isSelected: false,
            ),
            _buildDrawerItem(
              icon: Icons.chat_bubble_outline,
              title: 'Mis opiniones',
              isSelected: false,
            ),
            _buildDrawerItem(
              icon: Icons.credit_card_outlined,
              title: 'Forma de pago',
              isSelected: false,
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Configuración',
              isSelected: false,
            ),

            const Spacer(),

            // Botón cerrar sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  // Lógica para cerrar sesión
                  Navigator.pop(
                    context,
                  ); // Cierra vista actual o regresa al login
                },
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
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
        onTap: () {},
      ),
    );
  }
}
