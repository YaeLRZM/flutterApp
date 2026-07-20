import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/data_config.dart';
import 'auth/login_screen.dart';
import 'user/user_layout.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    // Recreamos el keyframe 'float' de 6 segundos
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.05), // Sube un poco
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset('assets/images/fondoWel.png', fit: BoxFit.cover),
          // Filtros oscuros (gradiente)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFD81B60).withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Contenido Principal (scrollable: evita overflow en viewports bajos/estrechos)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 8),
                        // Contenedor Animado
                        SlideTransition(
                          position: _animation,
                          child: Column(
                            children: [
                              Text(
                                'IXÉ\nMODA',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cinzel(
                                  fontSize: 60,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 4.0,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Historia en cada hilo',
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Botón Empezar
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD81B60),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(
                                      0xFFD81B60,
                                    ).withOpacity(0.4),
                                  ),
                                  child: const Text(
                                    'Empezar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Botón Iniciar Sesión — contraste alto sobre fondo rosa
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.15,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Acceso rápido de desarrollo: entra sin login
                              // mientras se trabaja con datos mock (kUseMockData).
                              // TODO: quitar este botón antes de conectar la API real.
                              if (kUseMockData) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const UserLayout(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Entrar sin login (modo prueba)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                          child: Text(
                            'HERENCIA • ELEGANCIA • DISEÑO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
