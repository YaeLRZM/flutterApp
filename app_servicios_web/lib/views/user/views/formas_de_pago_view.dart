import 'package:flutter/material.dart';

import 'buyer_proxima_version_view.dart';

/// Formas de pago del comprador: no hay “mis tarjetas” / wallet real.
/// El checkout usa pago simulado sin guardar métodos.
class FormasDePagoView extends StatelessWidget {
  final VoidCallback? onIrAInicio;

  const FormasDePagoView({super.key, this.onIrAInicio});

  @override
  Widget build(BuildContext context) {
    return BuyerProximaVersionView(
      icon: Icons.credit_card_outlined,
      title: 'Formas de pago',
      subtitle: 'Sin wallet en esta versión',
      body:
          'Aún no puedes guardar tarjetas ni monederos en la app.\n\n'
          'Al comprar se usa un pago de prueba (sin cobro real). '
          'Guardar formas de pago estará disponible en una próxima versión.',
      primaryLabel: 'Volver al catálogo',
      onPrimary: onIrAInicio,
    );
  }
}
