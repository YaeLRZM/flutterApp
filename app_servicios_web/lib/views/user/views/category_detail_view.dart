import 'package:flutter/material.dart';

class CategoryDetailView extends StatelessWidget {
  const CategoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2), // Fondo principal
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado estático (Título, Subtítulo y Filtros)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Cuadrícula de productos (Scrollable)
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio:
                  0.58, // Ajusta la proporción para que quepan todos los textos
              children: [
                _buildProductCard(
                  artisan: 'Maestra Juana B.',
                  title: 'Huipil de Gala San Antonino',
                  rating: 12,
                  price: '\$4,850 MXN',
                  isFavorite: false,
                ),
                _buildProductCard(
                  artisan: 'Maestro Pedro M.',
                  title: 'Rebozo de Seda Indigo',
                  rating: 8,
                  price: '\$3,200 MXN',
                  isFavorite: true, // Corazón relleno como en la imagen
                ),
                _buildProductCard(
                  artisan: 'Artesana Sofía G.',
                  title: 'Falda Istmeña Tejida',
                  rating: 24,
                  price: '\$5,400 MXN',
                  isFavorite: false,
                ),
                _buildProductCard(
                  artisan: 'Maestra Elena R.',
                  title: 'Blusa de Telar de Cintura',
                  rating: 5,
                  price: '\$2,750 MXN',
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Textos del Encabezado ---
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Textiles Oaxaqueños',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60), // Rosa Bugambilia
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Obras maestras tejidas en telar de cintura y pedal.',
          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
        ),
      ],
    );
  }

  // --- 2. Fila de Filtros ---
  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('Precio', isSelected: true),
        const SizedBox(width: 8),
        _buildFilterChip('Técnica'),
        const SizedBox(width: 8),
        _buildFilterChip('Artesano'),
      ],
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFD81B60)
            : const Color(0xFFEef4fb), // Rosa vs Azul Claro
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  // --- 3. Tarjeta de Producto Individual ---
  Widget _buildProductCard({
    required String artisan,
    required String title,
    required int rating,
    required String price,
    required bool isFavorite,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen y botón de Favorito
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Placeholder para imagen
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información del producto
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD81B60),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($rating)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD81B60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
