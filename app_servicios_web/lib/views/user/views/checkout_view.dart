import 'package:flutter/material.dart';

import '../../../models/articulo.dart';
import '../../../services/articulo_service.dart';
import '../../../widgets/app_ui.dart';
import 'payment_processing_view.dart';

/// Checkout: resumen del carrito local + flujo de **pago simulado**.
/// La venta real se crea solo si la simulación termina en éxito
/// (ver [PaymentProcessingView]).
/// Restricción v1: una sola tienda por compra.
class CheckoutView extends StatefulWidget {
  final Map<int, int> items;

  const CheckoutView({super.key, required this.items});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _articuloService = ArticuloService();

  bool _loading = true;
  String? _error;
  List<Articulo> _articulos = [];

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
      final articulos = await _articuloService.fetchArticulosPorIds(
        widget.items.keys,
      );
      if (!mounted) return;
      setState(() {
        _articulos = articulos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el resumen de compra: $e';
        _loading = false;
      });
    }
  }

  int _cantidadDe(int articuloId) => widget.items[articuloId] ?? 0;

  /// Total orientativo (precios de catálogo × cantidad).
  /// El total oficial lo calcula el servidor al crear la venta.
  double get _subtotal {
    double total = 0;
    for (final a in _articulos) {
      total += a.precio * _cantidadDe(a.id);
    }
    return total;
  }

  int get _totalArticulos =>
      _articulos.fold<int>(0, (acc, a) => acc + _cantidadDe(a.id));

  Set<int> get _tiendaIds =>
      _articulos.map((a) => a.tiendaId).where((id) => id > 0).toSet();

  bool get _multiTienda => _tiendaIds.length > 1;

  void _continuarAPagoSimulado() {
    if (_articulos.isEmpty) return;

    if (_multiTienda) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo puedes comprar artículos de una misma tienda. '
            'Ajusta el carrito e intenta de nuevo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final items = <int, int>{
      for (final a in _articulos) a.id: _cantidadDe(a.id),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentProcessingView(
          items: items,
          totalEstimado: _subtotal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
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
      return AppErrorView(message: _error!, onRetry: _cargarDatos);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildItemsSummary(),
        const SizedBox(height: 24),
        // Sin métodos de pago inventados: no hay pasarela en v1.
        _buildOrderTotals(),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- 1. Encabezado ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmar compra',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Siguiente paso: flujo de pago simulado (prueba). '
          'No se cobrará dinero real. La compra en servidor se registra solo si la simulación resulta exitosa.',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'PAGO SIMULADO · sin pasarela · sin cobro real',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
        if (_multiTienda) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: const Text(
              'Tu carrito mezcla productos de varias tiendas. '
              'En esta versión solo se permite una tienda por compra.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB71C1C), height: 1.35),
            ),
          ),
        ],
      ],
    );
  }

  // --- 2. Resumen de Artículos ---
  Widget _buildItemsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen de\nCompra',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD81B60).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalArticulos\nArtículos',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD81B60),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (final articulo in _articulos) ...[
            _buildSummaryItem(articulo, _cantidadDe(articulo.id)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(Articulo articulo, int cantidad) {
    final subtotalItem = articulo.precioFinal * cantidad;

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            // TODO: API -> Image.network(articulo.imagenUrl)
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                articulo.nombre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cantidad > 1
                    ? '${articulo.categoriaNombre.toUpperCase()} • x$cantidad'
                    : articulo.categoriaNombre.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${subtotalItem.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60),
          ),
        ),
      ],
    );
  }

  // --- Resumen Total y Botón Final ---
  Widget _buildOrderTotals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECEF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen (orientativo)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD81B60),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalArticulos artículo(s) · una tienda por compra',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _buildTotalRow(
            'Subtotal catálogo',
            '\$${_subtotal.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.black12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total estimado',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                '\$${_subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sin envío ni pasarela. El total final lo define el servidor.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_multiTienda || _articulos.isEmpty)
                  ? null
                  : _continuarAPagoSimulado,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continuar a pago simulado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isFree ? FontWeight.w900 : FontWeight.w600,
            color: isFree ? const Color(0xFF00BFA5) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
