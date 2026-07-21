import 'package:flutter/material.dart';

import '../../../config/data_config.dart';
import '../../../models/articulo.dart';
import '../../../services/articulo_service.dart';
import '../../../services/carrito_service.dart';
import '../../../widgets/app_ui.dart';
import 'checkout_view.dart';
import 'product_detail_view.dart';

/// Vista de Carrito. Las cantidades viven en `CarritoService`
/// (compartido con `ProductDetailView` y `FavoritesView`); esta vista
/// solo pide, con esos ids, los artículos completos y calcula el
/// resumen de compra en tiempo real.
///
/// [onIrAInicio] se usa para el botón "Elegir más productos": cambia a
/// la pestaña de Inicio del bottom bar (igual que `onIrAColecciones` en
/// HomeView), en vez de abrir una pantalla nueva.
class CartView extends StatefulWidget {
  final VoidCallback onIrAInicio;

  const CartView({super.key, required this.onIrAInicio});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final _articuloService = ArticuloService();

  bool _loading = true;
  String? _error;
  List<Articulo> _articulos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    CarritoService.instance.addListener(_onCarritoChanged);
  }

  @override
  void dispose() {
    CarritoService.instance.removeListener(_onCarritoChanged);
    super.dispose();
  }

  void _onCarritoChanged() {
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ids = CarritoService.instance.cantidades.keys;
      final articulos = await _articuloService.fetchArticulosPorIds(ids);

      if (!mounted) return;
      setState(() {
        _articulos = articulos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el carrito: $e';
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

  bool get _multiTienda {
    final ids = _articulos.map((a) => a.tiendaId).where((id) => id > 0).toSet();
    return ids.length > 1;
  }

  void _vaciarCarrito() {
    CarritoService.instance.vaciar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carrito vaciado (local)')),
    );
  }

  void _continuarCompra() {
    if (_articulos.isEmpty) return;
    if (_multiTienda) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El carrito mezcla tiendas. En esta versión solo puedes '
            'comprar de una tienda a la vez. Quita productos de otras tiendas.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutView(items: CarritoService.instance.cantidades),
      ),
    );
  }

  // --- Cálculos del resumen ---

  double get _subtotalOriginal {
    double total = 0;
    for (final a in _articulos) {
      final cantidad = CarritoService.instance.cantidadDe(a.id);
      total += a.precio * cantidad;
    }
    return total;
  }

  double get _descuentoArtesanal {
    double total = 0;
    for (final a in _articulos) {
      if (!a.tieneDescuento) continue;
      final cantidad = CarritoService.instance.cantidadDe(a.id);
      total += (a.precio - a.precioFinal) * cantidad;
    }
    return total;
  }

  double get _costoEnvio {
    final subtotalConDescuento = _subtotalOriginal - _descuentoArtesanal;
    if (_articulos.isEmpty) return 0;
    return subtotalConDescuento >= kEnvioGratisDesde ? 0 : kCostoEnvioNacional;
  }

  double get _total => _subtotalOriginal - _descuentoArtesanal + _costoEnvio;

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF8F5F2), child: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargarDatos);
    }

    if (_articulos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          if (_multiTienda)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: const Text(
                'Hay productos de más de una tienda. La compra v1 solo '
                'permite una tienda por compra: ajusta el carrito antes de continuar.',
                style: TextStyle(fontSize: 12, color: Color(0xFFB71C1C), height: 1.35),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _vaciarCarrito,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Vaciar carrito'),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
            ),
          ),
          for (final articulo in _articulos) ...[
            _buildCartItem(articulo),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildSecurityBadge(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyView(
      icon: Icons.shopping_bag_outlined,
      title: 'Tu carrito está vacío.',
      subtitle: 'Explora el catálogo y agrega piezas.',
      action: OutlinedButton(
        onPressed: widget.onIrAInicio,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD81B60)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
        child: const Text(
          'Ir a explorar',
          style: TextStyle(
            color: Color(0xFFD81B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Tarjeta de producto en carrito ---
  Widget _buildCartItem(Articulo articulo) {
    final cantidad = CarritoService.instance.cantidadDe(articulo.id);
    final subtotalItem = articulo.precioFinal * cantidad;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _abrirArticulo(articulo.id),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: articulo.imagenUrl.startsWith('http')
                  ? Image.network(
                      articulo.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: Colors.grey.shade300),
                    )
                  : ColoredBox(color: Colors.grey.shade300),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _abrirArticulo(articulo.id),
                  child: Text(
                    articulo.nombre,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${articulo.tela.toUpperCase()} • ${articulo.color.toUpperCase()}'
                      .replaceAll('N/A • ', '')
                      .replaceAll(' • N/A', ''),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _buildQuantityButton(
                          Icons.remove,
                          onTap: () => CarritoService.instance
                              .actualizarCantidad(articulo.id, cantidad - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '$cantidad',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          Icons.add,
                          onTap: () => CarritoService.instance
                              .actualizarCantidad(articulo.id, cantidad + 1),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${subtotalItem.toStringAsFixed(2)} MXN',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD81B60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () =>
                              CarritoService.instance.quitar(articulo.id),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: Colors.red[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildQuantityButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFD81B60)),
      ),
    );
  }

  // --- Resumen de compra ---
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Compra',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Subtotal (${_articulos.length} producto${_articulos.length == 1 ? '' : 's'})',
            '\$${_subtotalOriginal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Envío (Nacional)',
            _costoEnvio == 0 ? 'Gratis' : '\$${_costoEnvio.toStringAsFixed(2)}',
          ),
          if (_descuentoArtesanal > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Descuento Artesanal',
              '-\$${_descuentoArtesanal.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.black12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_total.toStringAsFixed(2)} MXN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'IVA incluido',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _multiTienda ? null : _continuarCompra,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _multiTienda
                        ? 'Ajusta tiendas para continuar'
                        : 'Continuar a checkout',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_multiTienda) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onIrAInicio,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Elegir más productos',
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDiscount ? const Color(0xFF00BFA5) : Colors.black54,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDiscount ? const Color(0xFF00BFA5) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEef4fb),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.security, color: Color(0xFFD81B60), size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compra Segura',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Protección de datos garantizada',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
