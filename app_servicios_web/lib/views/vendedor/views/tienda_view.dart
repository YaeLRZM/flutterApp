import 'package:flutter/material.dart';

class TiendaView extends StatelessWidget {
  const TiendaView({Key? key}) : super(key: key);

  // Colores principales actualizados
  static const Color colorBugambilia = Color(0xFFD81B60);
  static const Color colorFondoMarfil = Color(0xFFF8F5F2);
  static const Color colorSuperficie = Colors.white;
  static const Color colorTextoSecundario = Color(0xFF5E6668);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondoMarfil,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerYPerfil(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildTarjetaEsencia(),
                  const SizedBox(height: 16),
                  _buildMetricas(),
                  const SizedBox(height: 32),
                  _buildEncabezadoEscaparate(),
                  const SizedBox(height: 16),
                  _buildListaProductos(),
                  const SizedBox(height: 32), // Espacio extra al final
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerYPerfil() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner principal
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            image: DecorationImage(
              image: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCF-ZV1OGnwaWHgCpVFsG-CRgOxgMrLfBZaCT0RqM9QZBPqOJmtRL-TS_t-goGw7_X47PEcIi1CW99JpaZlUPlJXyv51krv-WkwNQIbQ_eWW3KF1IbwR8ozmPm60LjEmd-laIKKCeMTURJdgX-z6Q_sf7J4V0l97ykA-ZMZ07kNTfv7lNEFA4xH56ub7p5kXRVLBhfPuT82UTFrjZCFcH8dNz6RfTxnSDPqml_npTuvAftZMvZI5X1OJg',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Imagen de perfil superpuesta a la derecha
        Positioned(
          bottom: -20,
          right: 24,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorSuperficie,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC4ggkuiBCMDORFPWcpbT51wwoAvE2EFCJTV70_0vQ4VXJYMfYH-VNWZ0C3536Tv0eJlMvprZMA6Adsyv7fleJby_elohkGyFicijyprtl64A_vnIopOX4DS0-79pjaLpEMzc_9b07ttZ6GCvNLb1H1eXrY0W8jvJfOkxP3-89mYQDjkP2BeBZBiJE4x86FFEmWop98t-ODC8gaujBc_OhGFlVmRBW14uRQh2LQ7CND_GF-MFz4qqcPBg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaEsencia() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuestra Esencia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorBugambilia,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ixé Artesano nace del corazón de Oaxaca, fusionando técnicas ancestrales con la visión contemporánea de la moda premium. Cada pieza en nuestra tienda es una narrativa de hilos y pigmentos naturales, curada para quienes valoran la autenticidad y el lujo consciente. Nos especializamos en textiles de seda silvestre y acabados en telar de cintura que honran nuestra herencia.',
            style: TextStyle(
              fontSize: 14,
              color: colorTextoSecundario,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Oaxaca, MX', const Color(0xFF10b981)),
              _buildChip('Sustentable', colorBugambilia),
              _buildChip('Artesanal', const Color(0xFFf59e0b)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF0EAE6,
        ), // Tono cálido en lugar del azulado anterior
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorTextoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricas() {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaMetrica(
            Icons.shopping_bag_outlined,
            '142',
            'PRODUCTOS',
            colorBugambilia,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTarjetaMetrica(
            Icons.trending_up,
            '98%',
            'CUMPLIMIENTO',
            const Color(0xFF10b981),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaMetrica(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorBugambilia,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: colorTextoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncabezadoEscaparate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Escaparate Público',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorBugambilia,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Lo que tus clientes ven actualmente',
              style: TextStyle(fontSize: 12, color: colorTextoSecundario),
            ),
          ],
        ),
        Row(
          children: const [
            Text(
              'Ver todo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorBugambilia,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 16, color: colorBugambilia),
          ],
        ),
      ],
    );
  }

  Widget _buildListaProductos() {
    return Column(
      children: [
        _buildTarjetaProducto(
          imagenUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuD0ynwfKC9_TzONO23LLRj1Jav9uAfACxsaQdexFYeGoRLlUs45qmvI9a2F6X1IilQ9EVT0mf_jQT2guDbfbKHz6WchE4gNP9mwGVWwduuK6t_8SZSz1e4dpwjt-XghbgSS-Q8Vo7EVCh4zLmKfQ-ezAHHIwl9KgQUyR4s4BFwazDFP8Q1IyIAt_MhrjdY5RWzciNBxD6aEAyzs2ecYeNcmIEjXT7q-VzXWTzEG3K3ypyUv0zsj71naPA',
          categoria: 'SEDA SILVESTRE',
          titulo: 'Huipil Gala Indigo',
          precio: '\$4,200 MXN',
        ),
        const SizedBox(height: 16),
        _buildTarjetaProducto(
          imagenUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuB1yOwp-JGgjSnF4ElFbzSspoqg2vpmjJGO3Ev8dfviSscR8ziRnXd6wLnaJ5xejukemKgS7_f-SzwE0tttJKm7vb-P4kWzdqg4jjSQtL6q0H6Dl8PzhR2JTrJg-CO3VBk3M45bND9HyimuTCjCpISB3tbSr3MV8Tp7mvWkO4u1WkAuneBvkiPE_k3Tr7K7CTpP0XGMXKpqAmC-Y8cOgU3vUsL7xMlM7HKrrBTIq_byRKcQ-CK9_gxpsg',
          categoria: 'CUERO GENUINO',
          titulo: 'Bolso Herencia Mística',
          precio: '\$2,850 MXN',
        ),
        const SizedBox(height: 16),
        _buildTarjetaProducto(
          imagenUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDM6G2DEShb7gZNffF6q9YzSGQ4Tvj-6JlBYC8HLOcBvV4_iW9shVCUIkEIRyQEYIBwB1oDI9XlKCiISr5ZBIG4SAv-PInhQYXn8yytoBnHAYi3ZfAEV0fGYtllWisQszmWpxwx6yRaLWENXus95lPpqGLfxQxMexQqN631JVG0YYtgbfGV_7kUB8FpN6Ln17wvf_Oyn3bglSwO7MOxqicP3QVmXazGxJ7tx1yPJ81H7XNt1WrLQ-mtJw',
          categoria: 'ACCESORIOS',
          titulo: 'Aretes Sol de Oro',
          precio: '\$1,200 MXN',
        ),
      ],
    );
  }

  Widget _buildTarjetaProducto({
    required String imagenUrl,
    required String categoria,
    required String titulo,
    required String precio,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(24),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              imagenUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: colorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  precio,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorBugambilia,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
