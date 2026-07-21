import 'package:flutter/material.dart';

import '../../../models/articulo.dart';
import '../../../services/articulo_service.dart';
import '../../../services/artesano_service.dart';
import '../../../services/tienda_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/product_card_small.dart';
import 'product_detail_view.dart';

enum PublicCatalogEntityType { artesano, tienda }

/// Pantalla pública simple: cabecera de artesano/tienda + listado de artículos.
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
  final _articuloService = ArticuloService();
  final _artesanoService = ArtesanoService();
  final _tiendaService = TiendaService();

  bool _loading = true;
  String? _error;
  String _title = '';
  String _subtitle = '';
  List<Articulo> _articulos = [];

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
      if (widget.type == PublicCatalogEntityType.artesano) {
        final a = await _artesanoService.fetchArtesanoPorId(widget.entityId);
        _title = a?.nombre.isNotEmpty == true
            ? a!.nombre
            : (widget.fallbackTitle ?? 'Artesano');
        _subtitle = a?.region.isNotEmpty == true
            ? a!.region
            : 'Artesano de Oaxaca';
        articulos = await _articuloService.fetchArticulosPorArtesano(
          widget.entityId,
          limit: 50,
        );
      } else {
        final t = await _tiendaService.fetchTiendaPorId(widget.entityId);
        _title = t?.nombre.isNotEmpty == true
            ? t!.nombre
            : (widget.fallbackTitle ?? 'Tienda');
        _subtitle = (t?.descripcion?.isNotEmpty == true)
            ? t!.descripcion!
            : 'Tienda de prendas y textiles de Oaxaca';
        articulos = await _articuloService.fetchArticulosPorTienda(
          widget.entityId,
          limit: 50,
        );
      }

      if (!mounted) return;
      setState(() {
        _articulos = articulos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.type == PublicCatalogEntityType.artesano
              ? 'Artesano'
              : 'Tienda',
          style: const TextStyle(color: Colors.black87, fontSize: 16),
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
      return AppErrorView(message: _error!, onRetry: _load);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          _title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Text(
          _articulos.isEmpty
              ? 'No hay piezas publicadas todavía.'
              : '${_articulos.length} pieza(s)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD81B60),
          ),
        ),
        const SizedBox(height: 12),
        ..._articulos.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProductCardSmall(
              articulo: a,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailView(articuloId: a.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
