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
          'No se guardan tarjetas ni métodos de pago en la app.\n\n'
          'La compra usa un flujo de pago simulado (sin cobro real). '
          'Un monedero o tarjetas guardadas será próxima versión.\n\n'
          'No se muestran números de tarjeta ni wallets inventados.',
      primaryLabel: 'Volver al catálogo',
      onPrimary: onIrAInicio,
    );
  }
}
