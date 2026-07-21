import 'package:flutter/material.dart';

import '../../../widgets/app_ui.dart';

/// Alias de comprador sobre [AppProximaVersionView] (consistencia transversal).
class BuyerProximaVersionView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final VoidCallback? onPrimary;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;

  const BuyerProximaVersionView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.icon = Icons.hourglass_empty_outlined,
    this.onPrimary,
    this.primaryLabel = 'Ir al catálogo',
    this.onSecondary,
    this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppProximaVersionView(
      title: title,
      subtitle: subtitle,
      body: body,
      icon: icon,
      onPrimary: onPrimary,
      primaryLabel: primaryLabel,
      onSecondary: onSecondary,
      secondaryLabel: secondaryLabel,
    );
  }
}
