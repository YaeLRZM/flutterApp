// LEGACY / FUERA DE FLUJO — no importar desde rutas activas.
// Conservado solo como referencia histórica. Usar MenuConfigView / DetallePedidoView.
// @deprecated
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../../../config/data_config.dart';
import '../../../../models/articulo.dart';
import '../../../../services/articulo_service.dart';
import '../../user_layout.dart';

/// Vista final de "compra exitosa". Recibe los artículos comprados
/// (`articuloId -> cantidad`) desde `PaymentSuccessView` y carga los
/// datos reales con `ArticuloService`, igual que `CheckoutView`.
///
/// TODO: API -> el número de orden ("#IXE-882910"), la dirección de
/// entrega y el método de pago mostrados siguen siendo de muestra;
/// cuando exista GET /api/pedidos/{id} deben venir de esa respuesta
/// junto con los items.
class CompraExitosaView extends StatefulWidget {
  final Map<int, int> items;

  const CompraExitosaView({super.key, required this.items});

  @override
  State<CompraExitosaView> createState() => _CompraExitosaViewState();
}

class _CompraExitosaViewState extends State<CompraExitosaView> {
  late ConfettiController _confettiController;

  final _articuloService = ArticuloService();
  bool _loading = true;
  String? _error;
  List<Articulo> _articulos = [];

  @override
  void initState() {
    super.initState();
    // Configurado para durar 3 segundos y dispararse automáticamente 1 sola vez
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
    _cargarDatos();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
        _error = 'No se pudo cargar el resumen del pedido: $e';
        _loading = false;
      });
    }
  }

  int _cantidadDe(int articuloId) => widget.items[articuloId] ?? 0;

  // --- Cálculos del resumen (mismas reglas que CheckoutView/CartView) ---

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

  void _verPedidos() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const UserLayout(initialPage: 'mis_compras'),
      ),
      (route) => false,
    );
  }

  void _volverAlInicio() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserLayout()),
      (route) => false,
    );
  }

  Future<void> _cancelarCompra() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar compra'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar este pedido? Esta acción '
          'no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    // TODO: API -> DELETE /api/pedidos/{id} (o el endpoint de
    // cancelación real) en vez de solo navegar de regreso.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu compra ha sido cancelada.')),
    );
    _volverAlInicio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFD81B60),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(child: _buildBody()),

          // Animación de Confeti superpuesta
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality
                .explosive, // Dispara en todas las direcciones
            shouldLoop: false,
            colors: const [
              Color(0xFFD81B60), // Rosa bugambilia
              Color(0xFFF48FB1), // Rosa claro
              Color(0xFFFFC107), // Acento amarillo
              Colors.white,
            ],
            createParticlePath:
                drawStar, // Puedes quitar esto si prefieres el confeti rectangular
          ),
        ],
      ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Icono Check
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD81B60),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD81B60).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Gracias por tu\ncompra!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD81B60),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu pedido ha sido recibido con éxito por\nnuestros artesanos de Oaxaca. Estamos\npreparando cada detalle con la maestría\nque mereces.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 32),

          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildDireccionEntrega(),
          const SizedBox(height: 16),
          _buildMetodoPago(),
          const SizedBox(height: 16),
          _buildAccionTiempo(),
          const SizedBox(height: 24),

          // Botón Ver Pedidos
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verPedidos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ver pedidos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botón Volver al Inicio
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _volverAlInicio,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFD81B60), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Volver al inicio',
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80), // Espacio extra para que el FAB no estorbe
        ],
      ),
    );
  }

  // --- Resumen del Pedido ---
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                'Resumen del\nPedido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD81B60),
                  height: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                // TODO: API -> este folio debe venir del pedido real
                // creado por el backend (POST /api/pedidos).
                child: const Text(
                  '#IXE-882910',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (final articulo in _articulos) ...[
            _buildOrderItem(
              articulo.nombre,
              _subtituloArticulo(articulo),
              '\$${(articulo.precioFinal * _cantidadDe(articulo.id)).toStringAsFixed(2)} MXN',
            ),
            const Divider(height: 32, color: Colors.black12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                '\$${_subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          if (_descuentoArtesanal > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Descuento Artesanal',
                  style: TextStyle(fontSize: 13, color: Color(0xFF00BFA5)),
                ),
                Text(
                  '-\$${_descuentoArtesanal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF00BFA5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Envío Premium',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                _costoEnvio == 0
                    ? 'Gratis'
                    : '\$${_costoEnvio.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD81B60),
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtituloArticulo(Articulo articulo) {
    final talla = articulo.talla.isNotEmpty && articulo.talla != 'N/A'
        ? articulo.talla
        : null;
    final color = articulo.color.isNotEmpty && articulo.color != 'N/A'
        ? articulo.color
        : null;

    if (talla != null && color != null) {
      return 'Talla: $talla | Color: $color';
    }
    if (talla != null) return 'Talla: $talla';
    if (color != null) return 'Color: $color';
    return articulo.categoriaNombre;
  }

  Widget _buildOrderItem(String title, String subtitle, String price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            // TODO: API -> Image.network(articulo.imagenUrl)
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image, color: Colors.white54),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD81B60),
          ),
        ),
      ],
    );
  }

  // --- Dirección de Entrega ---
  // TODO: API -> hoy es de muestra; debe venir de la dirección real del
  // pedido (GET /api/pedidos/{id}) o del perfil del usuario.
  Widget _buildDireccionEntrega() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: const [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFFD81B60),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Dirección de Entrega',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'C. Porfirio Díaz 105, Centro Histórico\n68000 Oaxaca de Juárez, Oax.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrega estimada: 15 - 18 de Octubre',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // --- Método de Pago ---
  // TODO: API -> hoy es de muestra; debe venir del método de pago real
  // usado en el pedido (GET /api/pedidos/{id}).
  Widget _buildMetodoPago() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: const [
              Icon(Icons.credit_card, color: Color(0xFFD81B60), size: 18),
              SizedBox(width: 8),
              Text(
                'Método de Pago',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tarjeta terminada en •••• 4492',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.circle, color: Color(0xFF00C853), size: 8),
              SizedBox(width: 6),
              Text(
                'Pago Confirmado',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Acción de Tiempo (Cancelar Compra) ---
  // TODO: API -> hoy es de muestra; el conteo regresivo y la acción de
  // cancelar deben conectarse a la ventana real de cancelación del pedido.
  Widget _buildAccionTiempo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD81B60).withOpacity(0.3),
          width: 1,
        ),
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
            children: const [
              Icon(Icons.timer_outlined, color: Color(0xFFD81B60), size: 20),
              SizedBox(width: 8),
              Text(
                'Acción de Tiempo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '¿Hubo algún error? No te preocupes.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelarCompra,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Cancelar Compra',
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '11:17 restantes para cancelar',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Para hacer que los confetis tengan forma de estrella
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * 1 * (3.1415926535897932 / 180.0),
        halfWidth + externalRadius * 1 * (3.1415926535897932 / 180.0),
      );
      path.lineTo(
        halfWidth + internalRadius * 1 * (3.1415926535897932 / 180.0),
        halfWidth + internalRadius * 1 * (3.1415926535897932 / 180.0),
      );
    }
    path.close();
    return path;
  }
}
