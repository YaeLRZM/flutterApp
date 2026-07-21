import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../services/local_session_store.dart';
import '../../../widgets/app_ui.dart';

/// Configuración / perfil del comprador: datos reales de GET /api/me en
/// solo lectura. Edición de perfil y extras = próxima versión.
class MenuConfigView extends StatefulWidget {
  const MenuConfigView({super.key});

  @override
  State<MenuConfigView> createState() => _MenuConfigViewState();
}

class _MenuConfigViewState extends State<MenuConfigView> {
  static const Color bugambilia = Color(0xFFD81B60);

  bool _loading = true;
  String _displayName = 'Usuario Ixé';
  String _email = '';
  String _rol = '';
  String? _profileHint;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _profileHint = null;
    });

    final result = await ApiService().fetchMe();
    if (!mounted) return;

    if (result['success'] == true && result['user'] is Map) {
      final user = Map<String, dynamic>.from(result['user'] as Map);
      final nombre = (user['nombre'] ?? '').toString().trim();
      final ap = (user['apellido_paterno'] ?? '').toString().trim();
      final am = (user['apellido_materno'] ?? '').toString().trim();
      final full = [nombre, ap, am].where((s) => s.isNotEmpty).join(' ');
      final rol = (user['rol'] ?? '').toString().trim();
      setState(() {
        _displayName = full.isNotEmpty ? full : 'Usuario Ixé';
        _email = (user['email'] ?? '').toString();
        _rol = rol;
        _loading = false;
      });
    } else {
      setState(() {
        _displayName = 'Usuario Ixé';
        _email = '';
        _rol = '';
        _profileHint =
            (result['message'] ?? 'No se pudo cargar el perfil').toString();
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    await ApiService().logout();
    await LocalSessionStore.onGuest();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _proximaVersion(String feature) {
    AppUi.showProximamente(context, feature: feature);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: RefreshIndicator(
          color: bugambilia,
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey.shade300,
                        child: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: bugambilia,
                                ),
                              )
                            : Text(
                                _displayName.isNotEmpty
                                    ? _displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: bugambilia,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email.isEmpty ? 'Sin email cargado' : _email,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      if (_rol.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bugambilia.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Rol: $_rol',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: bugambilia,
                            ),
                          ),
                        ),
                      ],
                      if (_profileHint != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _profileHint!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Perfil en consulta · la edición llegará pronto',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _sectionTitle('DATOS DE CUENTA'),
                const SizedBox(height: 10),
                _card(
                  children: [
                    _infoRow('Nombre', _displayName),
                    const Divider(height: 1),
                    _infoRow(
                      'Correo',
                      _email.isEmpty ? 'No disponible' : _email,
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      'Rol',
                      _rol.isEmpty ? 'No disponible' : _rol,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('PRÓXIMA VERSIÓN'),
                const SizedBox(height: 10),
                _card(
                  children: [
                    _tappableRow(
                      icon: Icons.edit_outlined,
                      title: 'Editar perfil',
                      subtitle: 'Nombre, foto y datos de contacto',
                      onTap: () => _proximaVersion('Editar perfil'),
                    ),
                    const Divider(height: 1),
                    _tappableRow(
                      icon: Icons.lock_outline,
                      title: 'Seguridad',
                      subtitle: 'Contraseña y dispositivos',
                      onTap: () => _proximaVersion('Seguridad'),
                    ),
                    const Divider(height: 1),
                    _tappableRow(
                      icon: Icons.location_on_outlined,
                      title: 'Direcciones',
                      subtitle: 'Envíos aún no disponibles en la app',
                      onTap: () => _proximaVersion('Direcciones'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: bugambilia),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: bugambilia,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: bugambilia, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ixé Moda · perfil de comprador',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: bugambilia, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Text(
              'Próxima',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
