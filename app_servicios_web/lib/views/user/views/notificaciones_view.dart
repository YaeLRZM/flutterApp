import 'package:flutter/material.dart';

import 'buyer_proxima_version_view.dart';

/// Notificaciones del comprador: sin backend de bandeja.
/// Placeholder honesto (no lista inventada, sin badges falsos).
class NotificacionesView extends StatelessWidget {
  final VoidCallback? onIrAInicio;
  final VoidCallback? onIrAMisCompras;

  const NotificacionesView({
    super.key,
    this.onIrAInicio,
    this.onIrAMisCompras,
  });

  @override
  Widget build(BuildContext context) {
    return BuyerProximaVersionView(
      icon: Icons.notifications_none_outlined,
      title: 'Notificaciones',
      subtitle: 'Bandeja aún no disponible',
      body:
          'Aquí verás avisos de compras y actividad cuando exista un sistema '
          'de notificaciones en el servidor.\n\n'
          'Hoy no hay mensajes reales que mostrar: no se inventan alertas ni conteos.',
      primaryLabel: 'Ir al catálogo',
      onPrimary: onIrAInicio,
      secondaryLabel: onIrAMisCompras != null ? 'Ver mis compras' : null,
      onSecondary: onIrAMisCompras,
    );
  }
}
