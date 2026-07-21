import 'package:flutter/material.dart';

import '../../../config/data_config.dart';
import '../../../models/artesano.dart';
import '../../../models/articulo.dart';
import '../../../models/categoria.dart';
import '../../../models/resena_resumen.dart';
import '../../../services/articulo_service.dart';
import '../../../services/artesano_service.dart';
import '../../../services/favoritos_service.dart';
import '../../../services/resena_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/category_product_card.dart';
import '../../../widgets/selectable_filter_chip.dart';
import 'product_detail_view.dart';

enum _OrdenPrecio { relevancia, menor, mayor }

/// Vista que muestra los artículos de una categoría (hasta
/// `kMaxArticulosCategoria`), con filtros de precio/técnica/artesano.
///
/// Se navega a ella con `Navigator.push` desde `CollectionsView` al tocar
/// una tarjeta de categoría — es un "drill-down" legítimo (como
/// `ProductDetailView`), por eso sí tiene su propia flecha de regreso:
/// no es una pestaña del bottom bar, es una sub-pantalla de Colecciones.
class CategoryDetailView extends StatefulWidget {
  final Categoria categoria;

  const CategoryDetailView({super.key, required this.categoria});

  @override
  State<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<CategoryDetailView> {
  final _articuloService = ArticuloService();
  final _artesanoService = ArtesanoService();
  final _resenaService = ResenaService();

  bool _loading = true;
  String? _error;

  List<Articulo> _articulos = [];
  Map<int, Artesano> _artesanosPorId = {};
  Map<int, ResenaResumen> _resenasPorArticulo = {};

  _OrdenPrecio _orden = _OrdenPrecio.relevancia;
  String? _tecnicaSeleccionada;
  String? _artesanoSeleccionado;

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
      final articulos = await _articuloService.fetchArticulosPorCategoria(
        widget.categoria.id,
        limit: kMaxArticulosCategoria,
      );
      final artesanos = await _artesanoService.fetchTodos();

      final resenasEntries = await Future.wait(
        articulos.map((a) async {
          final resumen = await _resenaService.fetchResumenPorArticulo(a.id);
          return MapEntry(a.id, resumen);
        }),
      );

      if (!mounted) return;
      setState(() {
        _articulos = articulos;
        _artesanosPorId = {for (final a in artesanos) a.id: a};
        _resenasPorArticulo = Map.fromEntries(resenasEntries);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los artículos: $e';
        _loading = false;
      });
    }
  }

  String _nombreArtesano(int artesanoId) {
    return _artesanosPorId[artesanoId]?.nombre ?? 'Artesano';
  }

  List<String> get _opcionesTecnica {
    final set = _articulos
        .map((a) => a.bordado)
        .where((t) => t.isNotEmpty && t != 'N/A')
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  List<String> get _opcionesArtesano {
    final set = _articulos
        .map((a) => _nombreArtesano(a.artesanoId))
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  List<Articulo> get _articulosFiltrados {
    var lista = _articulos.where((a) {
      final pasaTecnica =
          _tecnicaSeleccionada == null || a.bordado == _tecnicaSeleccionada;
      final pasaArtesano =
          _artesanoSeleccionado == null ||
          _nombreArtesano(a.artesanoId) == _artesanoSeleccionado;
      return pasaTecnica && pasaArtesano;
    }).toList();

    switch (_orden) {
      case _OrdenPrecio.menor:
        lista.sort((a, b) => a.precioFinal.compareTo(b.precioFinal));
        break;
      case _OrdenPrecio.mayor:
        lista.sort((a, b) => b.precioFinal.compareTo(a.precioFinal));
        break;
      case _OrdenPrecio.relevancia:
        break;
    }
    return lista;
  }

  void _abrirArticulo(int articuloId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailView(articuloId: articuloId),
      ),
    );
  }

  void _verOtrasCategorias() {
    // Esta vista se llegó empujando desde CollectionsView, así que
    // "Ver otras categorías" es simplemente regresar a esa pantalla.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargarDatos);
    }

    final articulos = _articulosFiltrados;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 8),
          Text(
            '${articulos.length} publicaciones',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (articulos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'No hay artículos con esos filtros.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.58,
              children: articulos.map((articulo) {
                final resumen = _resenasPorArticulo[articulo.id];
                return CategoryProductCard(
                  articulo: articulo,
                  nombreArtesano: _nombreArtesano(articulo.artesanoId),
                  promedioResenas: resumen?.promedio ?? 0,
                  totalResenas: resumen?.total ?? 0,
                  isFavorite: FavoritosService.instance.esFavorito(articulo.id),
                  onTap: () => _abrirArticulo(articulo.id),
                  onFavoriteToggle: () =>
                      FavoritosService.instance.toggle(articulo.id),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          _buildVerOtrasCategoriasButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- 1. Encabezado ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.categoria.nombre,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.categoria.descripcion ??
              'Piezas artesanales curadas por maestros de la región.',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // --- 2. Filtros ---
  Widget _buildFilters() {
    return Row(
      children: [
        SelectableFilterChip(
          label: 'Precio',
          isActive: _orden != _OrdenPrecio.relevancia,
          seleccionActual: switch (_orden) {
            _OrdenPrecio.relevancia => null,
            _OrdenPrecio.menor => 'Menor precio',
            _OrdenPrecio.mayor => 'Mayor precio',
          },
          opciones: const ['Menor precio', 'Mayor precio'],
          onSeleccionar: (valor) {
            setState(() {
              _orden = switch (valor) {
                'Menor precio' => _OrdenPrecio.menor,
                'Mayor precio' => _OrdenPrecio.mayor,
                _ => _OrdenPrecio.relevancia,
              };
            });
          },
        ),
        const SizedBox(width: 8),
        SelectableFilterChip(
          label: 'Técnica',
          seleccionActual: _tecnicaSeleccionada,
          opciones: _opcionesTecnica,
          onSeleccionar: (valor) =>
              setState(() => _tecnicaSeleccionada = valor),
        ),
        const SizedBox(width: 8),
        SelectableFilterChip(
          label: 'Artesano',
          seleccionActual: _artesanoSeleccionado,
          opciones: _opcionesArtesano,
          onSeleccionar: (valor) =>
              setState(() => _artesanoSeleccionado = valor),
        ),
      ],
    );
  }

  // --- 3. Botón final ---
  Widget _buildVerOtrasCategoriasButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _verOtrasCategorias,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFD81B60)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.arrow_back, color: Color(0xFFD81B60)),
        label: const Text(
          'Ver otras categorías',
          style: TextStyle(
            color: Color(0xFFD81B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
