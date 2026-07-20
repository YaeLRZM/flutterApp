import 'package:flutter/material.dart';

import '../../../models/articulo.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';
import '../../user/views/product_detail_view.dart';

/// Mis productos del vendedor: listado real + detalle + toggle disponible + edición mínima.
class ProductosView extends StatefulWidget {
  const ProductosView({super.key});

  @override
  State<ProductosView> createState() => _ProductosViewState();
}

enum _FiltroPublicacion { todos, publicados, ocultos }

class _ProductosViewState extends State<ProductosView> {
  static const Color primaryColor = Color(0xFFD81B60);
  static const Color onSurface = Color(0xFF131D21);
  static const Color secondaryText = Color(0xFF5E6668);
  static const Color outlineVariant = Color(0xFFE0BEC6);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  final _articuloService = ArticuloService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  String _tiendaNombre = '';
  int? _tiendaId;
  List<Articulo> _productos = [];
  _FiltroPublicacion _filtro = _FiltroPublicacion.todos;
  String _query = '';
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final me = await ApiService().fetchMe();
      if (me['success'] != true || me['user'] is! Map) {
        throw Exception(
          me['message']?.toString() ?? 'No se pudo cargar la sesión del vendedor',
        );
      }

      final user = Map<String, dynamic>.from(me['user'] as Map);
      final vendedorRaw = user['vendedor'];
      if (vendedorRaw is! Map) {
        throw Exception(
          'Esta cuenta no tiene perfil de vendedor vinculado a una tienda.',
        );
      }
      final vendedor = Map<String, dynamic>.from(vendedorRaw);
      final tiendaRaw = vendedor['tienda'];
      if (tiendaRaw is! Map) {
        throw Exception('El vendedor no tiene tienda asignada.');
      }
      final tienda = Map<String, dynamic>.from(tiendaRaw);
      final tiendaId = tienda['id'] is int
          ? tienda['id'] as int
          : int.tryParse(tienda['id']?.toString() ?? '') ?? 0;
      if (tiendaId <= 0) {
        throw Exception('Tienda inválida para este vendedor.');
      }

      final productos = await _articuloService.fetchArticulosPorTienda(
        tiendaId,
        limit: 100,
      );

      if (!mounted) return;
      setState(() {
        _tiendaId = tiendaId;
        _tiendaNombre = tienda['nombre']?.toString() ?? 'Mi tienda';
        _productos = productos;
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

  void _abrirDetalle(Articulo a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailView(articuloId: a.id),
      ),
    );
  }

  Future<void> _toggleDisponible(Articulo a) async {
    if (_busyIds.contains(a.id)) return;
    setState(() => _busyIds.add(a.id));
    try {
      final updated = await _articuloService.updateArticulo(a.id, {
        'disponible': !a.disponible,
      });
      if (!mounted) return;
      setState(() {
        // Refresh local inmediato (sin reiniciar app).
        final i = _productos.indexWhere((p) => p.id == a.id);
        if (i >= 0) {
          _productos = List<Articulo>.from(_productos)..[i] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.disponible
                ? 'Producto publicado en el catálogo'
                : 'Producto oculto del catálogo público',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(a.id));
    }
  }

  Future<void> _abrirEdicion(Articulo a) async {
    // Capturar messenger del padre ANTES del modal (context estable).
    final messenger = ScaffoldMessenger.maybeOf(context);

    final saved = await showModalBottomSheet<Articulo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Padding de teclado FUERA del State del form: evita dependientes
      // de MediaQuery al desmontar el sheet con teclado abierto.
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: _EditarProductoSheet(
            articulo: a,
            articuloService: _articuloService,
          ),
        );
      },
    );

    if (!mounted) return;
    if (saved == null) return;

    setState(() {
      final i = _productos.indexWhere((p) => p.id == saved.id);
      if (i >= 0) {
        _productos = List<Articulo>.from(_productos)..[i] = saved;
      }
    });

    // SnackBar en el frame siguiente, con el messenger del padre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Producto actualizado')),
      );
    });
  }

  List<Articulo> get _filtrados {
    Iterable<Articulo> list = _productos;
    switch (_filtro) {
      case _FiltroPublicacion.publicados:
        list = list.where((a) => a.disponible);
        break;
      case _FiltroPublicacion.ocultos:
        list = list.where((a) => !a.disponible);
        break;
      case _FiltroPublicacion.todos:
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) {
        return a.nombre.toLowerCase().contains(q) ||
            a.categoriaNombre.toLowerCase().contains(q) ||
            a.region.toLowerCase().contains(q);
      });
    }
    return list.toList();
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
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final items = _filtrados;
    final nPub = _productos.where((a) => a.disponible).length;
    final nOcultos = _productos.length - nPub;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis productos',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tiendaNombre.isEmpty
                  ? 'Gestión de tu tienda'
                  : '$_tiendaNombre',
              style: const TextStyle(fontSize: 14, color: secondaryText),
            ),
            if (_tiendaId != null)
              Text(
                '${_productos.length} producto(s) · $nPub publicados · $nOcultos ocultos',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Filtrar por nombre o categoría…',
                prefixIcon: const Icon(Icons.search, color: secondaryText),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    'Todos (${_productos.length})',
                    _filtro == _FiltroPublicacion.todos,
                    () => setState(() => _filtro = _FiltroPublicacion.todos),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    'Publicados ($nPub)',
                    _filtro == _FiltroPublicacion.publicados,
                    () => setState(
                      () => _filtro = _FiltroPublicacion.publicados,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    'Ocultos ($nOcultos)',
                    _filtro == _FiltroPublicacion.ocultos,
                    () => setState(() => _filtro = _FiltroPublicacion.ocultos),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    _productos.isEmpty
                        ? 'Tu tienda aún no tiene productos.'
                        : _filtro == _FiltroPublicacion.ocultos
                            ? 'No hay productos ocultos.'
                            : _filtro == _FiltroPublicacion.publicados
                                ? 'No hay productos publicados.'
                                : 'Ningún producto coincide con el filtro.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: secondaryText),
                  ),
                ),
              )
            else
              ...items.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildProductCard(a),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? primaryColor : outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Articulo a) {
    final busy = _busyIds.contains(a.id);
    // Publicado/Oculto = campo disponible (no confundir con stock).
    final statusColor = a.disponible ? successColor : warningColor;
    final status = a.disponible ? 'Publicado' : 'Oculto';
    final imageUrl = a.imagenUrl;

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalle(a),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ColorFiltered(
                      colorFilter: a.disponible
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey.shade300),
                            )
                          : Container(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.categoriaNombre.isNotEmpty
                                  ? a.categoriaNombre
                                  : 'Sin categoría',
                              style: const TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${a.precio.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock: ${a.stock} unidades'
                    '${a.region.isNotEmpty ? ' · ${a.region}' : ''}'
                    '${a.disponible ? '' : ' · no visible en catálogo público'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: a.disponible ? Colors.black45 : warningColor,
                      fontWeight:
                          a.disponible ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => _abrirEdicion(a),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: busy ? null : () => _toggleDisponible(a),
                          icon: busy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  a.disponible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 16,
                                ),
                          label: Text(
                            a.disponible ? 'Ocultar' : 'Publicar',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: a.disponible
                        ? () => _abrirDetalle(a)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Este producto está oculto: no aparece en el catálogo público. Publícalo para previsualizarlo como cliente.',
                                ),
                              ),
                            );
                          },
                    child: Text(
                      a.disponible
                          ? 'Ver en catálogo público'
                          : 'Oculto del catálogo público',
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
}

/// Formulario de edición: controllers solo aquí (initState/dispose).
/// Sin StatefulBuilder. Sin MediaQuery de teclado (va en el Padding exterior).
class _EditarProductoSheet extends StatefulWidget {
  final Articulo articulo;
  final ArticuloService articuloService;

  const _EditarProductoSheet({
    required this.articulo,
    required this.articuloService,
  });

  @override
  State<_EditarProductoSheet> createState() => _EditarProductoSheetState();
}

class _EditarProductoSheetState extends State<_EditarProductoSheet> {
  static const Color primaryColor = Color(0xFFD81B60);

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _telaCtrl;
  late final TextEditingController _bordadoCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.articulo;
    _nombreCtrl = TextEditingController(text: a.nombre);
    _descCtrl = TextEditingController(text: a.descripcion ?? '');
    _precioCtrl = TextEditingController(text: a.precio.toStringAsFixed(2));
    _colorCtrl = TextEditingController(text: a.color);
    _telaCtrl = TextEditingController(text: a.tela);
    _bordadoCtrl = TextEditingController(text: a.bordado);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _colorCtrl.dispose();
    _telaCtrl.dispose();
    _bordadoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_saving || !mounted) return;

    // Quitar foco/teclado ANTES de await/pop (evita _dependents en MediaQuery/Focus).
    FocusManager.instance.primaryFocus?.unfocus();

    final precio = double.tryParse(
      _precioCtrl.text.trim().replaceAll(',', '.'),
    );
    if (_nombreCtrl.text.trim().isEmpty || precio == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y precio válidos son obligatorios'),
        ),
      );
      return;
    }

    // Snapshot de campos ANTES de cualquier await.
    final payload = <String, dynamic>{
      'nombre': _nombreCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'precio': precio,
      'color': _colorCtrl.text.trim(),
      'tela': _telaCtrl.text.trim(),
      'bordado': _bordadoCtrl.text.trim(),
    };

    setState(() => _saving = true);
    try {
      final updated = await widget.articuloService.updateArticulo(
        widget.articulo.id,
        payload,
      );
      // Única acción al éxito: pop con resultado. NO setState después.
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sin MediaQuery.viewInsets aquí: el Padding exterior del sheet lo maneja.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),
          const Text(
            'Editar producto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Campos básicos · #${widget.articulo.id}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _field('Nombre', _nombreCtrl),
          _field('Descripción', _descCtrl, maxLines: 3),
          _field('Precio', _precioCtrl, keyboard: TextInputType.number),
          _field('Color', _colorCtrl),
          _field('Tela', _telaCtrl),
          _field('Bordado', _bordadoCtrl),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
