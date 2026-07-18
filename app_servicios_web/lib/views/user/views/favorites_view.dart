import 'package:flutter/material.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F5F2), // Fondo principal
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildAddAllButton(),
          const SizedBox(height: 24),

          // 1. Huipil
          _buildSavedItemCard(
            title: 'Huipil de Gala "Zapoteca"',
            price: '\$3,200',
            artisan: 'Artesana: Elena Santiago',
            status: 'En stock',
            statusColor: Colors.green,
          ),
          const SizedBox(height: 20),

          // 2. Bolso
          _buildSavedItemCard(
            title: 'Bolso Mixteco Piel',
            price: '\$1,850',
            artisan: 'Artesano: Pedro Ruiz',
            status: 'Últimas piezas',
            statusColor: Colors.orange,
          ),
          const SizedBox(height: 20),

          // 3. Pendientes
          _buildSavedItemCard(
            title: 'Pendientes Filigrana Plata',
            price: '\$1,450',
            artisan: 'Artesana: María López',
            status: 'En stock',
            statusColor: Colors.green,
          ),
          const SizedBox(height: 20),

          // 4. Rebozo
          _buildSavedItemCard(
            title: 'Rebozo de Seda Índigo',
            price: '\$2,100',
            artisan: 'Artesana: Rosa Gutiérrez',
            status: 'Agotado',
            statusColor: Colors.red,
          ),

          // Espacio extra al final para que la barra de navegación no tape la última tarjeta
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- Encabezado ---
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU SELECCIÓN PERSONAL',
          style: TextStyle(
            color: Color(0xFFD81B60),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Guardados (12)',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- Botón de Añadir Todo ---
  Widget _buildAddAllButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white,
          size: 18,
        ),
        label: const Text(
          'Añadir todo al carrito',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD81B60),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  // --- Tarjeta de Artículo Guardado ---
  Widget _buildSavedItemCard({
    required String title,
    required String price,
    required String artisan,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de la Imagen y el Corazón
          Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300], // Placeholder para tu imagen
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  // image: DecorationImage(image: AssetImage('assets/tu_imagen.jpg'), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: const Icon(
                    Icons
                        .favorite, // Corazón relleno indicando que está guardado
                    color: Color(0xFFD81B60),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // Sección de Textos y Detalles
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y Precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nombre del Artesano
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      artisan,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Indicador de Stock
                Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
