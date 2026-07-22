import 'package:flutter/material.dart';

import '../../../models/artesano.dart';
import '../../../models/articulo.dart';
import '../../../models/resena.dart';
import '../../../models/resena_resumen.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_imagen_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/artesano_service.dart';
import '../../../services/carrito_service.dart';
import '../../../services/favoritos_service.dart';
import '../../../services/resena_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/favorite_heart_button.dart';
import '../../../widgets/product_grid_item.dart';
import '../../../widgets/product_image_gallery.dart';
import 'checkout_view.dart';
import 'public_catalog_entity_view.dart';

/// Detalle de artículo (API real: artículo, imágenes, reseñas).
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
  final _ventaService = VentaService();

  bool _loading = true;
  String? _error;

  Articulo? _articulo;
  Artesano? _artesano;
  List<String> _imagenes = [];
  ResenaResumen? _resumenResenas;
  List<Resena> _resenas = [];
  List<Articulo> _masObrasDelArtesano = [];
  bool _loggedIn = false;
  /// Rol vendedor: no carrito, no compra, no reseñas (reglas de catálogo).
  bool _esVendedor = false;
  /// Compra **entregada** real del usuario que incluye este artículo.
  bool _yaAdquirido = false;
  /// Compra en curso (sin entrega final) del mismo artículo.
  bool _compraEnProceso = false;

  final _comentarioCtrl = TextEditingController();
  int _nuevaCalificacion = 5;
  bool _enviandoResena = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    FavoritosService.instance.addListener(_onFavoritosChanged);
  }

  @override
  void dispose() {
    FavoritosService.instance.removeListener(_onFavoritosChanged);
    _comentarioCtrl.dispose();
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

      final api = ApiService();
      final token = await api.getToken();
      // Rol desde sesión; si falta, una sola consulta a /me.
      var esVendedor = await api.isVendedor();
      if (token != null && (await api.getRole()).isEmpty) {
        final me = await api.fetchMe();
        if (me['success'] == true) {
          esVendedor = ApiService.isVendedorRoleName(
            me['role']?.toString() ??
                ApiService.roleFromUserMap(me['user']),
          );
        }
      }

      final results = await Future.wait([
        _artesanoService.fetchArtesanoPorId(articulo.artesanoId),
        _imagenService.fetchImagenesPorArticulo(articulo.id),
        _resenaService.fetchPorArticulo(articulo.id),
        _articuloService.fetchArticulosPorArtesano(
          articulo.artesanoId,
          excludeId: articulo.id,
          limit: 4,
        ),
      ]);

      // Historial del artículo (no solo la última compra):
      // adquirido <=> existe >=1 compra entregada del usuario.
      // Una cancelada posterior NO oculta el aviso.
      var yaAdquirido = false;
      var compraEnProceso = false;
      if (token != null && !esVendedor) {
        try {
          final estado = await _ventaService.fetchEstadoAdquisicionArticulo(
            articulo.id,
          );
          yaAdquirido = estado.adquirido;
          compraEnProceso = !yaAdquirido && estado.enProceso;
        } catch (_) {
          yaAdquirido = false;
          compraEnProceso = false;
        }
      }

      final resenas = results[2] as List<Resena>;
      ResenaResumen resumen;
      if (resenas.isEmpty) {
        resumen = const ResenaResumen(promedio: 0, total: 0);
      } else {
        final sum = resenas.fold<int>(0, (a, r) => a + r.calificacion);
        resumen = ResenaResumen(
          promedio: double.parse((sum / resenas.length).toStringAsFixed(1)),
          total: resenas.length,
        );
      }

      if (!mounted) return;
      setState(() {
        _articulo = articulo;
        _artesano = results[0] as Artesano?;
        _imagenes = results[1] as List<String>;
        _resenas = resenas;
        _resumenResenas = resumen;
        _masObrasDelArtesano = results[3] as List<Articulo>;
        _loggedIn = token != null;
        _esVendedor = esVendedor;
        _yaAdquirido = yaAdquirido;
        _compraEnProceso = compraEnProceso;
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

  void _abrirArtesano() {
    final a = _articulo;
    if (a == null || a.artesanoId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicCatalogEntityView(
          type: PublicCatalogEntityType.artesano,
          entityId: a.artesanoId,
          fallbackTitle: a.artesanoNombre.isNotEmpty
              ? a.artesanoNombre
              : _artesano?.nombre,
        ),
      ),
    );
  }

  void _abrirTienda() {
    final a = _articulo;
    if (a == null || a.tiendaId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicCatalogEntityView(
          type: PublicCatalogEntityType.tienda,
          entityId: a.tiendaId,
          fallbackTitle: a.tiendaNombre,
        ),
      ),
    );
  }

  void _avisarAccionVendedor() {
    AppUi.showAccionNoPermitidaVendedor(context);
  }

  Future<void> _enviarResena() async {
    final articulo = _articulo;
    if (articulo == null || _enviandoResena) return;

    if (_esVendedor) {
      _avisarAccionVendedor();
      return;
    }

    setState(() => _enviandoResena = true);
    final result = await _resenaService.crearResena(
      articuloId: articulo.id,
      calificacion: _nuevaCalificacion,
      comentario: _comentarioCtrl.text,
    );
    if (!mounted) return;
    setState(() => _enviandoResena = false);

    if (result['success'] == true) {
      _comentarioCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña publicada')),
      );
      await _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Error al publicar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _puedeComprar {
    final a = _articulo;
    if (a == null) return false;
    return a.disponible && a.stock > 0;
  }

  /// Apariencia habilitada: stock OK y no es cuenta vendedor.
  bool get _accionesCompraHabilitadas => _puedeComprar && !_esVendedor;

  void _comprarAhora() {
    final articulo = _articulo;
    if (articulo == null) return;
    if (_esVendedor) {
      _avisarAccionVendedor();
      return;
    }
    if (!_puedeComprar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto no está disponible o sin stock.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutView(items: {articulo.id: 1}),
      ),
    );
  }

  Future<void> _agregarAlCarrito() async {
    final articulo = _articulo;
    if (articulo == null) return;
    if (_esVendedor) {
      _avisarAccionVendedor();
      return;
    }
    if (!_puedeComprar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede agregar: sin stock o no disponible.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await CarritoService.instance.agregar(articulo.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CarritoService.instance.usaReservaRemota
                ? '“${articulo.nombre}” reservado en tu carrito (5 min).'
                : '“${articulo.nombre}” agregado al carrito',
          ),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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
      return const AppLoadingView();
    }

    if (_error != null || _articulo == null) {
      return AppErrorView(
        message: _error ?? 'Artículo no disponible',
        onRetry: _cargarDatos,
      );
    }

    final articulo = _articulo!;

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
            _buildProductHeader(articulo),
            const SizedBox(height: 24),
            if (_artesano != null) ...[
              InkWell(
                onTap: _abrirArtesano,
                borderRadius: BorderRadius.circular(16),
                child: _buildArtisanCard(_artesano!),
              ),
              const SizedBox(height: 12),
            ],
            if (articulo.tiendaId > 0) ...[
              _buildStoreChip(articulo),
              const SizedBox(height: 24),
            ],
            _buildDescription(articulo),
            const SizedBox(height: 24),
            // Avisos solo con estado real de compra (nunca cancelada).
            if (_yaAdquirido) ...[
              _buildCompraBanner(
                texto: 'Ya adquiriste esta prenda',
                icon: Icons.check_circle_outline,
                bg: const Color(0xFFE8F5E9),
                border: const Color(0xFFC8E6C9),
                fg: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 12),
            ] else if (_compraEnProceso) ...[
              _buildCompraBanner(
                texto: 'Compra en proceso',
                icon: Icons.hourglass_top_outlined,
                bg: const Color(0xFFFFF3E0),
                border: const Color(0xFFFFCC80),
                fg: const Color(0xFFE65100),
              ),
              const SizedBox(height: 12),
            ],
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildFeatureBadges(),
            const SizedBox(height: 28),
            _buildResenasSection(),
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

  Widget _buildStoreChip(Articulo articulo) {
    final name = articulo.tiendaNombre.isNotEmpty
        ? articulo.tiendaNombre
        : 'Ver tienda';
    return InkWell(
      onTap: _abrirTienda,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: Color(0xFFD81B60)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const Text(
              'Ver tienda',
              style: TextStyle(
                color: Color(0xFFD81B60),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD81B60)),
          ],
        ),
      ),
    );
  }

  Widget _buildResenasSection() {
    final resumen = _resumenResenas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RESEÑAS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (resumen != null && resumen.total > 0)
          Text(
            '${resumen.promedio} ★ · ${resumen.total} reseña(s)',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          )
        else
          const Text(
            'Aún no hay reseñas para esta pieza.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        const SizedBox(height: 12),
        ..._resenas.take(10).map((r) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${r.calificacion}/5',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.autorNombre?.isNotEmpty == true
                            ? r.autorNombre!
                            : 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (r.comentario.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(r.comentario, style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_esVendedor)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Las cuentas vendedor no pueden publicar reseñas ni calificar productos.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
          )
        else if (_loggedIn)
          _buildFormResena()
        else
          const Text(
            'Inicia sesión para dejar una reseña.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
      ],
    );
  }

  Widget _buildFormResena() {
    // Defensa: no montar controles de calificación si es vendedor.
    if (_esVendedor) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escribe tu reseña',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  if (_esVendedor) {
                    _avisarAccionVendedor();
                    return;
                  }
                  setState(() => _nuevaCalificacion = star);
                },
                icon: Icon(
                  star <= _nuevaCalificacion ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            enabled: !_esVendedor,
            decoration: InputDecoration(
              hintText: 'Comentario (opcional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _enviandoResena
                  ? null
                  : () {
                      if (_esVendedor) {
                        _avisarAccionVendedor();
                        return;
                      }
                      _enviarResena();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(_enviandoResena ? 'Enviando…' : 'Publicar'),
            ),
          ),
        ],
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

  /// Aviso discreto según estado real de compra del usuario.
  Widget _buildCompraBanner({
    required String texto,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color fg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Encabezado (badge, título, estrellas, precio) ---
  Widget _buildProductHeader(Articulo articulo) {
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
            FavoriteHeartButton(
              articuloId: articulo.id,
              iconSize: 24,
              radius: 18,
              activeColor: Colors.pink,
              inactiveColor: Colors.black54,
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
    final looksEnabled = _accionesCompraHabilitadas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_esVendedor)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Las cuentas vendedor no pueden agregar al carrito ni comprar.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
          )
        else if (!_puedeComprar)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Producto no disponible o sin stock. No se puede comprar por ahora.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: ElevatedButton(
                // Siempre con handler: vendedor recibe SnackBar; sin stock queda deshabilitado.
                onPressed: _esVendedor
                    ? _comprarAhora
                    : (_puedeComprar ? _comprarAhora : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: looksEnabled
                      ? const Color(0xFFD81B60)
                      : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
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
                onPressed: _esVendedor
                    ? _agregarAlCarrito
                    : (_puedeComprar ? _agregarAlCarrito : null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: looksEnabled
                        ? const Color(0xFFD81B60)
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: looksEnabled ? const Color(0xFFD81B60) : Colors.grey,
                  size: 20,
                ),
                label: Text(
                  'Agregar',
                  style: TextStyle(
                    color: looksEnabled ? const Color(0xFFD81B60) : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 6. Info honesta (sin promesas de envío inventadas) ---
  Widget _buildFeatureBadges() {
    final a = _articulo;
    final stockLabel = a == null
        ? '—'
        : (a.stock <= 0
            ? 'Sin stock'
            : 'Stock: ${a.stock}');
    final dispLabel = a == null
        ? '—'
        : (a.disponible ? 'Publicado en catálogo' : 'No disponible');

    return Row(
      children: [
        Expanded(
          child: _featureBadge(
            icon: Icons.inventory_2_outlined,
            titulo: stockLabel,
            subtitulo: 'Disponibilidad',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _featureBadge(
            icon: Icons.visibility_outlined,
            titulo: dispLabel,
            subtitulo: 'Envíos próximamente',
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
    final nombreArtesano = _artesano?.nombre.split(' ').first ??
        _articulo?.artesanoNombre.split(' ').first ??
        '';

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
              onTap: _abrirArtesano,
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
