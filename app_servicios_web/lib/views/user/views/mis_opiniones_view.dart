import 'package:flutter/material.dart';

import 'buyer_proxima_version_view.dart';

/// Mis opiniones: no hay endpoint confiable “reseñas solo mías”.
/// Las reseñas se publican desde el detalle de producto (API real).
class MisOpinionesView extends StatelessWidget {
  final VoidCallback? onIrAInicio;

  const MisOpinionesView({super.key, this.onIrAInicio});

  @override
  Widget build(BuildContext context) {
    return BuyerProximaVersionView(
      icon: Icons.rate_review_outlined,
      title: 'Mis opiniones',
      subtitle: 'Listado propio en próxima versión',
      body:
          'Puedes publicar reseñas desde el detalle de cada producto '
          '(calificación y comentario reales en el servidor).\n\n'
          'El historial de “solo mis reseñas” en esta pantalla llegará cuando '
          'el backend exponga un filtro fiable por usuario. No se muestran '
          'opiniones inventadas aquí.',
      primaryLabel: 'Explorar catálogo',
      onPrimary: onIrAInicio,
    );
  }
}
