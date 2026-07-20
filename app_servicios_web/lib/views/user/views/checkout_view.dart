import 'package:flutter/material.dart';

import '../../../config/data_config.dart';
import '../../../models/articulo.dart';
import '../../../services/articulo_service.dart';
import 'payment_processing_view.dart';

/// Vista de Checkout. Recibe los artículos a comprar (`articuloId ->
/// cantidad`) desde `ProductDetailView` ("Comprar ahora", un solo
/// artículo) o desde `CartView` ("Continuar compra", el carrito
/// completo) y arma el resumen con datos reales de `ArticuloService`,
/// igual que hace `CartView`.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => CheckoutView(items: {articulo.id: 1}),
/// ));
/// ```
///
/// TODO: API -> al presionar "Finalizar Pago" esto debería crear el
/// pedido en el backend:
///   POST /api/pedidos  { items: [{articulo_id, cantidad}], metodo_pago }
/// y navegar a PaymentProcessingView mientras se espera la respuesta.
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

  // --- Cálculos del resumen (mismas reglas que CartView) ---

  double get _subtotal {
    double total = 0;
    for (final a in _articulos) {
      total += a.precio * _cantidadDe(a.id);
    }
    return total;
  }

  double get _descuentoArtesanal {
    double total = 0;
    for (final a in _articulos) {
      if (!a.tieneDescuento) continue;
      total += (a.precio - a.precioFinal) * _cantidadDe(a.id);
    }
    return total;
  }

  double get _costoEnvio {
    if (_articulos.isEmpty) return 0;
    final subtotalConDescuento = _subtotal - _descuentoArtesanal;
    return subtotalConDescuento >= kEnvioGratisDesde ? 0 : kCostoEnvioNacional;
  }

  double get _total => _subtotal - _descuentoArtesanal + _costoEnvio;

  int get _totalArticulos =>
      _articulos.fold<int>(0, (acc, a) => acc + _cantidadDe(a.id));

  void _finalizarPago() {
    // TODO: API -> antes de navegar, hacer POST /api/pedidos con
    // widget.items y el método de pago seleccionado; usar el pedidoId
    // real que regrese el backend en vez de simular el resultado
    // dentro de PaymentProcessingView.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentProcessingView(
          items: widget.items,
          total: _total,
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
              ElevatedButton(
                onPressed: _cargarDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildItemsSummary(),
        const SizedBox(height: 24),
        _buildPaymentMethods(),
        const SizedBox(height: 24),
        _buildOrderTotals(),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- 1. Encabezado ---
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finalizar Pago',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD81B60),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Por favor, revisa tus artículos y selecciona un método de pago para completar tu adquisición de lujo.',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
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

  // --- 3. Métodos de Pago ---
  // TODO: API -> hoy son estáticos; cuando exista el endpoint de
  // métodos de pago guardados (GET /api/metodos-pago) esto debe volverse
  // dinámico y permitir seleccionar cuál usar en _finalizarPago().
  Widget _buildPaymentMethods() {
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
          const Text(
            'Método de Pago',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Opción Seleccionada (Tarjeta)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD81B60).withOpacity(0.03),
              border: Border.all(color: const Color(0xFFD81B60), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: Color(0xFFD81B60)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tarjeta Crédito/Débito',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Terminada en **** 4421',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Color(0xFFD81B60)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Opción Inactiva (PayPal)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.black54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PayPal Express',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Paga de forma segura',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'PayPal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botón Agregar Nuevo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFD81B60).withOpacity(0.3),
                style: BorderStyle.solid,
              ), // Usamos solid por simplicidad, dotted requiere package extra
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_circle_outline, color: Colors.black54, size: 20),
                SizedBox(width: 8),
                Text(
                  'Agregar nuevo método\nde pago',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Resumen Total y Botón Final ---
  Widget _buildOrderTotals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECEF), // Gris azulado claro de la imagen
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Orden',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD81B60),
            ),
          ),
          const SizedBox(height: 20),

          _buildTotalRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _buildTotalRow(
            'Envío Asegurado',
            _costoEnvio == 0
                ? 'GRATIS'
                : '\$${_costoEnvio.toStringAsFixed(2)}',
            isFree: _costoEnvio == 0,
          ),
          if (_descuentoArtesanal > 0) ...[
            const SizedBox(height: 12),
            _buildTotalRow(
              'Descuento Artesanal',
              '-\$${_descuentoArtesanal.toStringAsFixed(2)}',
              isFree: true,
            ),
          ],
          const SizedBox(height: 12),
          _buildTotalRow('Impuestos (IVA)', 'Incluido'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.black12, height: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'MXN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Badge de Garantía
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu pago está protegido por nuestra garantía de autenticidad Ixé. Si no estás satisfecho con la calidad artesanal, devolvemos tu dinero.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón Pagar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finalizarPago,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Finalizar Pago',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.lock_outline, color: Colors.white, size: 18),
                ],
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
