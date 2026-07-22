import 'package:flutter/material.dart';

import '../../../models/articulo.dart';
import '../../../models/artesano.dart';
import '../../../models/tienda.dart';
import '../../../services/articulo_service.dart';
import '../../../services/artesano_service.dart';
import '../../../services/tienda_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/product_card_small.dart';
import '../../../widgets/product_image.dart';
import 'product_detail_view.dart';

enum PublicCatalogEntityType { artesano, tienda }

/// Pantalla pública: artesano o tienda con cabecera cuidada + piezas.
///
/// Solo muestra datos reales del API y resúmenes derivados de las
/// prendas publicadas (regiones, materiales, categorías). No inventa
/// biografías ni ubicaciones.
class PublicCatalogEntityView extends StatefulWidget {
  final PublicCatalogEntityType type;
  final int entityId;
  final String? fallbackTitle;

  const PublicCatalogEntityView({
    super.key,
    required this.type,
    required this.entityId,
    this.fallbackTitle,
  });

  @override
  State<PublicCatalogEntityView> createState() =>
      _PublicCatalogEntityViewState();
}

class _PublicCatalogEntityViewState extends State<PublicCatalogEntityView> {
  static const Color _bg = Color(0xFFF8F5F2);
  static const Color _primary = Color(0xFFD81B60);
  static const Color _softPink = Color(0xFFF3E5E8);
  static const Color _card = Colors.white;

  final _articuloService = ArticuloService();
  final _artesanoService = ArtesanoService();
  final _tiendaService = TiendaService();

  bool _loading = true;
  String? _error;
  Artesano? _artesano;
  Tienda? _tienda;
  List<Articulo> _articulos = [];

  bool get _esArtesano => widget.type == PublicCatalogEntityType.artesano;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      late final List<Articulo> articulos;
      if (_esArtesano) {
        final a = await _artesanoService.fetchArtesanoPorId(widget.entityId);
        articulos = await _articuloService.fetchArticulosPorArtesano(
          widget.entityId,
          limit: 50,
        );
        if (!mounted) return;
        setState(() {
          _artesano = a;
          _tienda = null;
          _articulos = articulos;
          _loading = false;
        });
      } else {
        final t = await _tiendaService.fetchTiendaPorId(widget.entityId);
        articulos = await _articuloService.fetchArticulosPorTienda(
          widget.entityId,
          limit: 50,
        );
        if (!mounted) return;
        setState(() {
          _tienda = t;
          _artesano = null;
          _articulos = articulos;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la información. Intenta de nuevo.';
        _loading = false;
      });
    }
  }

  String get _title {
    if (_esArtesano) {
      final n = _artesano?.nombre.trim() ?? '';
      if (n.isNotEmpty) return n;
      return widget.fallbackTitle?.trim().isNotEmpty == true
          ? widget.fallbackTitle!.trim()
          : 'Artesano';
    }
    final n = _tienda?.nombre.trim() ?? '';
    if (n.isNotEmpty) return n;
    return widget.fallbackTitle?.trim().isNotEmpty == true
        ? widget.fallbackTitle!.trim()
        : 'Tienda';
  }

  /// Imágenes de prendas para portada / avatar (datos reales del catálogo).
  List<String> get _productImageUrls {
    final urls = <String>[];
    for (final a in _articulos) {
      if (ProductImage.isUsable(a.imagenUrl)) {
        urls.add(a.imagenUrl);
      }
      if (urls.length >= 4) break;
    }
    return urls;
  }

  String? get _coverUrl {
    if (!_esArtesano && _tienda != null && _tienda!.tieneImagen) {
      return _tienda!.imagenUrl;
    }
    if (_esArtesano && _artesano != null && _artesano!.tieneAvatar) {
      return _artesano!.avatarUrl;
    }
    final imgs = _productImageUrls;
    return imgs.isNotEmpty ? imgs.first : null;
  }

  String? get _avatarUrl {
    if (_esArtesano && _artesano != null && _artesano!.tieneAvatar) {
      return _artesano!.avatarUrl;
    }
    if (!_esArtesano && _tienda != null && _tienda!.tieneImagen) {
      return _tienda!.imagenUrl;
    }
    final imgs = _productImageUrls;
    return imgs.isNotEmpty ? imgs.first : null;
  }

  /// Regiones presentes en las prendas publicadas.
  List<String> get _regionesDePiezas {
    final set = <String>{};
    for (final a in _articulos) {
      final r = a.region.trim();
      if (r.isNotEmpty && r.toUpperCase() != 'N/A') set.add(r);
    }
    return set.toList()..sort();
  }

  List<String> get _materialesYTecnicas {
    final set = <String>{};
    for (final a in _articulos) {
      for (final raw in [a.tela, a.bordado]) {
        final v = raw.trim();
        if (v.isNotEmpty && v.toUpperCase() != 'N/A') set.add(v);
      }
    }
    return set.toList()..sort();
  }

  List<String> get _categorias {
    final set = <String>{};
    for (final a in _articulos) {
      final c = a.categoriaNombre.trim();
      if (c.isNotEmpty) set.add(c);
    }
    return set.toList()..sort();
  }

  String? get _origenMostrable {
    if (_esArtesano && _artesano != null && _artesano!.tieneRegion) {
      return _artesano!.region;
    }
    if (!_esArtesano && _tienda != null && _tienda!.tieneUbicacion) {
      return _tienda!.ubicacion;
    }
    final regs = _regionesDePiezas;
    if (regs.isEmpty) return null;
    if (regs.length == 1) return regs.first;
    if (regs.length <= 3) return regs.join(' · ');
    return '${regs.take(2).join(' · ')} y más';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: AppLoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: AppErrorView(message: _error!, onRetry: _load),
      );
    }

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(child: _buildProfileHeader()),
        SliverToBoxAdapter(child: _buildInfoCard()),
        if (_chipsDisponibles.isNotEmpty)
          SliverToBoxAdapter(child: _buildChipsSection()),
        SliverToBoxAdapter(child: _buildPiecesHeader()),
        if (_articulos.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyPieces())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final a = _articulos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductCardSmall(
                      articulo: a,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailView(articuloId: a.id),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: _articulos.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    final cover = _coverUrl;
    final coverFallback =
        _productImageUrls.length > 1 ? _productImageUrls[1] : null;

    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      stretch: true,
      backgroundColor: _softPink,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            ProductImage(
              imageUrl: cover,
              fallbackUrl: coverFallback,
              width: double.infinity,
              height: double.infinity,
              icon: _esArtesano
                  ? Icons.volunteer_activism_outlined
                  : Icons.storefront_outlined,
              iconSize: 64,
            ),
            // Velos cálidos para identidad artesanal.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.05),
                    const Color(0xFFD81B60).withValues(alpha: 0.55),
                    const Color(0xFF4A1528).withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _esArtesano ? 'Artesano' : 'Tienda',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatar = _avatarUrl;
    final origen = _origenMostrable;
    final subtitle = _esArtesano
        ? (_artesano?.tieneTitulo == true
            ? _artesano!.titulo
            : (_artesano?.tieneEspecialidad == true
                ? _artesano!.especialidad!
                : null))
        : (_tienda?.tieneEstilo == true ? _tienda!.estilo : null);

    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _bg, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: ProductImage(
                  imageUrl: avatar,
                  width: 88,
                  height: 88,
                  icon: _esArtesano
                      ? Icons.volunteer_activism_outlined
                      : Icons.storefront_outlined,
                  iconSize: 36,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    if (origen != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              origen,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_esArtesano && _artesano?.verificado == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.verified, size: 16, color: _primary),
                          SizedBox(width: 4),
                          Text(
                            'Perfil verificado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final paragraphs = <Widget>[];

    if (_esArtesano) {
      paragraphs.add(_sectionLabel('Sobre el artesano'));
      if (_artesano?.tieneBiografia == true) {
        paragraphs.add(const SizedBox(height: 8));
        paragraphs.add(_bodyText(_artesano!.biografia!));
      } else {
        paragraphs.add(const SizedBox(height: 8));
        paragraphs.add(
          _bodyText(
            _articulos.isEmpty
                ? 'Aquí podrás conocer el trabajo de $_title cuando publique piezas.'
                : 'Explora las piezas de $_title y conoce de cerca su trabajo.',
          ),
        );
      }
      if (_artesano?.tieneEspecialidad == true) {
        paragraphs.add(const SizedBox(height: 14));
        paragraphs.add(_sectionLabel('Especialidad'));
        paragraphs.add(const SizedBox(height: 6));
        paragraphs.add(_bodyText(_artesano!.especialidad!));
      }
    } else {
      paragraphs.add(_sectionLabel('Sobre la tienda'));
      if (_tienda?.tieneDescripcion == true) {
        paragraphs.add(const SizedBox(height: 8));
        paragraphs.add(_bodyText(_tienda!.descripcion!));
      } else {
        paragraphs.add(const SizedBox(height: 8));
        paragraphs.add(
          _bodyText(
            _articulos.isEmpty
                ? 'Explora $_title cuando publique prendas en el catálogo.'
                : 'Descubre las prendas que encontrarás en $_title.',
          ),
        );
      }
      if (_tienda?.tieneEstilo == true) {
        paragraphs.add(const SizedBox(height: 14));
        paragraphs.add(_sectionLabel('Estilo'));
        paragraphs.add(const SizedBox(height: 6));
        paragraphs.add(_bodyText(_tienda!.estilo));
      }
    }

    // Resumen honesto derivado del catálogo de piezas.
    final meta = <String>[];
    if (_articulos.isNotEmpty) {
      meta.add(
        _articulos.length == 1
            ? '1 pieza publicada'
            : '${_articulos.length} piezas publicadas',
      );
    }
    if (_categorias.isNotEmpty) {
      final cats = _categorias.length <= 3
          ? _categorias.join(', ')
          : '${_categorias.take(3).join(', ')}…';
      meta.add(cats);
    }
    if (meta.isNotEmpty) {
      paragraphs.add(const SizedBox(height: 14));
      paragraphs.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _softPink.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _esArtesano
                    ? Icons.auto_awesome
                    : Icons.shopping_bag_outlined,
                size: 18,
                color: _primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta.join(' · '),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: paragraphs,
        ),
      ),
    );
  }

  List<String> get _chipsDisponibles {
    final chips = <String>[];
    chips.addAll(_materialesYTecnicas.take(8));
    for (final c in _categorias) {
      if (!chips.contains(c) && chips.length < 10) chips.add(c);
    }
    return chips;
  }

  Widget _buildChipsSection() {
    final chips = _chipsDisponibles;
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _esArtesano ? 'Materiales y técnicas' : 'Lo que encontrarás aquí',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPiecesHeader() {
    final count = _articulos.length;
    final label = _esArtesano ? 'Conoce su trabajo' : 'Piezas de la tienda';
    final countLabel = count == 0
        ? 'Sin piezas publicadas'
        : count == 1
            ? '1 pieza'
            : '$count piezas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              countLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPieces() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(
              _esArtesano
                  ? Icons.volunteer_activism_outlined
                  : Icons.storefront_outlined,
              size: 40,
              color: _primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _esArtesano
                  ? 'Aún no hay piezas publicadas de este artesano.'
                  : 'Esta tienda todavía no tiene piezas publicadas.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
        color: Colors.black54,
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.45,
        color: Colors.black87,
      ),
    );
  }
}
