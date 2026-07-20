import 'package:flutter/material.dart';

import '../../../models/articulo.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';

/// Mis productos del vendedor (solo lectura).
/// Resuelve tienda vía GET /api/me → vendedor.tienda y lista
/// GET /api/articulos?tienda={id}.
class ProductosView extends StatefulWidget {
  const ProductosView({super.key});

  @override
  State<ProductosView> createState() => _ProductosViewState();
}

enum _FiltroStock { todos, conStock, sinStock }

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
  _FiltroStock _filtro = _FiltroStock.todos;
  String _query = '';

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

  List<Articulo> get _filtrados {
    Iterable<Articulo> list = _productos;
    switch (_filtro) {
      case _FiltroStock.conStock:
        list = list.where((a) => a.stock > 0);
        break;
      case _FiltroStock.sinStock:
        list = list.where((a) => a.stock <= 0);
        break;
      case _FiltroStock.todos:
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

  String _statusLabel(Articulo a) {
    if (a.stock <= 0) return 'Sin stock';
    if (a.stock <= 5) return 'Bajo stock';
    return 'Disponible';
  }

  Color _statusColor(Articulo a) {
    if (a.stock <= 0) return secondaryText;
    if (a.stock <= 5) return warningColor;
    return successColor;
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
    final conStock = _productos.where((a) => a.stock > 0).length;
    final sinStock = _productos.length - conStock;

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
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tiendaNombre.isEmpty
                  ? 'Piezas de tu tienda (solo lectura)'
                  : '$_tiendaNombre · solo lectura',
              style: const TextStyle(fontSize: 14, color: secondaryText),
            ),
            if (_tiendaId != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_productos.length} producto(s) en tienda #$_tiendaId',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Filtrar por nombre o categoría…',
                hintStyle: const TextStyle(color: secondaryText),
                prefixIcon: const Icon(Icons.search, color: secondaryText),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Crear producto estará disponible en una próxima versión.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nuevo Producto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Todos (${_productos.length})',
                    selected: _filtro == _FiltroStock.todos,
                    onTap: () => setState(() => _filtro = _FiltroStock.todos),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Con stock ($conStock)',
                    selected: _filtro == _FiltroStock.conStock,
                    onTap: () =>
                        setState(() => _filtro = _FiltroStock.conStock),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Sin stock ($sinStock)',
                    selected: _filtro == _FiltroStock.sinStock,
                    onTap: () =>
                        setState(() => _filtro = _FiltroStock.sinStock),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    _productos.isEmpty
                        ? 'Tu tienda aún no tiene productos publicados.'
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

  Widget _buildFilterChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? primaryColor : outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: selected ? Colors.white : secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Articulo a) {
    final status = _statusLabel(a);
    final statusColor = _statusColor(a);
    final sinStock = a.stock <= 0;
    final imageUrl = a.imagenUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ColorFiltered(
                colorFilter: sinStock
                    ? const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
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
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
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
                    const SizedBox(width: 8),
                    Text(
                      '\$${a.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock',
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                        Text(
                          '${a.stock} unidades',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: a.stock == 0
                                ? const Color(0xFFBA1A1A)
                                : (a.stock <= 5 ? warningColor : onSurface),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      a.region.isNotEmpty ? a.region : '',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
