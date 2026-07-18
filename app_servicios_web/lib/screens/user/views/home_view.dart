import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          _buildCategoryFilter(),
          const SizedBox(height: 16),
          _buildFlashSales(),
          const SizedBox(height: 16),
          _buildMainProductCard(),
          const SizedBox(height: 16),
          _buildAlebrijeCard(),
          const SizedBox(height: 16),
          _buildSmallProductCard(),
          const SizedBox(height: 16),
          _buildArtisanVideoCard(),
        ],
      ),
    );
  }

  // 1. Menú superior estilizado
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ["Todo", "Huipiles", "Textiles", "Alebrijes", "Calzado"]
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: entry.key == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: entry.key == 0
                            ? const Color(0xFFD81B60)
                            : Colors.black87,
                      ),
                    ),
                    if (entry.key == 0)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        height: 2,
                        width: 20,
                        color: const Color(0xFFD81B60),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // 2. Recuadro de Ofertas Relámpago
  Widget _buildFlashSales() {
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
                "OFERTAS\nRELÁMPAGO",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Row(
                children: [
                  // TODO: API -> el contador regresivo debe calcularse
                  // con la fecha de fin de la oferta que envíe Laravel.
                  _buildCountdownBox("04"),
                  _buildCountdownSeparator(),
                  _buildCountdownBox("44"),
                  _buildCountdownSeparator(),
                  _buildCountdownBox("51"),
                  const SizedBox(width: 8),
                  const Icon(Icons.bolt, color: Colors.orange, size: 30),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // TODO: API -> reemplazar por un ListView/map con los productos
          // en oferta que devuelva el endpoint de "flash sales".
          _buildFlashItem("36% OFF", "\$335", "213", "49"),
          _buildFlashItem("65% OFF", "\$332", "116", "35"),
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCountdownSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Text(":", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFlashItem(
    String disc,
    String old,
    String priceWhole,
    String priceCents,
  ) {
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
            // TODO: API -> sustituir por Image.network(producto.imagenUrl)
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
                  disc,
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                old,
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
                    const TextSpan(text: "\$ "),
                    TextSpan(text: priceWhole),
                    TextSpan(
                      text: priceCents,
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

  // 3. Tarjeta de producto grande
  Widget _buildMainProductCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                // TODO: API -> Image.network(producto.imagenUrl)
                decoration: const BoxDecoration(color: Colors.grey),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD81B60),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "MÁS VENDIDO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  // TODO: API -> alternar según si el producto está en
                  // favoritos del usuario autenticado.
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.black54,
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
                const Text(
                  "Huipil de Gala Bordado a Mano",
                  style: TextStyle(fontSize: 16, color: Color(0xFF1A73E8)),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "49% OFF",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "\$1,277",
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                    children: [
                      TextSpan(text: "\$ 641"),
                      TextSpan(text: "68", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "LLEGA MAÑANA FULL",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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

  // 4. Tarjeta del Alebrije
  Widget _buildAlebrijeCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // TODO: API -> Image.network(producto.imagenUrl)
              child: Container(height: 250, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Alebrije Jaguar Multicolor Copal",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Text(
                  "\$ 850",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                SizedBox(width: 6),
                Text(
                  "+100 vendidos",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Cupón 15% OFF aplicado",
                style: TextStyle(color: Colors.pink, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: Colors.green,
                ),
                SizedBox(width: 4),
                Text(
                  "Envío Gratis",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. Tarjeta pequeña de producto (estilo "Vaso Barro Negro")
  Widget _buildSmallProductCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            // TODO: API -> Image.network(producto.imagenUrl)
            child: Container(width: 60, height: 60, color: Colors.grey[300]),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vaso Barro Negro",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "San Bartolo Coyotepec",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                "\$ 280",
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Video Artesano
  Widget _buildArtisanVideoCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // TODO: API -> aquí iría el reproductor de video / thumbnail
          // que devuelva Laravel para la sección "Historias de Artesanos".
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Historias de Artesanos",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Conoce el origen del Huipil de Jalatza",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
