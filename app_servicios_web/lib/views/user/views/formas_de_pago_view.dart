import 'package:flutter/material.dart';

import '../../../services/forma_pago_service.dart';
import '../../../widgets/app_ui.dart';

/// Catálogo real de formas de pago (GET /api/formas-pago).
class FormasDePagoView extends StatefulWidget {
  final VoidCallback? onIrAInicio;

  const FormasDePagoView({super.key, this.onIrAInicio});

  @override
  State<FormasDePagoView> createState() => _FormasDePagoViewState();
}

class _FormasDePagoViewState extends State<FormasDePagoView> {
  final _service = FormaPagoService();
  bool _loading = true;
  String? _error;
  List<FormaPagoItem> _items = [];

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
      final list = await _service.fetchFormasPago();
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
            'Formas de pago',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD81B60),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Métodos disponibles en la tienda. '
            'Al comprar se usa un pago de prueba (sin cobro real).',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 20),
          if (_items.isEmpty)
            AppEmptyView(
              icon: Icons.credit_card_outlined,
              title: 'Sin formas de pago registradas',
              subtitle: 'Aún no hay métodos configurados en el catálogo.',
              action: widget.onIrAInicio == null
                  ? null
                  : TextButton(
                      onPressed: widget.onIrAInicio,
                      child: const Text('Volver al catálogo'),
                    ),
            )
          else
            ..._items.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFFD81B60),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
