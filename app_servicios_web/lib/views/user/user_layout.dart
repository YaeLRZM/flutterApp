import 'package:flutter/material.dart';

// 1. IMPORTAMOS TUS MENÚS Y BOTONES GLOBALES
import '../../widgets/global_top_bar.dart';
import '../../widgets/global_bottom_bar.dart';
import '../../widgets/global_side_menu.dart';
import '../../widgets/global_chatbot_button.dart';

// 2. IMPORTAMOS TUS VISTAS PRINCIPALES Y DEL MENÚ LATERAL
import 'views/home_view.dart';
import 'views/collections_view.dart';
import 'views/favorites_view.dart';
import 'views/cart_view.dart';
import 'views/mis_compras_view.dart';
import 'views/notificaciones_view.dart';
import 'views/mis_opiniones_view.dart';
import 'views/formas_de_pago_view.dart';
import 'views/menu_config_view.dart'; // <-- Agregamos la vista de configuración

class UserLayout extends StatefulWidget {
  const UserLayout({super.key});

  @override
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> {
  bool _isDrawerOpen = false;

  // Usamos un String para saber exactamente qué página mostrar
  String _activePage = 'home';

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _goToCart() {
    setState(() {
      _activePage = 'cart';
      if (_isDrawerOpen) _isDrawerOpen = false;
    });
  }

  void _irAColecciones() {
    setState(() => _activePage = 'colecciones');
  }

  // Traduce el string de la página activa al índice del BottomBar
  int get _bottomNavIndex {
    if (_activePage == 'home') return 0;
    if (_activePage == 'colecciones') return 1;
    if (_activePage == 'favoritos') return 2;
    if (_activePage == 'cart') return 3;
    // Si estamos en una vista del menú, dejamos encendido el ícono de Inicio
    return 0;
  }

  // Cambia el título de la barra superior dependiendo de dónde estemos
  String get _topBarTitle {
    switch (_activePage) {
      case 'cart':
        return 'Carrito de Compras';
      case 'mis_compras':
        return 'Mis Compras';
      case 'notificaciones':
        return 'Notificaciones';
      case 'mis_opiniones':
        return 'Mis Opiniones';
      case 'forma_pago':
        return 'Formas de Pago';
      case 'configuracion':
        return 'Configuración'; // <-- Título dinámico agregado
      case 'favoritos':
        return 'Tus Favoritos';
      default:
        return 'Ixé Moda';
    }
  }

  // Decide qué widget pintar en el centro
  Widget _getContentView() {
    switch (_activePage) {
      case 'home':
        return HomeView(onIrAColecciones: _irAColecciones);
      case 'colecciones':
        return const CollectionsView();
      case 'favoritos':
        return const FavoritesView();
      case 'cart':
        return const CartView();

      // Vistas del menú lateral
      case 'mis_compras':
        return const MisComprasView();
      case 'notificaciones':
        return NotificacionesView(); // Sin 'const' por tu configuración
      case 'mis_opiniones':
        return const MisOpinionesView();
      case 'forma_pago':
        return const FormasDePagoView();
      case 'configuracion':
        return const MenuConfigView(); // <-- Vista de configuración integrada

      default:
        return HomeView(onIrAColecciones: _irAColecciones);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          // MENÚ LATERAL
          GlobalSideMenu(
            onClose: _toggleDrawer,
            isSeller: false,
            currentRoute: _activePage,
            onNavigate: (route) {
              _toggleDrawer(); // Cierra la animación 3D primero

              Future.delayed(const Duration(milliseconds: 300), () {
                // AHORA TODAS LAS RUTAS SE CARGAN ADENTRO DEL LAYOUT
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
                appBar: GlobalTopBar(
                  title: _topBarTitle,
                  showSearch:
                      _activePage == 'home' || _activePage == 'colecciones',
                ),
                body: Stack(
                  children: [
                    GestureDetector(
                      onTap: _isDrawerOpen ? _toggleDrawer : null,
                      child: AbsorbPointer(
                        absorbing: _isDrawerOpen,
                        child: _getContentView(),
                      ),
                    ),
                    const GlobalChatbotButton(),
                  ],
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                floatingActionButton: FloatingActionButton(
                  heroTag: 'cart_btn',
                  onPressed: _goToCart,
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
                  isSeller: false,
                  onTabSelected: (index) {
                    setState(() {
                      if (index == 0) _activePage = 'home';
                      if (index == 1) _activePage = 'colecciones';
                      if (index == 2) _activePage = 'favoritos';
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
