import 'package:flutter/material.dart';

import '../../../models/artesano.dart';
import '../../../models/articulo.dart';
import '../../../models/resena_resumen.dart';
import '../../../services/articulo_imagen_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/artesano_service.dart';
import '../../../services/carrito_service.dart';
import '../../../services/favoritos_service.dart';
import '../../../services/resena_service.dart';
import '../../../widgets/product_grid_item.dart';
import '../../../widgets/product_image_gallery.dart';
import 'checkout_view.dart';

/// Vista de detalle de un artículo. Se navega a ella pasando el
/// `articuloId` (ej. al tocar una tarjeta en el Home):
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ProductDetailView(articuloId: articulo.id),
/// ));
/// ```
///
/// Todos los datos (artículo, artesano, imágenes, reseñas, "más obras")
/// vienen de `services/`, que hoy regresan datos mock y mañana pegarán a
/// Laravel sin tocar esta vista.
class ProductDetailView extends StatefulWidget {
  final int articuloId;

  const ProductDetailView({super.key, required this.articuloId});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final _articuloService = ArticuloService();
  final _artesanoService = ArtesanoService();
  final _imagenService = ArticuloImagenService();
  final _resenaService = ResenaService();

  bool _loading = true;
  String? _error;

  Articulo? _articulo;
  Artesano? _artesano;
  List<String> _imagenes = [];
  ResenaResumen? _resumenResenas;
  List<Articulo> _masObrasDelArtesano = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    FavoritosService.instance.addListener(_onFavoritosChanged);
  }

  @override
  void dispose() {
    FavoritosService.instance.removeListener(_onFavoritosChanged);
    super.dispose();
  }

  void _onFavoritosChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final articulo = await _articuloService.fetchArticuloPorId(
        widget.articuloId,
      );
      if (articulo == null) {
        setState(() {
          _error = 'No se encontró el artículo.';
          _loading = false;
        });
        return;
      }

      final results = await Future.wait([
        _artesanoService.fetchArtesanoPorId(articulo.artesanoId),
        _imagenService.fetchImagenesPorArticulo(articulo.id),
        _resenaService.fetchResumenPorArticulo(articulo.id),
        _articuloService.fetchArticulosPorArtesano(
          articulo.artesanoId,
          excludeId: articulo.id,
          limit: 4,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _articulo = articulo;
        _artesano = results[0] as Artesano?;
        _imagenes = results[1] as List<String>;
        _resumenResenas = results[2] as ResenaResumen;
        _masObrasDelArtesano = results[3] as List<Articulo>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el producto: $e';
        _loading = false;
      });
    }
  }

  void _abrirArticulo(int articuloId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailView(articuloId: articuloId),
      ),
    );
  }

  void _verColeccionDelArtesano() {
    // TODO: NAV -> Navigator.push a una vista "ColeccionArtesanoView"
    // filtrando por artesanoId.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aquí abriremos la colección completa')),
    );
  }

  void _comprarAhora() {
    final articulo = _articulo;
    if (articulo == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutView(items: {articulo.id: 1}),
      ),
    );
  }

  void _agregarAlCarrito() {
    final articulo = _articulo;
    if (articulo == null) return;
    CarritoService.instance.agregar(articulo.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${articulo.nombre}" agregado al carrito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de Producto',
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _articulo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Artículo no disponible',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargarDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final articulo = _articulo!;
    final esFavorito = FavoritosService.instance.esFavorito(articulo.id);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumbs(articulo),
            const SizedBox(height: 16),
            ProductImageGallery(imagenes: _imagenes),
            const SizedBox(height: 24),
            _buildProductHeader(articulo, esFavorito),
            const SizedBox(height: 24),
            if (_artesano != null) ...[
              _buildArtisanCard(_artesano!),
              const SizedBox(height: 24),
            ],
            _buildDescription(articulo),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildFeatureBadges(),
            if (_masObrasDelArtesano.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildMoreFromArtisanSection(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. Migas de pan ---
  Widget _buildBreadcrumbs(Articulo articulo) {
    return Row(
      children: [
        Text(
          'TIENDA  >  ${articulo.categoriaNombre.toUpperCase()}  >  ',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            articulo.nombre.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD81B60),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Encabezado (badge, título, estrellas, precio) ---
  Widget _buildProductHeader(Articulo articulo, bool esFavorito) {
    final resumen = _resumenResenas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD81B60).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                // TODO: API -> este campo no existe aún en la migración de
                // `articulos`; hoy se infiere de `stock` bajo. Cuando exista
                // una columna real (ej. `es_pieza_unica`), usar esa.
                articulo.stock <= 3 ? 'Pieza Única' : 'Disponible',
                style: const TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => FavoritosService.instance.toggle(articulo.id),
              child: Icon(
                esFavorito ? Icons.favorite : Icons.favorite_border,
                color: esFavorito ? Colors.pink : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          articulo.nombre,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        if (resumen != null)
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  final estrellaLlena = index < resumen.promedio.round();
                  return Icon(
                    estrellaLlena ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '(${resumen.total} reseñas)',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD81B60),
                  height: 1.0,
                ),
                children: [
                  TextSpan(text: '\$${articulo.precioFinalEntero}'),
                  TextSpan(
                    text: '.${articulo.precioFinalDecimal}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            if (articulo.tieneDescuento)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12),
                child: Text(
                  '\$${articulo.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black45,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- 3. Tarjeta del artesano ---
  Widget _buildArtisanCard(Artesano artesano) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEef4fb),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[400],
            // TODO: API -> backgroundImage: NetworkImage(artesano.avatarUrl)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artesano.titulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD81B60),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  artesano.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  artesano.region,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (artesano.verificado)
            const Icon(
              Icons.verified_outlined,
              color: Color(0xFFD81B60),
              size: 28,
            ),
        ],
      ),
    );
  }

  // --- 4. Descripción y detalles del artículo ---
  Widget _buildDescription(Articulo articulo) {
    final detalles = <String, String>{
      if (articulo.talla.isNotEmpty && articulo.talla != 'N/A')
        'Talla': articulo.talla,
      if (articulo.color.isNotEmpty && articulo.color != 'N/A')
        'Color': articulo.color,
      if (articulo.tela.isNotEmpty && articulo.tela != 'N/A')
        'Tela': articulo.tela,
      if (articulo.bordado.isNotEmpty && articulo.bordado != 'N/A')
        'Bordado': articulo.bordado,
      'Región': articulo.region,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DESCRIPCIÓN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          articulo.descripcion?.isNotEmpty == true
              ? articulo.descripcion!
              : 'Esta pieza fue elaborada de forma artesanal, conservando '
                    'las técnicas tradicionales de la región.',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        if (detalles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detalles.entries
                .map((e) => _buildDetailChip(e.key, e.value))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: $valor',
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }

  // --- 5. Botones de acción ---
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ElevatedButton(
            onPressed: _comprarAhora,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Comprar ahora',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: OutlinedButton.icon(
            onPressed: _agregarAlCarrito,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFFD81B60),
              size: 20,
            ),
            label: const Text(
              'Agregar',
              style: TextStyle(
                color: Color(0xFFD81B60),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 6. Badges de envío y garantía ---
  // TODO: API -> hoy son estáticos; cuando exista una tabla de políticas
  // por tienda, se pueden condicionar (ej. ocultar "Envío Gratis" si la
  // tienda no lo ofrece).
  Widget _buildFeatureBadges() {
    return Row(
      children: [
        Expanded(
          child: _featureBadge(
            icon: Icons.local_shipping_outlined,
            titulo: 'Envío Gratis',
            subtitulo: 'A todo México y USA',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _featureBadge(
            icon: Icons.workspace_premium_outlined,
            titulo: 'Garantía Ixé',
            subtitulo: 'Certificado de Autenticidad',
          ),
        ),
      ],
    );
  }

  Widget _featureBadge({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD81B60)),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- 7. Más obras del artesano ---
  Widget _buildMoreFromArtisanSection() {
    final nombreArtesano = _artesano?.nombre.split(' ').first ?? '';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Más obras de\n$nombreArtesano',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Curaduría especial de piezas únicas',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _verColeccionDelArtesano,
              child: const Row(
                children: [
                  Text(
                    'Ver\ncolección',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD81B60),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Color(0xFFD81B60), size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
          children: _masObrasDelArtesano.map((a) {
            return ProductGridItem(
              articulo: a,
              isFavorite: FavoritosService.instance.esFavorito(a.id),
              onTap: () => _abrirArticulo(a.id),
              onFavoriteToggle: () => FavoritosService.instance.toggle(a.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
