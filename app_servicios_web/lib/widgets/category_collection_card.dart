import 'package:flutter/material.dart';
import '../models/categoria.dart';
import 'product_image.dart';

/// Tarjeta grande con imagen de fondo, degradado y textos, usada en
/// `CollectionsView`. Es puramente presentacional: recibe ya resuelto
/// si es "premium" y cuántos artículos tiene, para no acoplarse a cómo
/// se calculan esos datos.
class CategoryCollectionCard extends StatelessWidget {
  final Categoria categoria;
  final int totalArticulos;
  final bool isPremium;
  final VoidCallback? onTap;

  const CategoryCollectionCard({
    super.key,
    required this.categoria,
    this.totalArticulos = 0,
    this.isPremium = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF3E5E8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImage(
              imageUrl: categoria.imagen,
              width: double.infinity,
              height: 240,
              icon: Icons.grid_view_rounded,
            ),
            // Degradado oscuro para que el texto sea legible.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Pastilla con el conteo de artículos (arriba a la derecha).
            if (totalArticulos > 0)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '+$totalArticulos artículos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Textos en la parte inferior.
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPremium)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'CURADURÍA PREMIUM',
                        style: TextStyle(
                          color: Color(0xFFF48FB1),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  Text(
                    categoria.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((categoria.descripcion ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      categoria.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
