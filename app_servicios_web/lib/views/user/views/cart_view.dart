import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/data_config.dart';
import '../../../models/articulo.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/carrito_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/guest_auth_gate.dart';
import 'checkout_view.dart';
import 'product_detail_view.dart';

/// Vista de Carrito.
///
/// Countdown de reserva: un solo [ValueNotifier] + widgets locales
/// (no setState de toda la lista cada segundo).
class CartView extends StatefulWidget {
  final VoidCallback onIrAInicio;

  const CartView({super.key, required this.onIrAInicio});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final _articuloService = ArticuloService();

  bool _loading = true;
  bool _reloading = false;
  String? _error;
  List<Articulo> _articulos = [];

  /// Tick central del reloj de reservas (solo reconstruye textos de countdown).
  final ValueNotifier<int> _clockTick = ValueNotifier<int>(0);
  Timer? _tick;
  Timer? _poll;

  /// Evita que notifyListeners del carrito dispare otro reload en cadena.
  bool _ignoreCarritoListener = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    CarritoService.instance.addListener(_onCarritoChanged);

    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!CarritoService.instance.usaReservaRemota) return;
      // Solo avanza el reloj; no setState del ListView.
      _clockTick.value = _clockTick.value + 1;
    });

    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !CarritoService.instance.usaReservaRemota) return;
      _cargarDatos(silent: true, showLiberadosSnack: true);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    _clockTick.dispose();
    CarritoService.instance.removeListener(_onCarritoChanged);
    super.dispose();
  }

  void _onCarritoChanged() {
    if (!mounted || _ignoreCarritoListener || _reloading) return;
    // Actualización local (cantidades/ítems) sin reconsultar red en bucle.
    _aplicarEstadoLocalDelCarrito();
  }

  /// Refresca la lista de artículos mostrados según ids del servicio.
  /// Si faltan datos de catálogo, hace fetch puntual (no en cada tick).
  Future<void> _aplicarEstadoLocalDelCarrito() async {
    final ids = CarritoService.instance.cantidades.keys.toSet();
    final actuales = {for (final a in _articulos) a.id};

    // Quitar los que ya no están.
    final kept = _articulos.where((a) => ids.contains(a.id)).toList();

    // Traer solo los ids nuevos.
    final missing = ids.where((id) => !actuales.contains(id)).toList();
    if (missing.isNotEmpty) {
      try {
        final nuevos = await _articuloService.fetchArticulosPorIds(missing);
        kept.addAll(nuevos);
      } catch (_) {
        // Sin catálogo para el nuevo id: igual se muestra el resto.
      }
    }

    if (!mounted) return;
    setState(() {
      _articulos = kept;
      if (_loading) _loading = false;
    });
  }

  Future<void> _cargarDatos({
    bool silent = false,
    bool showLiberadosSnack = false,
  }) async {
    if (_reloading) return;
    _reloading = true;
    _ignoreCarritoListener = true;

    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (CarritoService.instance.usaReservaRemota) {
        // notify:false → no reentrar por el listener del servicio.
        await CarritoService.instance.sincronizarRemoto(notify: false);
        if (showLiberadosSnack &&
            CarritoService.instance.reservasLiberadasRecientes > 0 &&
            mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Algunas reservas vencieron y el stock se liberó.',
              ),
            ),
          );
        }
      }

      final ids = CarritoService.instance.cantidades.keys;
      final articulos = await _articuloService.fetchArticulosPorIds(ids);

      if (!mounted) return;
      setState(() {
        _articulos = articulos;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = 'No se pudo cargar el carrito: $e';
          _loading = false;
        });
      }
    } finally {
      _reloading = false;
      _ignoreCarritoListener = false;
    }
  }

  Future<void> _runCartAction(Future<void> Function() action) async {
    try {
      // Las mutaciones del servicio ya notifican; el listener actualiza UI.
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
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

  Future<void> _vaciarCarrito() async {
    await _runCartAction(() async {
      await CarritoService.instance.vaciar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrito vaciado')),
      );
    });
  }

  Future<void> _continuarCompra() async {
    if (_articulos.isEmpty) return;
    if (!await ensureLoggedInForPurchase(context)) return;
    if (!mounted) return;
    if (await ApiService().isVendedor()) {
      if (!mounted) return;
      AppUi.showAccionNoPermitidaVendedor(context);
      return;
    }
    if (_multiTienda) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El carrito mezcla tiendas. Por ahora solo puedes '
            'comprar de una tienda a la vez. Quita productos de otras tiendas.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutView(items: CarritoService.instance.cantidades),
      ),
    );
  }

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
    return Material(
      color: const Color(0xFFF8F5F2),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: () => _cargarDatos());
    }

    if (_articulos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _cargarDatos(),
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
                'Hay productos de más de una tienda. Por ahora solo puedes '
                'comprar de una tienda a la vez: ajusta el carrito antes de continuar.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB71C1C),
                  height: 1.35,
                ),
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
            KeyedSubtree(
              key: ValueKey('cart_item_${articulo.id}'),
              child: _buildCartItem(articulo),
            ),
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

  Widget _buildCartItem(Articulo articulo) {
    final cantidad = CarritoService.instance.cantidadDe(articulo.id);
    final subtotalItem = articulo.precioFinal * cantidad;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.black38,
                            ),
                          ),
                        ),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
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
                  if (CarritoService.instance.usaReservaRemota) ...[
                    const SizedBox(height: 8),
                    _ReservaCountdownLabel(
                      articuloId: articulo.id,
                      clock: _clockTick,
                    ),
                    const Text(
                      'Stock reservado temporalmente para ti.',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          _buildQuantityButton(
                            Icons.remove,
                            onTap: () => _runCartAction(
                              () => CarritoService.instance
                                  .actualizarCantidad(
                                articulo.id,
                                cantidad - 1,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                            onTap: () => _runCartAction(
                              () => CarritoService.instance
                                  .actualizarCantidad(
                                articulo.id,
                                cantidad + 1,
                              ),
                            ),
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
                            onTap: () => _runCartAction(
                              () => CarritoService.instance
                                  .quitar(articulo.id),
                            ),
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
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD81B60).withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFD81B60)),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            _costoEnvio == 0
                ? 'Gratis'
                : '\$${_costoEnvio.toStringAsFixed(2)}',
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
                  const Text(
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
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ],
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
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: Colors.black38),
        SizedBox(width: 6),
        Text(
          'Compra protegida · pago de prueba sin cobro real',
          style: TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ],
    );
  }
}

/// Solo reconstruye el texto del countdown al avanzar [_clockTick].
class _ReservaCountdownLabel extends StatelessWidget {
  final int articuloId;
  final ValueNotifier<int> clock;

  const _ReservaCountdownLabel({
    required this.articuloId,
    required this.clock,
  });

  String _fmt(Duration? d) {
    if (d == null) return '';
    if (d == Duration.zero) return 'Reserva vencida';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return 'Reserva: ${m}m ${s.toString().padLeft(2, '0')}s';
    return 'Reserva: ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: clock,
      builder: (context, tick, child) {
        final exp = CarritoService.instance.expiresAtDe(articuloId);
        Duration? left;
        if (exp != null) {
          final diff = exp.toLocal().difference(DateTime.now());
          left = diff.isNegative ? Duration.zero : diff;
        }
        return Text(
          _fmt(left),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade800,
          ),
        );
      },
    );
  }
}
