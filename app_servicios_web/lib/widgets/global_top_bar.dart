import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_ui.dart';

enum UserType { client, seller }

class GlobalTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;

  /// Se dispara al enviar la búsqueda (tecla buscar / enter).
  final ValueChanged<String>? onSearchSubmitted;

  /// Texto mostrado en la barra (última query).
  final String? searchInitialText;

  /// Campana: si no se provee, muestra “próxima versión” (sin badge falso).
  final VoidCallback? onNotificationsTap;

  /// No leídas reales (0 = sin badge). Nunca inventar conteos.
  final int unreadNotifications;

  const GlobalTopBar({
    super.key,
    this.title = 'Ixé Moda',
    this.showSearch = true,
    this.onSearchSubmitted,
    this.searchInitialText,
    this.onNotificationsTap,
    this.unreadNotifications = 0,
  });

  const GlobalTopBar.seller({
    super.key,
    this.title = 'Ixé Moda - Vendedor',
    this.onNotificationsTap,
    this.unreadNotifications = 0,
  })  : showSearch = false,
        onSearchSubmitted = null,
        searchInitialText = null;

  factory GlobalTopBar.forUserType({
    required UserType userType,
    String title = 'Ixé Moda',
    ValueChanged<String>? onSearchSubmitted,
    String? searchInitialText,
    VoidCallback? onNotificationsTap,
    int unreadNotifications = 0,
  }) {
    switch (userType) {
      case UserType.client:
        return GlobalTopBar(
          title: title,
          showSearch: true,
          onSearchSubmitted: onSearchSubmitted,
          searchInitialText: searchInitialText,
          onNotificationsTap: onNotificationsTap,
          unreadNotifications: unreadNotifications,
        );
      case UserType.seller:
        return GlobalTopBar.seller(
          title: title,
          onNotificationsTap: onNotificationsTap,
          unreadNotifications: unreadNotifications,
        );
    }
  }

  @override
  Size get preferredSize {
    // Altura del contenido del bar (Scaffold suma el safe-area/status bar aparte).
    // Antes: 130 dejaba ~3–7 px de overflow (title row ~48 + search 45 + paddings).
    return Size.fromHeight(showSearch ? 140 : 88);
  }

  @override
  State<GlobalTopBar> createState() => _GlobalTopBarState();
}

class _GlobalTopBarState extends State<GlobalTopBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchInitialText ?? '',
    );
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant GlobalTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.searchInitialText ?? '';
    if (next != _searchController.text &&
        next != oldWidget.searchInitialText) {
      _searchController.text = next;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBellTap() {
    if (widget.onNotificationsTap != null) {
      widget.onNotificationsTap!();
      return;
    }
    AppUi.showProximamente(context, feature: 'Notificaciones');
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchSubmitted?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    // safeTop se pinta DENTRO del espacio que Scaffold reserva
    // (preferredSize + padding.top). El bloque de contenido (sin safeTop)
    // debe caber en preferredSize para no desbordar.
    return Container(
      padding: EdgeInsets.only(
        top: safeTop + 10,
        left: 20,
        right: 20,
        bottom: widget.showSearch ? 12 : 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFD81B60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Notificaciones',
                  onPressed: _onBellTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Badge(
                    isLabelVisible: widget.unreadNotifications > 0,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFFD81B60),
                    label: Text(
                      widget.unreadNotifications > 99
                          ? '99+'
                          : '${widget.unreadNotifications}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Icon(
                      widget.unreadNotifications > 0
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showSearch) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) =>
                      widget.onSearchSubmitted?.call(value.trim()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar huipil, rebozo, tienda…',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 22,
                    ),
                    suffixIcon: hasQuery
                        ? IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: _clearSearch,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
