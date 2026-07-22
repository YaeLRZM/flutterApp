import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/carrito_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';
import 'payment_denied_view.dart';
import 'payment_success_view.dart';

/// Procesamiento de **pago simulado** (tarjeta o efectivo).
/// POST /api/ventas solo al confirmar el método elegido.
class PaymentProcessingView extends StatefulWidget {
  final Map<int, int> items;
  final double totalEstimado;

  /// Si no es null, fuerza éxito/rechazo sin elegir método (legacy).
  final bool? forceSimulateSuccess;

  const PaymentProcessingView({
    super.key,
    required this.items,
    required this.totalEstimado,
    this.forceSimulateSuccess,
  });

  @override
  State<PaymentProcessingView> createState() => _PaymentProcessingViewState();
}

class _PaymentProcessingViewState extends State<PaymentProcessingView> {
  final _ventaService = VentaService();
  final _formKey = GlobalKey<FormState>();

  final _titularCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  /// null = aún no eligió; tarjeta | efectivo
  String? _metodo;
  bool _esperando = true;
  bool _registrandoCompra = false;
  String? _errorRegistro;

  @override
  void initState() {
    super.initState();
    _iniciarSimulacion();
  }

  @override
  void dispose() {
    _titularCtrl.dispose();
    _numeroCtrl.dispose();
    _fechaCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSimulacion() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final forced = widget.forceSimulateSuccess;
    if (forced == true) {
      // Compat: flujo antiguo sin método → legacy backend.
      await _registrarCompra(metodo: null);
      return;
    }
    if (forced == false) {
      _irADenegado();
      return;
    }

    setState(() => _esperando = false);
  }

  Future<void> _confirmarTarjeta() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _registrarCompra(metodo: 'tarjeta');
  }

  Future<void> _confirmarEfectivo() async {
    await _registrarCompra(metodo: 'efectivo');
  }

  Future<void> _registrarCompra({required String? metodo}) async {
    setState(() {
      _registrandoCompra = true;
      _errorRegistro = null;
    });

    try {
      final venta = await _ventaService.crearCompra(
        items: widget.items,
        metodoPago: metodo,
      );
      await CarritoService.instance.vaciar();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessView(
            ventaId: venta.id,
            total: venta.total,
            estado: venta.estado,
            mensaje: venta.metodoPagoClave == 'efectivo'
                ? 'Tu solicitud fue enviada al vendedor'
                : venta.metodoPagoClave == 'tarjeta'
                    ? 'Tu pago fue acreditado'
                    : null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registrandoCompra = false;
        _esperando = false;
        _errorRegistro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _irADenegado() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDeniedView(items: widget.items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppStatusBadge.pagoSimulado(),
        const SizedBox(height: 16),
        const Text(
          'Esta app usa un flujo de pago de prueba; '
          'no se realizará ningún cobro real.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Total estimado: \$${widget.totalEstimado.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 24),
        if (_registrandoCompra) ...[
          const CircularProgressIndicator(color: Color(0xFFD81B60)),
          const SizedBox(height: 16),
          const Text(
            'Registrando tu compra…',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ] else if (_esperando) ...[
          const CircularProgressIndicator(color: Color(0xFFD81B60)),
          const SizedBox(height: 16),
          const Text(
            'Preparando pago de prueba…',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ] else ...[
          const Text(
            'Elige tu forma de pago',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metodoChip(
                  label: 'Tarjeta',
                  selected: _metodo == 'tarjeta',
                  onTap: () => setState(() => _metodo = 'tarjeta'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metodoChip(
                  label: 'Efectivo',
                  selected: _metodo == 'efectivo',
                  onTap: () => setState(() => _metodo = 'efectivo'),
                ),
              ),
            ],
          ),
          if (_metodo == 'tarjeta') ...[
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titularCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del titular',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _numeroCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Número de tarjeta',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(' ', '');
                      if (d.length < 13) return 'Número incompleto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fechaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Fecha (MM/AA)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(t)) {
                              return 'Usa MM/AA';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if ((v ?? '').length < 3) return 'CVV inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Datos solo de prueba; no se envían a un banco.',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registrandoCompra ? null : _confirmarTarjeta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Pagar con tarjeta (prueba)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (_metodo == 'efectivo') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Text(
                'El vendedor debe activar tu pago en efectivo antes de generar el código. '
                'Al confirmar, se enviará la solicitud a la tienda.',
                style: TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registrandoCompra ? null : _confirmarEfectivo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Solicitar pago en efectivo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (_errorRegistro != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorRegistro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _registrandoCompra ? null : _irADenegado,
            child: const Text(
              'Cancelar prueba',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Pago de prueba',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: cardBody,
            ),
          ),
        ),
      ),
    );
  }

  Widget _metodoChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFD81B60) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD81B60)
                  : const Color(0xFFE0D8D4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
