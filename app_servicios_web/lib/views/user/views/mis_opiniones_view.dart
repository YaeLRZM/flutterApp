import 'package:flutter/material.dart';

class MisOpinionesView extends StatelessWidget {
  const MisOpinionesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Blanco marfil
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Mis Opiniones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFD81B60), // Rosa bugambilia
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gestiona las reseñas de tus piezas artesanales.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Reseña 1
            _buildReviewCard(
              productName: 'Huipil Oaxaqueño Floral',
              rating: 5,
              date: 'Publicado hace 2 días',
              reviewText:
                  '"La calidad del bordado es simplemente excepcional. Se nota el trabajo artesanal en cada puntada. El color Rosa Bugambilia es vibrante y fiel a las fotos."',
            ),
            const SizedBox(height: 16),

            // Reseña 2
            _buildReviewCard(
              productName: 'Bolso "Sol de Oaxaca"',
              rating: 4,
              date: 'Publicado el 15 Oct',
              reviewText:
                  '"El cuero es de excelente calidad y el tamaño es perfecto para el diario. Me hubiera gustado que la correa fuera un poco más larga, pero en general es una pieza hermosa."',
            ),
            const SizedBox(height: 16),

            // Reseña 3
            _buildReviewCard(
              productName: 'Aretes de Filigrana',
              rating: 5,
              date: 'Publicado el 02 Sep',
              reviewText:
                  '"Piezas de colección. Pesan muy poco a pesar de su tamaño y los detalles son finísimos. Recibo cumplidos cada vez que los uso."',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String productName,
    required int rating,
    required String date,
    required String reviewText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen placeholder del producto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.black26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Estrellas
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating
                              ? const Color(
                                  0xFFD81B60,
                                ) // Bugambilia si está activa
                              : Colors.grey.shade300, // Gris si está inactiva
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Caja de texto de la reseña
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors
                  .grey
                  .shade50, // Gris neutro muy claro, eliminando azulados
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reviewText,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botón Editar
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD81B60), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Editar',
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
