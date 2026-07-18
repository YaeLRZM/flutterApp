import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../user/user_layout.dart';
import '../vendedor/vendedor_layout.dart'; // Asegúrate de que la ruta sea correcta

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Controla el toggle: false = Usuario, true = Vendedor
  bool _isSeller = false;

  void _login() async {
  setState(() => _isLoading = true);

  final apiService = ApiService();
  final response = await apiService.login(
    _emailController.text.trim(),
    _passwordController.text.trim(),
  );

  setState(() => _isLoading = false);

  if (response['success'] == true) {
    final String userRole = (response['role'] ?? '').toString().toLowerCase().trim();

    // === BLOQUEO DE ADMIN ===
    if (userRole == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los administradores deben usar el panel web.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final bool isSellerActual = userRole == 'vendedor' || userRole.contains('seller');

    final bool isSellerExpected = _isSeller;

    // Validar que el toggle coincida con el rol real
    if (isSellerActual != isSellerExpected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSellerExpected
              ? 'Esta cuenta no es de vendedor.'
              : 'Esta cuenta es de vendedor. Selecciona "Vendedor".'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegación
    if (isSellerActual) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VendedorLayout()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserLayout()),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Error al iniciar sesión'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con imagen
          Image.asset('assets/images/fondoRosa.png', fit: BoxFit.cover),

          // Efecto de desenfoque
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),

          // Contenido centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF8F5F2).withOpacity(0.85),
                      const Color(0xFFFFE7CE).withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INICIAR SESIÓN',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- TOGGLE USUARIO / VENDEDOR ---
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSeller = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: !_isSeller
                                      ? const Color(0xFFD81B60)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Usuario',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: !_isSeller
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSeller = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: _isSeller
                                      ? const Color(0xFFD81B60)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Vendedor',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: _isSeller
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- FIN TOGGLE ---

                    const SizedBox(height: 25),

                    // Campo Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Correo electrónico',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        suffixIcon: const Icon(
                          Icons.mail_outline,
                          color: Colors.black54,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xFFD81B60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.lock_outline
                                : Icons.lock_open,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xFFD81B60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Recuérdame y Olvidé contraseña
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val!),
                              activeColor: const Color(0xFFD81B60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              'Recuérdame',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // Aquí puedes navegar a la pantalla de recuperación
                          },
                          child: Text(
                            'Olvidé mi contraseña',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Botón Ingresar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD81B60),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: const Color(0xFFD81B60).withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Ingresar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}