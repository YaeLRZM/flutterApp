import 'package:flutter/material.dart';
import 'views/welcome_screen.dart';

void main() {
  runApp(const IxeModaApp());
}

class IxeModaApp extends StatelessWidget {
  const IxeModaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ixé Moda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD81B60)),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(), // Iniciamos en la pantalla de bienvenida
    );
  }
}
