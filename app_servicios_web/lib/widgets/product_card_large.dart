import 'package:flutter/material.dart';
import '../models/articulo.dart';
import '../models/cupon.dart';

class ProductCardLarge extends StatelessWidget {
  final Articulo articulo;
  final Cupon? cupon;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const ProductCardLarge({
    super.key,
    required this.articulo,
    this.cupon,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  // TODO: API -> Image.network(articulo.imagenUrl)
                  color: Colors.grey.shade300,
                ),
                if (articulo.vendidos >= 100)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _badge('MÁS VENDIDO', const Color(0xFFD81B60)),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.pink : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    articulo.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  if (articulo.tieneDescuento) ...[
                    Row(
                      children: [
                        _badge(
                          '${articulo.descuentoPorcentaje!.toInt()}% OFF',
                          Colors.green,
                          background: Colors.green.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${articulo.precio.toStringAsFixed(0)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                      children: [
                        TextSpan(text: '\$ ${articulo.precioFinalEntero}'),
                        TextSpan(
                          text: articulo.precioFinalDecimal,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          articulo.region,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (articulo.vendidos > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+${articulo.vendidos} vendidos',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (cupon != null && cupon!.vigente)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cupon!.textoCorto,
                        style: const TextStyle(
                          color: Colors.pink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, {Color? background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: background != null ? color : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
