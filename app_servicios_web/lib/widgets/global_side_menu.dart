import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/local_session_store.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';

/// Menú lateral según sesión real:
/// - sin sesión → opciones públicas + Iniciar sesión
/// - con sesión → opciones de cuenta + Cerrar sesión
class GlobalSideMenu extends StatefulWidget {
  final VoidCallback onClose;
  final bool isSeller;
  final String currentRoute;
  final Function(String) onNavigate;

  /// Cuando el drawer se abre, el layout puede reenviar este valor para
  /// forzar una relectura del token (estado real de sesión).
  final bool? drawerOpen;

  const GlobalSideMenu({
    super.key,
    required this.onClose,
    this.isSeller = false,
    required this.currentRoute,
    required this.onNavigate,
    this.drawerOpen,
  });

  @override
  State<GlobalSideMenu> createState() => _GlobalSideMenuState();
}

class _GlobalSideMenuState extends State<GlobalSideMenu> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  @override
  void didUpdateWidget(covariant GlobalSideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al abrir el menú o cambiar de rol/vista, releer sesión real.
    final opened = widget.drawerOpen == true && oldWidget.drawerOpen != true;
    if (opened ||
        widget.isSeller != oldWidget.isSeller ||
        widget.currentRoute != oldWidget.currentRoute) {
      _refreshSession();
    }
  }

  Future<void> _refreshSession() async {
    final token = await ApiService().getToken();
    final active = token != null && token.trim().isNotEmpty;
    if (!mounted) return;
    setState(() {
      _loggedIn = active;
      _checking = false;
    });
  }

  String get _headerLabel {
    if (!_loggedIn) return 'Invitado';
    return widget.isSeller ? 'Cuenta vendedor' : 'Cuenta comprador';
  }

  void _goToLogin() {
    widget.onClose();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  void _goToRegister() {
    widget.onClose();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    });
  }

  Future<void> _logout(BuildContext context) async {
    widget.onClose();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _performLogout(context);
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    await ApiService().logout();
    await LocalSessionStore.onGuest();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.65,
          height: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del perfil / invitado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFFF8BBD0),
                        child: Icon(
                          _loggedIn ? Icons.person : Icons.person_outline,
                          color: const Color(0xFFD81B60),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _checking ? '…' : _headerLabel,
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
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: _checking
                      ? const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD81B60),
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: _menuItems(),
                        ),
                ),

                if (!_checking)
                  SafeArea(
                    bottom: true,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      child: _loggedIn
                          ? _authFooterButton(
                              icon: Icons.logout,
                              label: 'Cerrar sesión',
                              onTap: () => _logout(context),
                            )
                          : Column(
                              children: [
                                _authFooterButton(
                                  icon: Icons.login,
                                  label: 'Iniciar sesión',
                                  onTap: _goToLogin,
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: _goToRegister,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'Registrarme',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _menuItems() {
    // Siempre: inicio (catálogo / panel).
    final items = <Widget>[
      _buildDrawerItem(
        icon: Icons.home_outlined,
        title: 'Inicio',
        isSelected: widget.currentRoute == 'home',
        onTap: () => widget.onNavigate('home'),
      ),
    ];

    if (!_loggedIn) {
      // Invitado: solo opciones públicas del catálogo.
      items.add(
        _buildDrawerItem(
          icon: Icons.favorite_border,
          title: 'Favoritos',
          isSelected: widget.currentRoute == 'favoritos',
          onTap: () => widget.onNavigate('favoritos'),
        ),
      );
      return items;
    }

    // Sesión activa: menú completo según rol.
    if (widget.isSeller) {
      items.addAll([
        _buildDrawerItem(
          icon: Icons.inventory_2_outlined,
          title: 'Mis productos',
          isSelected: widget.currentRoute == 'productos',
          onTap: () => widget.onNavigate('productos'),
        ),
        _buildDrawerItem(
          icon: Icons.storefront_outlined,
          title: 'Mi tienda',
          isSelected: widget.currentRoute == 'mi_tienda',
          onTap: () => widget.onNavigate('mi_tienda'),
        ),
        _buildDrawerItem(
          icon: Icons.receipt_long_outlined,
          title: 'Mis ventas',
          isSelected: widget.currentRoute == 'ventas',
          onTap: () => widget.onNavigate('ventas'),
        ),
        _buildDrawerItem(
          icon: Icons.notifications_none_outlined,
          title: 'Notificaciones',
          isSelected: widget.currentRoute == 'notificaciones',
          onTap: () => widget.onNavigate('notificaciones'),
        ),
      ]);
    } else {
      items.addAll([
        _buildDrawerItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Mis compras',
          isSelected: widget.currentRoute == 'mis_compras',
          onTap: () => widget.onNavigate('mis_compras'),
        ),
        _buildDrawerItem(
          icon: Icons.favorite_border,
          title: 'Favoritos',
          isSelected: widget.currentRoute == 'favoritos',
          onTap: () => widget.onNavigate('favoritos'),
        ),
        _buildDrawerItem(
          icon: Icons.notifications_none_outlined,
          title: 'Notificaciones',
          isSelected: widget.currentRoute == 'notificaciones',
          onTap: () => widget.onNavigate('notificaciones'),
        ),
        _buildDrawerItem(
          icon: Icons.chat_bubble_outline,
          title: 'Mis opiniones',
          isSelected: widget.currentRoute == 'mis_opiniones',
          onTap: () => widget.onNavigate('mis_opiniones'),
        ),
        _buildDrawerItem(
          icon: Icons.credit_card_outlined,
          title: 'Formas de pago',
          isSelected: widget.currentRoute == 'forma_pago',
          onTap: () => widget.onNavigate('forma_pago'),
        ),
      ]);
    }

    items.add(
      _buildDrawerItem(
        icon: Icons.settings_outlined,
        title: 'Configuración',
        isSelected: widget.currentRoute == 'configuracion',
        onTap: () => widget.onNavigate('configuracion'),
      ),
    );

    return items;
  }

  Widget _authFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFD81B60)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: const Color(0xFFD81B60),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    String? badge,
  }) {
    return Material(
      color: isSelected
          ? const Color(0xFFD81B60).withOpacity(0.1)
          : Colors.transparent,
      child: ListTile(
        tileColor: Colors.transparent,
        selectedTileColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
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
