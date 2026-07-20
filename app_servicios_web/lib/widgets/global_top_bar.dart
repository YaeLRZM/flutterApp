import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum UserType { client, seller }

class GlobalTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;

  /// Se dispara al enviar la búsqueda (tecla buscar / enter).
  final ValueChanged<String>? onSearchSubmitted;

  /// Texto mostrado en la barra (última query).
  final String? searchInitialText;

  const GlobalTopBar({
    super.key,
    this.title = 'Ixé Moda',
    this.showSearch = true,
    this.onSearchSubmitted,
    this.searchInitialText,
  });

  const GlobalTopBar.seller({
    super.key,
    this.title = 'Ixé Moda - Vendedor',
  })  : showSearch = false,
        onSearchSubmitted = null,
        searchInitialText = null;

  factory GlobalTopBar.forUserType({
    required UserType userType,
    String title = 'Ixé Moda',
    ValueChanged<String>? onSearchSubmitted,
    String? searchInitialText,
  }) {
    switch (userType) {
      case UserType.client:
        return GlobalTopBar(
          title: title,
          showSearch: true,
          onSearchSubmitted: onSearchSubmitted,
          searchInitialText: searchInitialText,
        );
      case UserType.seller:
        return GlobalTopBar.seller(title: title);
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

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

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
              Text(
                widget.title,
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
          if (widget.showSearch) ...[
            const SizedBox(height: 18),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) =>
                    widget.onSearchSubmitted?.call(value.trim()),
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
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
