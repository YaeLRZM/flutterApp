import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/notificacion_service.dart';
import '../../widgets/global_top_bar.dart';
import '../../widgets/global_bottom_bar.dart';
import '../../widgets/global_side_menu.dart';
import '../../widgets/global_chatbot_button.dart';
import '../user/views/menu_config_view.dart';
import '../user/views/notificaciones_view.dart';
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
  String _activePage = 'home';
  /// Desde notificaciones: abrir Mis ventas en filtro de efectivo por activar.
  bool _ventasAbrirActivarEfectivo = false;

  final _notificacionService = NotificacionService();
  int _noLeidas = 0;
  Timer? _notifPoll;

  @override
  void initState() {
    super.initState();
    _refrescarBadge();
    // Poll ligero: nuevas ventas / completadas / reseñas.
    _notifPoll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _refrescarBadge();
    });
  }

  @override
  void dispose() {
    _notifPoll?.cancel();
    super.dispose();
  }

  Future<void> _refrescarBadge() async {
    try {
      final result = await _notificacionService.fetchNotificaciones();
      if (!mounted) return;
      setState(() => _noLeidas = result.noLeidas);
    } catch (_) {
      // No bloquear el panel si falla el badge.
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  int get _bottomNavIndex {
    if (_activePage == 'home') return 0;
    if (_activePage == 'productos') return 1;
    if (_activePage == 'ventas') return 2;
    if (_activePage == 'mi_tienda') return 3;
    return 0;
  }

  String get _topBarTitle {
    switch (_activePage) {
      case 'home':
        return 'Panel vendedor';
      case 'productos':
        return 'Mis productos';
      case 'ventas':
        return 'Mis ventas';
      case 'mi_tienda':
        return 'Mi tienda';
      case 'notificaciones':
        return 'Notificaciones';
      case 'configuracion':
        return 'Configuración';
      default:
        return 'Panel vendedor';
    }
  }

  void _go(String page, {bool activarEfectivo = false}) {
    setState(() {
      _activePage = page;
      _ventasAbrirActivarEfectivo =
          page == 'ventas' && activarEfectivo;
      if (_isDrawerOpen) _isDrawerOpen = false;
    });
    if (page == 'notificaciones') {
      _refrescarBadge();
    }
  }

  void _onNotificationsTap() {
    _go('notificaciones');
  }

  Widget _getContentView() {
    switch (_activePage) {
      case 'home':
        return HomeViewVendedor(
          onIrAProductos: () => _go('productos'),
          onIrAVentas: () => _go('ventas'),
          onIrATienda: () => _go('mi_tienda'),
        );
      case 'productos':
        return const ProductosView();
      case 'ventas':
        return VentasView(
          key: ValueKey('ventas_$_ventasAbrirActivarEfectivo'),
          abrirActivarEfectivo: _ventasAbrirActivarEfectivo,
        );
      case 'mi_tienda':
        return const TiendaView();
      case 'notificaciones':
        return NotificacionesView(
          esVendedor: true,
          onIrAMisVentas: () => _go('ventas'),
          onIrAActivarEfectivo: () =>
              _go('ventas', activarEfectivo: true),
          onIrAProductos: () => _go('productos'),
          onIrAInicio: () => _go('home'),
          onNoLeidasChanged: (n) {
            if (mounted) setState(() => _noLeidas = n);
          },
        );
      case 'configuracion':
        return const MenuConfigView();
      default:
        return HomeViewVendedor(
          onIrAProductos: () => _go('productos'),
          onIrAVentas: () => _go('ventas'),
          onIrATienda: () => _go('mi_tienda'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(
        children: [
          GlobalSideMenu(
            onClose: _toggleDrawer,
            isSeller: true,
            currentRoute: _activePage,
            drawerOpen: _isDrawerOpen,
            onNavigate: (route) {
              _toggleDrawer();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                setState(() => _activePage = route);
                if (route == 'notificaciones') {
                  _refrescarBadge();
                }
              });
            },
          ),
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
                        color: Colors.black.withValues(alpha: 0.2),
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
                  title: _topBarTitle,
                  onNotificationsTap: _onNotificationsTap,
                  unreadNotifications: _noLeidas,
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
                  heroTag: 'vendor_fab',
                  tooltip: 'Mis ventas',
                  onPressed: () => _go('ventas'),
                  backgroundColor: const Color(0xFFD81B60),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                bottomNavigationBar: GlobalBottomBar(
                  currentIndex: _bottomNavIndex,
                  isDrawerOpen: _isDrawerOpen,
                  isSeller: true,
                  onTabSelected: (index) {
                    if (index == 0) _go('home');
                    if (index == 1) _go('productos');
                    if (index == 2) _go('ventas');
                    if (index == 3) _go('mi_tienda');
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
