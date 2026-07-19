import 'package:flutter/material.dart';
import 'views/welcome_screen.dart'; // Ajusta la ruta según tu proyecto

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    print("Entré al Splash");

    Future.delayed(const Duration(seconds: 3), () {
      print("Ya pasaron 5 segundos");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Mismo color de fondo que el splash nativo
      body: Center(
        child: Image.asset(
          'assets/images/splash2.gif',
          fit: BoxFit.contain, // Ajusta según necesites
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
