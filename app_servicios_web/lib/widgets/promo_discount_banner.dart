import 'package:flutter/material.dart';
import '../models/articulo.dart';
import 'product_card_small.dart';

/// Recuadro rosa bugambilia pastel que sustituye al video del artesano.
/// Muestra un título y 2 artículos con descuento en tarjetas chicas.
class PromoDiscountBanner extends StatelessWidget {
  final List<Articulo> articulos;
  final String titulo;
  final ValueChanged<Articulo>? onArticuloTap;

  const PromoDiscountBanner({
    super.key,
    required this.articulos,
    this.titulo = 'Prendas con descuento',
    this.onArticuloTap,
  });

  @override
  Widget build(BuildContext context) {
    if (articulos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5D9E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6A9CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Color(0xFFAD1457), size: 18),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFFAD1457),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final articulo in articulos.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ProductCardSmall(
                articulo: articulo,
                onTap: onArticuloTap == null
                    ? null
                    : () => onArticuloTap!(articulo),
              ),
            ),
        ],
      ),
    );
  }
}
