import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/local_session_store.dart';
import 'splash_screen.dart';
import 'views/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistencia local de carrito/favoritos (sobrevive recargas).
  await LocalSessionStore.ensureInitialized();

  // Si hay JWT válido, cargar carrito/favoritos del usuario.
  try {
    final api = ApiService();
    final token = await api.getToken();
    if (token != null) {
      final me = await api.fetchMe();
      if (me['success'] == true) {
        final uid = LocalSessionStore.userIdFromMap(me['user']);
        await LocalSessionStore.onAuthenticated(userId: uid);
      } else {
        await LocalSessionStore.onGuest();
      }
    }
  } catch (_) {
    // Sin red: se queda con carrito/favoritos de invitado ya cargados.
  }

  runApp(const IxeModaApp());
}

class IxeModaApp extends StatelessWidget {
  const IxeModaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ixé Moda',
      debugShowCheckedModeBanner: false,
      navigatorKey: ApiService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD81B60)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}
