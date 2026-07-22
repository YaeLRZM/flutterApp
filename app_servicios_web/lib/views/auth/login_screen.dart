import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/local_session_store.dart';
import '../../widgets/app_ui.dart';
import '../user/user_layout.dart';
import '../user/views/product_detail_view.dart';
import '../vendedor/vendedor_layout.dart';
import 'vendedor_identidad_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Página del layout de comprador tras un login exitoso (ej. 'cart').
  final String? returnPage;

  /// Si se llegó desde un producto concreto, regresar a su detalle tras login.
  final int? returnArticuloId;

  const LoginScreen({
    super.key,
    this.returnPage,
    this.returnArticuloId,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _checkingSession = true;
  /// Preferencia de UI: el rol real lo define el backend tras login.
  bool _isSeller = false;

  @override
  void initState() {
    super.initState();
    _tryRestoreSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Catálogo como invitado sin forzar inicio de sesión (sin bucles).
  void _empezarComoInvitado() {
    if (_isLoading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UserLayout()),
    );
  }

  /// Si hay JWT local y /api/me responde, entra al layout del rol real.
  Future<void> _tryRestoreSession() async {
    final api = ApiService();
    final token = await api.getToken();
    if (token == null) {
      if (mounted) setState(() => _checkingSession = false);
      return;
    }

    final me = await api.fetchMe();
    if (!mounted) return;

    if (me['success'] != true) {
      // Token inválido/expirado: limpia y muestra el formulario.
      await api.clearToken();
      await LocalSessionStore.onGuest();
      if (mounted) setState(() => _checkingSession = false);
      return;
    }

    final user = me['user'];
    final role = ApiService.normalizeRole(
      me['role']?.toString() ?? ApiService.roleFromUserMap(user),
    );

    if (role == 'admin') {
      await api.clearToken();
      await LocalSessionStore.onGuest();
      if (mounted) setState(() => _checkingSession = false);
      return;
    }

    await api.saveRole(role);
    await LocalSessionStore.onAuthenticated(
      userId: LocalSessionStore.userIdFromMap(user),
    );

    final isSeller = ApiService.isVendedorRoleName(role);
    if (!mounted) return;
    await _navigateAfterAuth(isSeller: isSeller);
  }

  void _loginWithGoogle() {
    AppUi.showProximamente(context, feature: 'Login con Google');
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _requestSeller() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendedorIdentidadScreen()),
    );
  }

  void _forgotPassword() {
    AppUi.showProximamente(context, feature: 'Recuperar contraseña');
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Ingresa tu correo';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) return 'Correo no válido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  /// Tras autenticación válida: comprador con contexto de compra o panel vendedor.
  Future<void> _navigateAfterAuth({required bool isSeller}) async {
    if (!mounted) return;

    if (isSeller) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendedorLayout()),
        (route) => false,
      );
      return;
    }

    final page = (widget.returnPage != null && widget.returnPage!.isNotEmpty)
        ? widget.returnPage!
        : 'home';
    final articuloId = widget.returnArticuloId;

    // Continuidad: layout de comprador y, si venía de un artículo, su detalle.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (routeContext) {
          if (articuloId != null && articuloId > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!routeContext.mounted) return;
              Navigator.of(routeContext).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailView(articuloId: articuloId),
                ),
              );
            });
          }
          return UserLayout(initialPage: page);
        },
      ),
      (route) => false,
    );
  }

  /// Aviso amable si la pestaña no coincide con el tipo real de cuenta.
  /// Opción estable: Cambiar ajusta la pestaña y continúa el acceso;
  /// Cancelar deshace la sesión recién creada para que pueda corregir.
  Future<bool> _confirmRoleTabMismatch({required bool isSellerActual}) async {
    final esVendedor = isSellerActual;
    final mensaje = esVendedor
        ? 'Esta cuenta corresponde a vendedor. Cambia a la pestaña de vendedor para continuar.'
        : 'Esta cuenta corresponde a usuario. Cambia a la pestaña de usuario para continuar.';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pestaña incorrecta',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            mensaje,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.dmSans(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Cambiar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiService = ApiService();
    final response = await apiService.login(
      _emailController.text.trim(),
      _passwordController.text, // no trim: la contraseña es literal
    );

    if (!mounted) return;

    if (response['success'] != true) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Error al iniciar sesión',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final String userRole = ApiService.normalizeRole(
      response['role']?.toString() ??
          ApiService.roleFromUserMap(response['user']),
    );

    if (userRole == 'admin') {
      // Backend ya bloquea admin (403); por si llega token residual.
      await apiService.clearToken();
      await LocalSessionStore.onGuest();
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los administradores deben usar el panel web.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final bool isSellerActual = ApiService.isVendedorRoleName(userRole);

    // Verificación de pestaña: no entrar en silencio si no coincide.
    if (isSellerActual != _isSeller) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final accepted = await _confirmRoleTabMismatch(
        isSellerActual: isSellerActual,
      );
      if (!mounted) return;

      if (!accepted) {
        // Cancelar: deshacer sesión para no dejar al usuario a medias.
        await apiService.clearToken();
        await LocalSessionStore.onGuest();
        if (!mounted) return;
        setState(() => _isSeller = isSellerActual);
        return;
      }

      // Cambiar: alinear pestaña y continuar el acceso con el rol real.
      setState(() {
        _isSeller = isSellerActual;
        _isLoading = true;
      });
    }

    await apiService.saveRole(userRole);
    await LocalSessionStore.onAuthenticated(
      userId: LocalSessionStore.userIdFromMap(response['user']),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    await _navigateAfterAuth(isSeller: isSellerActual);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F5F2),
        body: AppLoadingView(),
      );
    }

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
          Image.asset('assets/images/fondoRosa.png', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
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
                child: Form(
                  key: _formKey,
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

                      // Toggle Usuario / Vendedor (preferencia de UI; rol = backend)
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
                                onTap: _isLoading
                                    ? null
                                    : () => setState(() => _isSeller = false),
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
                                onTap: _isLoading
                                    ? null
                                    : () => setState(() => _isSeller = true),
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
                      const SizedBox(height: 8),
                      Text(
                        'Elige la pestaña según tu tipo de cuenta.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: GoogleFonts.poppins(fontSize: 14),
                        validator: _validateEmail,
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
                          errorStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _login(),
                        style: GoogleFonts.poppins(fontSize: 14),
                        validator: _validatePassword,
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
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
                          errorStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _forgotPassword,
                          child: Text(
                            'Olvidé mi contraseña',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                            shadowColor:
                                const Color(0xFFD81B60).withOpacity(0.5),
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
                      const SizedBox(height: 12),

                      // Empezar = explorar catálogo sin cuenta (misma idea que welcome).
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _empezarComoInvitado,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD81B60),
                            side: const BorderSide(
                              color: Color(0xFFD81B60),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Empezar',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD81B60),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Explora el catálogo sin iniciar sesión',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      if (!_isSeller) ...[
                        GestureDetector(
                          onTap: _isLoading ? null : _loginWithGoogle,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.string(
                                  '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                                  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                                  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                                  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                                </svg>''',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continuar con Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Google: próxima versión',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Aún no tienes cuenta? ',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : _goToRegister,
                              child: Text(
                                'Registrarse',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: const Color(0xFFD81B60),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '¿Aún no eres un vendedor?',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _isLoading ? null : _requestSeller,
                                child: Text(
                                  'Solicítalo AQUÍ',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14.5,
                                    color: const Color(0xFFD81B60),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
