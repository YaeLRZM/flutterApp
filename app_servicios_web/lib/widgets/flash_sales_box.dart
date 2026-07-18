import 'package:flutter/material.dart';
import '../models/articulo.dart';
import 'countdown_timer.dart';

class FlashSalesBox extends StatelessWidget {
  final List<Articulo> articulos;

  const FlashSalesBox({super.key, required this.articulos});

  @override
  Widget build(BuildContext context) {
    if (articulos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBD38D)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OFERTAS\nRELÁMPAGO',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Row(
                children: const [
                  // TODO: API -> usar la fecha real de fin de promoción.
                  CountdownTimer(
                    duration: Duration(hours: 4, minutes: 44, seconds: 51),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.bolt, color: Colors.orange, size: 30),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final articulo in articulos) _flashItem(articulo),
        ],
      ),
    );
  }

  Widget _flashItem(Articulo articulo) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            // TODO: API -> Image.network(articulo.imagenUrl)
            child: Container(width: 60, height: 60, color: Colors.grey[300]),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${articulo.descuentoPorcentaje?.toInt() ?? 0}% OFF',
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '\$${articulo.precio.toStringAsFixed(0)}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(text: '\$ ${articulo.precioFinalEntero}'),
                    TextSpan(
                      text: articulo.precioFinalDecimal,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
