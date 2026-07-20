import 'package:flutter/material.dart';

import '../../../config/data_config.dart';
import '../../../models/articulo.dart';
import '../../../models/categoria.dart';
import '../../../models/cupon.dart';
import '../../../services/articulo_service.dart';
import '../../../services/categoria_service.dart';
import '../../../services/cupon_service.dart';
import '../../../services/favoritos_service.dart';
import '../../../widgets/category_filter_bar.dart';
import '../../../widgets/flash_sales_box.dart';
import '../../../widgets/product_card_large.dart';
import '../../../widgets/product_card_small.dart';
import '../../../widgets/promo_discount_banner.dart';
import 'product_detail_view.dart';

/// Muestra el feed principal. Recibe [onIrAColecciones] para avisarle a
/// `UserLayout` que debe cambiar a la pestaña de Colecciones del bottom
/// bar — esta vista NO navega por su cuenta con `Navigator.push`, porque
/// eso abriría una pantalla nueva encima (sin el bottom bar ni el menú),
/// en vez de simplemente cambiar de pestaña como el resto de la app.
class HomeView extends StatefulWidget {
  final VoidCallback onIrAColecciones;

  const HomeView({super.key, required this.onIrAColecciones});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _articuloService = ArticuloService();
  final _categoriaService = CategoriaService();
  final _cuponService = CuponService();

  bool _loading = true;
  String? _error;

  List<Categoria> _categorias = [];
  List<Articulo> _ofertasRelampago = [];
  List<Articulo> _feed = [];

  // TODO: API -> se llenará al construir las tarjetas, buscando el cupón
  // vigente de cada `tiendaId` distinto presente en `_feed`.
  final Map<int, Cupon?> _cuponesPorTienda = {};

  /// 0 = agregador "Todo" (cliente); ids reales vienen del backend.
  int _selectedCategoriaId = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // El corazón de las tarjetas se sincroniza con ProductDetailView y
    // cualquier otra vista a través del mismo servicio.
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
      // Catálogo principal: categorías + artículos desde Laravel.
      // Cupones pueden seguir mock (módulo secundario).
      final categorias = await _categoriaService.fetchCategorias();
      final feed = await _articuloService.fetchArticulos(
        limit: kMaxArticulosHome,
      );
      // Ofertas: solo si la API trae descuento; si no, caja vacía (no mock).
      final ofertas = await _articuloService.fetchOfertasRelampago(limit: 2);

      final tiendaIds = feed.map((a) => a.tiendaId).toSet();
      for (final tiendaId in tiendaIds) {
        try {
          _cuponesPorTienda[tiendaId] = await _cuponService
              .fetchCuponVigentePorTienda(tiendaId);
        } catch (_) {
          _cuponesPorTienda[tiendaId] = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _ofertasRelampago = ofertas;
        _feed = feed;
        _selectedCategoriaId = 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos: $e';
        _loading = false;
      });
    }
  }

  List<Articulo> get _articulosFiltrados {
    // 0 o categoría esGeneral = "Todo"
    final selected = _categorias.where((c) => c.id == _selectedCategoriaId);
    if (_selectedCategoriaId == 0 ||
        (selected.isNotEmpty && selected.first.esGeneral)) {
      return _feed;
    }
    return _feed.where((a) => a.categoriaId == _selectedCategoriaId).toList();
  }

  void _abrirArticulo(int articuloId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailView(articuloId: articuloId),
      ),
    );
  }

  void _irACategorias() {
    widget.onIrAColecciones();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
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

    final articulos = _articulosFiltrados;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            CategoryFilterBar(
              categorias: _categorias,
              selectedCategoriaId: _selectedCategoriaId,
              onSelect: (id) => setState(() => _selectedCategoriaId = id),
              onVerMas: _irACategorias,
            ),
            const SizedBox(height: 16),
            FlashSalesBox(articulos: _ofertasRelampago),
            const SizedBox(height: 16),
            ..._buildFeedBlocks(articulos),
          ],
        ),
      ),
    );
  }

  /// Construye el feed en bloques repetidos de:
  /// [2 tarjetas grandes] + [1 tarjeta chica] + [banner promo con 2 chicas]
  /// hasta agotar los artículos (máx. `kMaxArticulosHome` ya viene acotado
  /// desde el service). Al terminar, se agrega el botón "Ver categorías".
  List<Widget> _buildFeedBlocks(List<Articulo> articulos) {
    final widgets = <Widget>[];
    int i = 0;

    while (i < articulos.length) {
      final bloque = articulos.skip(i).take(5).toList();
      if (bloque.isEmpty) break;

      for (final articulo in bloque.take(2)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductCardLarge(
              articulo: articulo,
              cupon: _cuponesPorTienda[articulo.tiendaId],
              isFavorite: FavoritosService.instance.esFavorito(articulo.id),
              onFavoriteToggle: () =>
                  FavoritosService.instance.toggle(articulo.id),
              onTap: () => _abrirArticulo(articulo.id),
            ),
          ),
        );
      }

      if (bloque.length > 2) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductCardSmall(
              articulo: bloque[2],
              onTap: () => _abrirArticulo(bloque[2].id),
            ),
          ),
        );
      }

      if (bloque.length > 3) {
        final paraPromo = bloque.skip(3).take(2).toList();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PromoDiscountBanner(
              articulos: paraPromo,
              onArticuloTap: (a) => _abrirArticulo(a.id),
            ),
          ),
        );
      }

      i += 5;
    }

    widgets.add(_buildVerCategoriasButton());
    return widgets;
  }

  Widget _buildVerCategoriasButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _irACategorias,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFFD81B60)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.grid_view_rounded, color: Color(0xFFD81B60)),
          label: const Text(
            'Ver categorías',
            style: TextStyle(
              color: Color(0xFFD81B60),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
