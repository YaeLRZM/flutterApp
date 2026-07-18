import 'package:flutter/material.dart';

class CollectionsView extends StatelessWidget {
  const CollectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Container con el color de fondo base
    return Container(
      color: const Color(0xFFF8F5F2),
      // ListView es ideal aquí para permitir el scroll de las tarjetas grandes
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // 1. Huipiles (Con la etiqueta premium de la imagen)
          _buildCategoryCard(
            title: 'Huipiles',
            description:
                'Tejidos a mano que narran historias ancestrales con hilos de seda y algodón natural.',
            isPremium: true,
          ),
          const SizedBox(height: 16),

          // 2. Guayaberas
          _buildCategoryCard(
            title: 'Guayaberas',
            description:
                'Elegancia y frescura en lino con bordados tradicionales de la región.',
          ),
          const SizedBox(height: 16),

          // 3. Vestidos Tehuanos
          _buildCategoryCard(
            title: 'Vestidos Tehuanos',
            description:
                'Color y tradición del Istmo, bordados a mano sobre terciopelo y satín.',
          ),
          const SizedBox(height: 16),

          // 4. Rebozos y Textiles
          _buildCategoryCard(
            title: 'Rebozos de Seda',
            description:
                'Elaborados en telar de cintura, un complemento indispensable de la indumentaria.',
          ),
          const SizedBox(height: 16),

          // 5. Ropa de Manta
          _buildCategoryCard(
            title: 'Prendas de Manta',
            description:
                'Diseños contemporáneos fusionados con técnicas textiles de los valles centrales.',
          ),

          // Espacio extra al final para que el menú inferior o el botón del chatbot no tapen la última tarjeta
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Construye los títulos superiores basados en la imagen
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colecciones\nIxé',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.1, // Reduce el espacio entre las dos líneas
            color: Color(0xFFD81B60), // Tu rosa bugambilia
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Descubre la esencia de Oaxaca a través de nuestras categorías curadas por maestros artesanos.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Construye cada tarjeta de categoría con su imagen, degradado y textos
  Widget _buildCategoryCard({
    required String title,
    required String description,
    bool isPremium = false,
  }) {
    return Container(
      height: 240, // Altura de las tarjetas grandes de la imagen
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Aquí agregarás tu DecorationImage cuando tengas los assets reales.
        // Ejemplo: image: DecorationImage(image: AssetImage('assets/huipil.jpg'), fit: BoxFit.cover),
        color: Colors.grey.shade300, // Placeholder temporal
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Capa 1: El degradado oscuro para que el texto sea legible (exactamente como en la imagen)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.85), // Oscurece al fondo
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Capa 2: Los textos posicionados en la parte inferior
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
                        color: Color(
                          0xFFF48FB1,
                        ), // Un rosa claro para contrastar en el fondo oscuro
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
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
    );
  }
}
