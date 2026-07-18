import 'package:flutter/material.dart';
// 1. Importamos tus menús y botones globales
import '../../widgets/global_top_bar.dart';
import '../../widgets/global_bottom_bar.dart';
import '../../widgets/global_side_menu.dart';
import '../../widgets/global_chatbot_button.dart'; // <-- NUEVO IMPORT

// 2. IMPORTAMOS TU VISTA PRINCIPAL
import 'views/home_view.dart';

class UserLayout extends StatefulWidget {
  const UserLayout({super.key});

  @override
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> {
  bool _isDrawerOpen = false;
  int _bottomNavIndex = 0;

  final List<Widget> _views = [
    const HomeView(),
    const Center(child: Text('Colecciones en blanco')),
    const Center(child: Text('Favoritos en blanco')),
  ];

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          // MENÚ LATERAL
          GlobalSideMenu(onClose: _toggleDrawer),

          // EL MARCO CON EFECTO 3D
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _isDrawerOpen ? -screenWidth * 0.65 : 0,
              _isDrawerOpen ? 40 : 0,
              0,
            )..scale(_isDrawerOpen ? 0.85 : 1.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F2),
              borderRadius: _isDrawerOpen
                  ? BorderRadius.circular(30)
                  : BorderRadius.zero,
              boxShadow: _isDrawerOpen
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: _isDrawerOpen
                  ? BorderRadius.circular(30)
                  : BorderRadius.zero,
              child: Scaffold(
                backgroundColor: Colors.transparent,

                appBar: const GlobalTopBar(),

                // AQUÍ ESTÁ EL CAMBIO: Envolvemos el cuerpo en un Stack
                body: Stack(
                  children: [
                    // Tu contenido dinámico
                    GestureDetector(
                      onTap: _isDrawerOpen ? _toggleDrawer : null,
                      child: _views[_bottomNavIndex],
                    ),

                    // <-- TU WIDGET GLOBAL DEL CHATBOT -->
                    const GlobalChatbotButton(),
                  ],
                ),

                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                floatingActionButton: FloatingActionButton(
                  heroTag:
                      'cart_btn', // Etiqueta para diferenciarlo del chatbot
                  onPressed: () {},
                  backgroundColor: const Color(0xFFD81B60),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                bottomNavigationBar: GlobalBottomBar(
                  currentIndex: _bottomNavIndex,
                  isDrawerOpen: _isDrawerOpen,
                  onTabSelected: (index) {
                    setState(() => _bottomNavIndex = index);
                  },
                  onMenuPressed: _toggleDrawer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
