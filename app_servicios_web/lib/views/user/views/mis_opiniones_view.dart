import 'package:flutter/material.dart';

import '../../../services/mi_resena_service.dart';
import '../../../widgets/app_ui.dart';
import 'product_detail_view.dart';

/// Opiniones reales del usuario autenticado.
/// Listar / editar / borrar vía API (solo las propias).
class MisOpinionesView extends StatefulWidget {
  final VoidCallback? onIrAInicio;

  const MisOpinionesView({super.key, this.onIrAInicio});

  @override
  State<MisOpinionesView> createState() => _MisOpinionesViewState();
}

class _MisOpinionesViewState extends State<MisOpinionesView> {
  static const Color bugambilia = Color(0xFFD81B60);

  final _service = MiResenaService();
  bool _loading = true;
  String? _error;
  List<MiResenaItem> _items = [];
  int? _busyId;

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

  Future<void> _editar(MiResenaItem r) async {
    final result = await showModalBottomSheet<MiResenaItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F5F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditOpinionSheet(item: r),
    );
    if (result == null || !mounted) return;

    setState(() => _busyId = r.id);
    try {
      final updated = await _service.actualizar(
        id: r.id,
        calificacion: result.calificacion,
        comentario: result.comentario,
      );
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((e) => e.id == r.id);
        if (i >= 0) {
          // Conserva nombre de artículo si la respuesta no trae relación.
          _items[i] = updated.articuloNombre == 'Artículo' &&
                  r.articuloNombre.isNotEmpty
              ? updated.copyWith(articuloNombre: r.articuloNombre)
              : updated;
        }
        _busyId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opinión actualizada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _borrar(MiResenaItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar opinión'),
        content: Text(
          '¿Deseas eliminar tu opinión sobre «${r.articuloNombre}»? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busyId = r.id);
    try {
      await _service.eliminar(r.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((e) => e.id == r.id);
        _busyId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opinión eliminada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
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
    if (_loading) return const AppLoadingView();
    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargar);
    }

    return RefreshIndicator(
      color: bugambilia,
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
              color: bugambilia,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reseñas que has publicado. Puedes editarlas o eliminarlas.',
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
    final busy = _busyId == r.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E0DC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
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
              child: Text(
                r.articuloNombre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
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
                    color: bugambilia,
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
            const SizedBox(height: 12),
            if (busy)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _editar(r),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(foregroundColor: bugambilia),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _borrar(r),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Borrar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Modal para editar calificación y comentario.
class _EditOpinionSheet extends StatefulWidget {
  final MiResenaItem item;

  const _EditOpinionSheet({required this.item});

  @override
  State<_EditOpinionSheet> createState() => _EditOpinionSheetState();
}

class _EditOpinionSheetState extends State<_EditOpinionSheet> {
  late int _calificacion;
  late final TextEditingController _comentarioCtrl;

  @override
  void initState() {
    super.initState();
    _calificacion = widget.item.calificacion.clamp(1, 5);
    _comentarioCtrl = TextEditingController(text: widget.item.comentario);
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Editar opinión',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.articuloNombre,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          const Text(
            'Calificación',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= _calificacion;
              return IconButton(
                onPressed: () => setState(() => _calificacion = star),
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: const Color(0xFFD81B60),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: 'Comentario',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                widget.item.copyWith(
                  calificacion: _calificacion,
                  comentario: _comentarioCtrl.text.trim(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Guardar cambios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
