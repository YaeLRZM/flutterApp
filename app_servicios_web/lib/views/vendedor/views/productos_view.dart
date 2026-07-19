import 'package:flutter/material.dart';

void main() {
  runApp(const ProductosView());
}

class ProductosView extends StatelessWidget {
  const ProductosView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ixé Moda - Catálogo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F5F2), // Fondo Blanco Marfil
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60), // Rosa Bugambilia
          primary: const Color(0xFFD81B60),
          surface: const Color(0xFFFFFFFF),
          error: const Color(0xFFBA1A1A),
        ),
      ),
      home: const ProductCatalogView(),
    );
  }
}

class ProductCatalogView extends StatelessWidget {
  const ProductCatalogView({super.key});

  // Colores extraídos de la configuración
  static const Color primaryColor = Color(0xFFD81B60); // Rosa Bugambilia
  static const Color onSurface = Color(0xFF131D21);
  static const Color secondaryText = Color(0xFF5E6668);
  static const Color outlineVariant = Color(0xFFE0BEC6);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Catálogo de Productos',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administra tu inventario de piezas artesanales exclusivas.',
                style: TextStyle(fontSize: 16, color: secondaryText),
              ),
              const SizedBox(height: 24),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o SKU...',
                  hintStyle: const TextStyle(color: secondaryText),
                  prefixIcon: const Icon(Icons.search, color: secondaryText),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add Product Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Nuevo Producto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos (24)', isSelected: true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Activos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inactivos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sin Stock'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Product List
              _buildProductCard(
                title: 'Huipil Oaxaqueño "Zapoteca"',
                sku: 'IXE-2024-001',
                price: '\$3,450',
                stock: 12,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCa36stQ0FL5NWIKZA6IqtvEXgJBgfas61-gx56uvyaVMcSx3iPQjdvLJdAnw_3zdfdEoHjJVL7CesWKSOdbKsRt7V9H1esjJV2Zh7OPaylRDfoZxz0NaHXgwEDuA991GwDedGjrI9YXvc36pOdk5dwyyXepAzcLBjKNd8oDq-1-Ahv-saYbbOnAmDQp1PeArz8juR8URJ2KoTl_W-oyaTNd1_hFvPAT5Ecj8mkauES49a9X9bgRn6GSg',
                status: 'Activo',
                statusColor: successColor,
              ),
              const SizedBox(height: 16),
              _buildProductCard(
                title: 'Huarache Artesanal "Sol"',
                sku: 'IXE-2024-042',
                price: '\$1,890',
                stock: 8,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB7Ln7QyI1N1oZ8o6fH-DfT7ZkltFxGJCpvfKCDvj6kN4_MJCfwshYr37nDY2PYO7NI7LPP7sfaxwwFNh7rUSxYVphYzPbKeCnUpLbRRBZ873KEIXzdd93cZYihtyLQMpUcMDdO71gy6YlTG8AxSR005mP76SI0av5lw4mW5nNTmHFRt3KLh8TJjnrGlUE6e0he18lJwlKzILlcGrOeVYwTjiBS59pxMnpIP0ATgQMMOOtoZ3ePLEZSxQ',
                status: 'Activo',
                statusColor: successColor,
              ),
              const SizedBox(height: 16),
              _buildProductCard(
                title: 'Jarrón Barro Negro "Luna"',
                sku: 'IXE-2024-015',
                price: '\$5,200',
                stock: 0,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCugRqvz2g_m76qyD6jSgRxqj6O4xhxLu1bd9pjny2Er0ECze5Nrus9x7BHIbj1x7ozTwoe3xfXDCxODYRNp4MTxwWiR0RnAqaG8JC6yNJS_LOADJChWNoiCfS1mudwOu8JE6PLS7VI8EZxHWJRdshFX0EqZofTHJNmFhZLF3V_xgo3vN1wzxwu5BVvLvFxfzqHQ7dYg9J6Xj82KycauFUOKumYDE_N7-EruYcpVQ-0AStxss0QkuZHfw',
                status: 'Inactivo',
                statusColor: secondaryText,
                isGrayscale: true,
              ),
              const SizedBox(height: 16),
              _buildProductCard(
                title: 'Pendientes Filigrana Plata',
                sku: 'IXE-2024-009',
                price: '\$1,250',
                stock: 45,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCMoEExc4moicjj4AiNHGRdnX0hgPlrpFKv_WnbV18-xjkyAgI_qg-pixs4Y4NyN_h_IARlTWvyMIEVEk0KoGSaMNOmIpj25aq5V9DjpQmn1uSXZ6MFT3tr0N2Td86cBIg2VWRXjRPJ5V_w2GWiXsSzVOANLqyX-I_4CbMtFxr7sKnU3Nh8jpwEOJbUpbo0U-axF6jJK8HkQqBgccnKcZq-jYCZ50yTD_jdXlZK7g12vskfR35KGY8jqQ',
                status: 'Activo',
                statusColor: successColor,
              ),
              const SizedBox(height: 16),
              _buildProductCard(
                title: 'Canasta Palma "Tehuacán"',
                sku: 'IXE-2024-058',
                price: '\$850',
                stock: 2,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAZZ48xhBAEmNGUQhqZqPKxDQVYMw4yaH4VWP867VSfeDiJlraZAYlQd3cmNRS7Quexu8Eb6etbUCm38gjLC24kLRAdyYBG5IuVgycOobFist_be-1Z8XOchzS0u6USot8EzhmZN8_tUQHcuG6F8PxhZoWr4zCB09NJ94nkWQvIPxf5QtkeESojCTvEYaC3s2gVtdVriHhs1QEOXbX-WmQotfOpKyNWMcVV6MEPtZuiqZBDQsG1c--Etg',
                status: 'Bajo Stock',
                statusColor: warningColor,
              ),
              const SizedBox(height: 16),

              // Add New Product Placeholder Card
              _buildAddProductPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isSelected ? primaryColor : outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isSelected ? Colors.white : secondaryText,
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String title,
    required String sku,
    required String price,
    required int stock,
    required String imageUrl,
    required String status,
    required Color statusColor,
    bool isGrayscale = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and Status
          Stack(
            children: [
              ColorFiltered(
                colorFilter: isGrayscale
                    ? const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isGrayscale)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: primaryColor,
                        size: 20,
                      ),
                      onPressed: () {},
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: $sku',
                            style: const TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock',
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                        Text(
                          '$stock unidades',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: stock == 0
                                ? const Color(0xFFBA1A1A)
                                : (stock <= 5 ? warningColor : onSurface),
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
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

  Widget _buildAddProductPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48.0),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF0EAE6,
        ).withOpacity(0.5), // Tono neutro/crema suave sin ser azulado
        borderRadius: BorderRadius.circular(12),
        // Nota: Flutter no tiene bordes dashed nativos para Container.
        // Para simularlo visualmente de forma limpia sin paquetes externos usamos un borde sólido sutil.
        border: Border.all(color: outlineVariant, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Agregar producto',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nueva pieza artesanal',
            style: TextStyle(
              fontSize: 12,
              color: secondaryText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
