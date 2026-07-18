import 'package:flutter/material.dart';
// 1. Importamos tus menús y botones globales
import '../../widgets/global_top_bar.dart';
import '../../widgets/global_bottom_bar.dart';
import '../../widgets/global_side_menu.dart';
import '../../widgets/global_chatbot_button.dart';

// 2. IMPORTAMOS TUS VISTAS DE VENDEDOR
import 'views/home_view_vendedor.dart';
import 'views/productos_view.dart';
import 'views/ventas_view.dart';
import 'views/tienda_view.dart';

class VendedorLayout extends StatefulWidget {
  const VendedorLayout({super.key});

  @override
  State<VendedorLayout> createState() => _VendedorLayoutState();
}

class _VendedorLayoutState extends State<VendedorLayout> {
  bool _isDrawerOpen = false;
  int _bottomNavIndex = 0; // 0: Inicio, 1: Productos, 2: Ventas, 3: Mi tienda

  final List<Widget> _views = [
    const HomeViewVendedor(),
    const ProductosView(),
    const VentasView(),
    const TiendaView(),
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

          // MARCO CON EFECTO 3D
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
                appBar: GlobalTopBar.seller(
                  title: 'Panel de Vendedor',
                ),
                body: Stack(
                  children: [
                    GestureDetector(
                      onTap: _isDrawerOpen ? _toggleDrawer : null,
                      child: _views[_bottomNavIndex],
                    ),
                    const GlobalChatbotButton(),
                  ],
                ),
                // En VendedorLayout, dentro del Scaffold:
floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
floatingActionButton: FloatingActionButton(
  heroTag: 'vendor_fab',
  onPressed: () {
    // Navegar a la pestaña de Ventas (índice 2)
    setState(() {
      _bottomNavIndex = 2;
    });
  },
  backgroundColor: const Color(0xFFD81B60),
  shape: const CircleBorder(),
  elevation: 4,
  child: const Icon(
    Icons.attach_money, // o Icons.sell, Icons.trending_up, etc.
    color: Colors.white,
    size: 28,
  ),
),
                bottomNavigationBar: GlobalBottomBar(
                  currentIndex: _bottomNavIndex,
                  isDrawerOpen: _isDrawerOpen,
                  isSeller: true, // modo vendedor
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