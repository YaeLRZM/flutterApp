import 'package:flutter/material.dart';

/// Imagen de prenda con respaldo visual unificado.
///
/// Orden:
/// 1. URL principal (si es http/https válida)
/// 2. URL de respaldo (si se indica)
/// 3. Contenedor limpio con ícono de prenda (nunca espacio en blanco)
///
/// Sin mensajes técnicos al usuario.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData icon;
  final double? iconSize;
  final Alignment alignment;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.icon = Icons.checkroom_outlined,
    this.iconSize,
    this.alignment = Alignment.center,
  });

  /// Miniatura cuadrada típica (carrito / confirmación).
  const ProductImage.thumb({
    super.key,
    this.imageUrl,
    this.fallbackUrl,
    double size = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.icon = Icons.checkroom_outlined,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  })  : width = size,
        height = size,
        iconSize = size * 0.42;

  /// Normaliza y valida una URL de imagen de red.
  static String? normalizeUrl(String? raw) {
    if (raw == null) return null;
    final url = raw.trim();
    if (url.isEmpty) return null;
    if (url == 'null' || url == 'undefined') return null;
    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    return url;
  }

  static bool isUsable(String? raw) => normalizeUrl(raw) != null;

  @override
  Widget build(BuildContext context) {
    final primary = normalizeUrl(imageUrl);
    final secondary = normalizeUrl(fallbackUrl);

    Widget child;
    if (primary != null) {
      child = _NetworkImageLayer(
        url: primary,
        fallbackUrl: secondary,
        fit: fit,
        width: width,
        height: height,
        icon: icon,
        iconSize: iconSize,
        alignment: alignment,
      );
    } else if (secondary != null) {
      child = _NetworkImageLayer(
        url: secondary,
        fallbackUrl: null,
        fit: fit,
        width: width,
        height: height,
        icon: icon,
        iconSize: iconSize,
        alignment: alignment,
      );
    } else {
      child = ProductImagePlaceholder(
        width: width,
        height: height,
        icon: icon,
        iconSize: iconSize,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}

/// Bloque visual limpio cuando no hay imagen usable.
class ProductImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;
  final double? iconSize;

  const ProductImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.checkroom_outlined,
    this.iconSize,
  });

  static const Color _bg = Color(0xFFF3E5E8);
  static const Color _fg = Color(0xFFD81B60);

  @override
  Widget build(BuildContext context) {
    final resolvedIconSize = iconSize ??
        ((width != null && height != null)
            ? (width! < height! ? width! : height!) * 0.36
            : 36.0);

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: _bg,
        child: Center(
          child: Icon(
            icon,
            size: resolvedIconSize.clamp(16.0, 72.0),
            color: _fg.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _NetworkImageLayer extends StatelessWidget {
  final String url;
  final String? fallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData icon;
  final double? iconSize;
  final Alignment alignment;

  const _NetworkImageLayer({
    required this.url,
    required this.fallbackUrl,
    required this.fit,
    required this.width,
    required this.height,
    required this.icon,
    required this.iconSize,
    required this.alignment,
  });

  Widget _placeholder() => ProductImagePlaceholder(
        width: width,
        height: height,
        icon: icon,
        iconSize: iconSize,
      );

  Widget _onError() {
    final fb = ProductImage.normalizeUrl(fallbackUrl);
    if (fb != null && fb != url) {
      return Image.network(
        fb,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => _onError(),
      loadingBuilder: (context, child, progress) {
        // Evita flash en blanco: mientras carga se ve el fondo suave.
        if (progress == null) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            _placeholder(),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFD81B60).withValues(alpha: 0.35),
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
