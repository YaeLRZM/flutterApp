import 'package:flutter/material.dart';

import '../../../services/mi_resena_service.dart';
import '../../../widgets/app_ui.dart';
import 'product_detail_view.dart';

/// Opiniones reales del usuario autenticado (GET /api/mis-resenas).
class MisOpinionesView extends StatefulWidget {
  final VoidCallback? onIrAInicio;

  const MisOpinionesView({super.key, this.onIrAInicio});

  @override
  State<MisOpinionesView> createState() => _MisOpinionesViewState();
}

class _MisOpinionesViewState extends State<MisOpinionesView> {
  final _service = MiResenaService();
  bool _loading = true;
  String? _error;
  List<MiResenaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchMias();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoadingView();
    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargar);
    }

    return RefreshIndicator(
      color: const Color(0xFFD81B60),
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          const Text(
            'Mis opiniones',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD81B60),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reseñas que has publicado en productos.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          if (_items.isEmpty)
            AppEmptyView(
              icon: Icons.rate_review_outlined,
              title: 'Aún no has publicado opiniones',
              subtitle:
                  'Desde el detalle de un producto puedes dejar una calificación y un comentario.',
              action: widget.onIrAInicio == null
                  ? null
                  : TextButton(
                      onPressed: widget.onIrAInicio,
                      child: const Text('Explorar catálogo'),
                    ),
            )
          else
            ..._items.map(_buildCard),
        ],
      ),
    );
  }

  Widget _buildCard(MiResenaItem r) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: r.articuloId > 0
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailView(articuloId: r.articuloId),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.articuloNombre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ...List.generate(5, (i) {
                    final filled = i < r.calificacion;
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 18,
                      color: const Color(0xFFD81B60),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    _fmtDate(r.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
              if (r.comentario.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  r.comentario,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
