import 'package:app_servicios_web/views/user/views/category_detail_view.dart';
import 'package:flutter/material.dart';

class CollectionsView extends StatelessWidget {
  const CollectionsView({super.key});

  void _navigateToCategory(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailView(categoryTitle: title),
      ),
    );
  }

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

          _buildCategoryCard(
            title: 'Huipiles',
            description:
                'Tejidos a mano que narran historias ancestrales con hilos de seda y algodón natural.',
            isPremium: true,
            onTap: () => _navigateToCategory(context, 'Huipiles'),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            title: 'Guayaberas',
            description:
                'Elegancia y frescura en lino con bordados tradicionales de la región.',
            onTap: () => _navigateToCategory(context, 'Guayaberas'),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            title: 'Vestidos Tehuanos',
            description:
                'Color y tradición del Istmo, bordados a mano sobre terciopelo y satín.',
            onTap: () => _navigateToCategory(context, 'Vestidos Tehuanos'),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            title: 'Rebozos de Seda',
            description:
                'Elaborados en telar de cintura, un complemento indispensable de la indumentaria.',
            onTap: () => _navigateToCategory(context, 'Rebozos de Seda'),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            title: 'Prendas de Manta',
            description:
                'Diseños contemporáneos fusionados con técnicas textiles de los valles centrales.',
            onTap: () => _navigateToCategory(context, 'Prendas de Manta'),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade300,
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
            // El degradado y textos igual que antes
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
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
      ),
    );
  }
}
