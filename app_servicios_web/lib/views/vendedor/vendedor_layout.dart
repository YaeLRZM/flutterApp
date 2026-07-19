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
// Importamos también las vistas del menú lateral que compartas aquí
import '../user/views/menu_config_view.dart';
// Si tienes notificaciones u otras para el vendedor, impórtalas aquí también
// import 'views/notificaciones_view.dart';

class VendedorLayout extends StatefulWidget {
  const VendedorLayout({super.key});

  @override
  State<VendedorLayout> createState() => _VendedorLayoutState();
}

class _VendedorLayoutState extends State<VendedorLayout> {
  bool _isDrawerOpen = false;

  // Usamos un String para saber exactamente qué página cargar dentro del Layout
  String _activePage = 'home';

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  // Traduce el string de la página activa al índice del BottomBar
  int get _bottomNavIndex {
    if (_activePage == 'home') return 0;
    if (_activePage == 'productos') return 1;
    if (_activePage == 'ventas') return 2;
    if (_activePage == 'mi_tienda') return 3;
    // Si abrimos "configuracion" u otra vista del menú, dejamos encendido el ícono de Inicio
    return 0;
  }

  // Cambia el título de la barra superior dependiendo de la vista activa
  String get _topBarTitle {
    switch (_activePage) {
      case 'home':
        return 'Panel de Vendedor';
      case 'productos':
        return 'Mis Productos';
      case 'ventas':
        return 'Mis Ventas';
      case 'mi_tienda':
        return 'Mi Tienda';
      case 'configuracion':
        return 'Configuración';
      // case 'notificaciones': return 'Notificaciones';
      default:
        return 'Panel de Vendedor';
    }
  }

  // Decide qué widget pintar en el centro dinámicamente
  Widget _getContentView() {
    switch (_activePage) {
      case 'home':
        return const HomeViewVendedor();
      case 'productos':
        return const ProductosView();
      case 'ventas':
        return const VentasView();
      case 'mi_tienda':
        return const TiendaView();

      // Vistas del menú lateral
      case 'configuracion':
        return const MenuConfigView();
      // case 'notificaciones': return NotificacionesView(); // Sin const si te marca error

      default:
        return const HomeViewVendedor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          // MENÚ LATERAL ACTUALIZADO
          GlobalSideMenu(
            onClose: _toggleDrawer,
            isSeller: true, // Modo vendedor
            currentRoute: _activePage, // Le pasamos la ruta actual
            onNavigate: (route) {
              _toggleDrawer(); // Cierra el menú animado primero

              // Espera a que termine la animación 3D (300ms) antes de cambiar la vista
              Future.delayed(const Duration(milliseconds: 300), () {
                // TODAS las rutas se cargan dentro del layout
                setState(() => _activePage = route);
              });
            },
          ),

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
                // Usamos el título dinámico en el top bar
                appBar: GlobalTopBar.seller(title: _topBarTitle),
                body: Stack(
                  children: [
                    GestureDetector(
                      // Bloquea interacciones en el body si el menú está abierto
                      onTap: _isDrawerOpen ? _toggleDrawer : null,
                      child: AbsorbPointer(
                        absorbing: _isDrawerOpen,
                        child:
                            _getContentView(), // AQUÍ CARGAMOS LA VISTA DINÁMICAMENTE
                      ),
                    ),
                    const GlobalChatbotButton(),
                  ],
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                floatingActionButton: FloatingActionButton(
                  heroTag: 'vendor_fab',
                  onPressed: () {
                    // Navegar a la pestaña de Ventas (internamente)
                    setState(() {
                      _activePage = 'ventas';
                      if (_isDrawerOpen) _isDrawerOpen = false;
                    });
                  },
                  backgroundColor: const Color(0xFFD81B60),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                bottomNavigationBar: GlobalBottomBar(
                  currentIndex: _bottomNavIndex,
                  isDrawerOpen: _isDrawerOpen,
                  isSeller: true, // modo vendedor
                  onTabSelected: (index) {
                    setState(() {
                      if (index == 0) _activePage = 'home';
                      if (index == 1) _activePage = 'productos';
                      if (index == 2) _activePage = 'ventas';
                      if (index == 3) _activePage = 'mi_tienda';
                    });
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
