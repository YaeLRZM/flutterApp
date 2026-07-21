import 'package:flutter/material.dart';

import '../../../models/categoria.dart';
import '../../../services/articulo_service.dart';
import '../../../services/categoria_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/category_collection_card.dart';
import 'category_detail_view.dart';

/// Vista de Colecciones: categorías reales vía API.
///
/// Se llega aquí de dos formas:
///  - Como pestaña del bottom nav (`UserLayout`).
///  - Empujada con `Navigator.push` desde los botones "Ver más" /
///    "Ver categorías" del Home.
/// Por eso el encabezado no incluye una flecha de regreso fija: solo
/// aparece si sí se puede hacer pop (es decir, si se llegó navegando).
class CollectionsView extends StatefulWidget {
  const CollectionsView({super.key});

  @override
  State<CollectionsView> createState() => _CollectionsViewState();
}

enum _FiltroColecciones { todas, destacadas }

class _CollectionsViewState extends State<CollectionsView> {
  final _categoriaService = CategoriaService();
  final _articuloService = ArticuloService();

  bool _loading = true;
  String? _error;

  List<Categoria> _categorias = [];
  Map<int, int> _conteoPorCategoria = {};
  _FiltroColecciones _filtro = _FiltroColecciones.todas;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categorias = await _categoriaService.fetchCategoriasColecciones();
      final conteo = await _articuloService.fetchConteoArticulosPorCategoria();

      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _conteoPorCategoria = conteo;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las colecciones: $e';
        _loading = false;
      });
    }
  }

  List<Categoria> get _categoriasFiltradas {
    if (_filtro == _FiltroColecciones.todas) return _categorias;
    return _categorias.where((c) => c.destacada).toList();
  }

  void _abrirCategoria(Categoria categoria) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailView(categoria: categoria),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F5F2),
      child: SafeArea(bottom: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargarDatos);
    }

    final categorias = _categoriasFiltradas;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFiltroChips(),
          const SizedBox(height: 20),
          if (categorias.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No hay categorías destacadas por ahora.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            for (final categoria in categorias) ...[
              CategoryCollectionCard(
                categoria: categoria,
                totalArticulos: _conteoPorCategoria[categoria.id] ?? 0,
                isPremium: categoria.destacada,
                onTap: () => _abrirCategoria(categoria),
              ),
              const SizedBox(height: 16),
            ],
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  /// Encabezado con título en degradado, subtítulo y una pastilla con el
  /// total de categorías/artículos disponibles.
  Widget _buildHeader() {
    final totalArticulos = _conteoPorCategoria.values.fold<int>(
      0,
      (a, b) => a + b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFD81B60), Color(0xFF8E24AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Colecciones\nIxé',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: Colors.white, // El ShaderMask pinta encima de esto.
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Descubre la esencia de Oaxaca a través de nuestras categorías '
          'curadas por maestros artesanos.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _statPill(
              icon: Icons.category_outlined,
              texto: '${_categorias.length} categorías',
            ),
            const SizedBox(width: 8),
            _statPill(
              icon: Icons.shopping_bag_outlined,
              texto: '+$totalArticulos artículos',
            ),
          ],
        ),
      ],
    );
  }

  Widget _statPill({required IconData icon, required String texto}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD81B60).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD81B60)),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD81B60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChips() {
    Widget chip(String texto, _FiltroColecciones valor) {
      final bool selected = _filtro == valor;
      return GestureDetector(
        onTap: () => setState(() => _filtro = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD81B60) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Todas', _FiltroColecciones.todas),
        const SizedBox(width: 8),
        chip('Destacadas', _FiltroColecciones.destacadas),
      ],
    );
  }
}
