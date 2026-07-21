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

  const GlobalTopBar({
    super.key,
    this.title = 'Ixé Moda',
    this.showSearch = true,
    this.onSearchSubmitted,
    this.searchInitialText,
    this.onNotificationsTap,
  });

  const GlobalTopBar.seller({
    super.key,
    this.title = 'Ixé Moda - Vendedor',
    this.onNotificationsTap,
  })  : showSearch = false,
        onSearchSubmitted = null,
        searchInitialText = null;

  factory GlobalTopBar.forUserType({
    required UserType userType,
    String title = 'Ixé Moda',
    ValueChanged<String>? onSearchSubmitted,
    String? searchInitialText,
    VoidCallback? onNotificationsTap,
  }) {
    switch (userType) {
      case UserType.client:
        return GlobalTopBar(
          title: title,
          showSearch: true,
          onSearchSubmitted: onSearchSubmitted,
          searchInitialText: searchInitialText,
          onNotificationsTap: onNotificationsTap,
        );
      case UserType.seller:
        return GlobalTopBar.seller(
          title: title,
          onNotificationsTap: onNotificationsTap,
        );
    }
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(showSearch ? 130 : 85);
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

    return Container(
      padding: EdgeInsets.only(
        top: safeTop + 12,
        left: 20,
        right: 20,
        bottom: widget.showSearch ? 20 : 16,
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
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: _onBellTap,
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          if (widget.showSearch) ...[
            const SizedBox(height: 12),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) =>
                    widget.onSearchSubmitted?.call(value.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar huipil, rebozo, tienda…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
