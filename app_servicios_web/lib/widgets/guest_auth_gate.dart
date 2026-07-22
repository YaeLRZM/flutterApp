import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';

/// Comprueba si hay sesión JWT real.
Future<bool> hasActiveSession() async {
  final token = await ApiService().getToken();
  return token != null && token.trim().isNotEmpty;
}

/// Si no hay sesión, muestra aviso para iniciar sesión o registrarse.
/// Devuelve true si hay sesión y se puede continuar la acción de compra.
Future<bool> ensureLoggedInForPurchase(BuildContext context) async {
  if (await hasActiveSession()) return true;
  if (!context.mounted) return false;
  await showGuestPurchaseDialog(context);
  return false;
}

/// Modal claro para invitado que intenta comprar.
Future<void> showGuestPurchaseDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Inicia sesión para comprar',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Para comprar necesitas iniciar sesión o crear una cuenta.',
          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ahora no'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD81B60),
                  side: const BorderSide(color: Color(0xFFD81B60)),
                ),
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Registrarme'),
              ),
            ],
          ),
        ],
      );
    },
  );
}
