import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/favoritos_service.dart';
import 'app_ui.dart';

/// Corazón de favoritos con guard de rol vendedor (misma regla que carrito/compra).
///
/// - Comprador/invitado: toggle normal.
/// - Vendedor: icono apagado; al tocar, SnackBar sin mutar favoritos.
class FavoriteHeartButton extends StatefulWidget {
  final int articuloId;
  final double iconSize;
  final double radius;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const FavoriteHeartButton({
    super.key,
    required this.articuloId,
    this.iconSize = 18,
    this.radius = 14,
    this.activeColor = const Color(0xFFD81B60),
    this.inactiveColor = Colors.black54,
    this.backgroundColor = Colors.white,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton> {
  bool _esVendedor = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    FavoritosService.instance.addListener(_onChanged);
    _cargarRol();
  }

  @override
  void dispose() {
    FavoritosService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarRol() async {
    final v = await ApiService().isVendedor();
    if (!mounted) return;
    setState(() => _esVendedor = v);
  }

  Future<void> _onTap() async {
    if (_busy) return;
    if (_esVendedor) {
      AppUi.showAccionNoPermitidaVendedor(context);
      return;
    }
    _busy = true;
    try {
      await FavoritosService.instance.toggle(widget.articuloId);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == ApiService.msgAccionNoPermitidaVendedor) {
        AppUi.showAccionNoPermitidaVendedor(context);
      } else {
        AppUi.showError(context, msg);
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = FavoritosService.instance.esFavorito(widget.articuloId);
    // Vendedor: siempre outline apagado (no semántica de “marcado”).
    final icon = (!_esVendedor && fav) ? Icons.favorite : Icons.favorite_border;
    final color = _esVendedor
        ? Colors.black26
        : (fav ? (widget.activeColor ?? const Color(0xFFD81B60)) : (widget.inactiveColor ?? Colors.black54));

    return Padding(
      padding: widget.padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: widget.radius,
            backgroundColor: widget.backgroundColor.withValues(
              alpha: _esVendedor ? 0.85 : 1,
            ),
            child: Icon(
              icon,
              size: widget.iconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
