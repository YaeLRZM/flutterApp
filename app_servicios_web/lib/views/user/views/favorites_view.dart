import 'package:flutter/material.dart';

import '../../../models/artesano.dart';
import '../../../models/articulo.dart';
import '../../../services/articulo_service.dart';
import '../../../services/artesano_service.dart';
import '../../../services/carrito_service.dart';
import '../../../services/favoritos_service.dart';
import 'product_detail_view.dart';

/// Vista de Favoritos. Los artículos guardados viven en
/// `FavoritosService` (compartido con Home, Detalle y Categorías); esta
/// vista solo pide, con esos ids, los artículos completos.
///
/// Al tocar una tarjeta se reutiliza `ProductDetailView` (no se crea una
/// vista de detalle nueva).
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  final _articuloService = ArticuloService();
  final _artesanoService = ArtesanoService();

  bool _loading = true;
  String? _error;

  List<Articulo> _articulos = [];
  Map<int, Artesano> _artesanosPorId = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // Si el usuario quita/agrega un favorito desde Home, Detalle o
    // Categorías, esta vista se refresca sola.
    FavoritosService.instance.addListener(_onFavoritosChanged);
  }

  @override
  void dispose() {
    FavoritosService.instance.removeListener(_onFavoritosChanged);
    super.dispose();
  }

  void _onFavoritosChanged() {
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ids = FavoritosService.instance.ids;
      final articulos = await _articuloService.fetchArticulosPorIds(ids);
      final artesanos = await _artesanoService.fetchTodos();

      if (!mounted) return;
      setState(() {
        _articulos = articulos;
        _artesanosPorId = {for (final a in artesanos) a.id: a};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus favoritos: $e';
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

  void _agregarTodoAlCarrito() {
    for (final articulo in _articulos) {
      CarritoService.instance.agregar(articulo.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_articulos.length} artículo(s) agregados al carrito'),
      ),
    );
  }

  /// Deriva un estado de disponibilidad a partir del `stock`.
  /// TODO: API -> si el backend agrega un estado explícito
  /// (ej. `disponibilidad` como columna calculada), usar ese en vez de
  /// inferirlo aquí.
  (String, Color) _estadoDisponibilidad(Articulo articulo) {
    if (articulo.stock <= 0) return ('Agotado', Colors.red);
    if (articulo.stock <= 5) return ('Últimas piezas', Colors.orange);
    return ('En stock', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF8F5F2), child: _buildBody());
  }

  Widget _buildBody() {
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

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          _buildHeader(),
          if (_articulos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAddAllButton(),
          ],
          const SizedBox(height: 24),
          if (_articulos.isEmpty)
            _buildEmptyState()
          else
            for (final articulo in _articulos) ...[
              _buildSavedItemCard(articulo),
              const SizedBox(height: 20),
            ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- Encabezado ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TU SELECCIÓN PERSONAL',
          style: TextStyle(
            color: Color(0xFFD81B60),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Guardados (${_articulos.length})',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Aún no has guardado ningún artículo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca el corazón ♡ en cualquier artículo para guardarlo aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- Botón de Añadir Todo ---
  Widget _buildAddAllButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: _agregarTodoAlCarrito,
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
  Widget _buildSavedItemCard(Articulo articulo) {
    final (estadoTexto, estadoColor) = _estadoDisponibilidad(articulo);
    final nombreArtesano =
        _artesanosPorId[articulo.artesanoId]?.nombre ?? 'Artesano';

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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirArticulo(articulo.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  // TODO: API -> Image.network(articulo.imagenUrl)
                  color: Colors.grey[300],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => FavoritosService.instance.toggle(articulo.id),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(
                        Icons.favorite,
                        color: Color(0xFFD81B60),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          articulo.nombre,
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
                        '\$${articulo.precioFinalEntero}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD81B60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Artesano: $nombreArtesano',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: estadoColor),
                      const SizedBox(width: 6),
                      Text(
                        estadoTexto,
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
      ),
    );
  }
}
