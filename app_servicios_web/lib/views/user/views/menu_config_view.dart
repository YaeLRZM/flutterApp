import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../services/local_session_store.dart';
import '../../../widgets/app_ui.dart';

/// Perfil / configuración: datos reales de GET /api/me, edición con PUT /api/me.
/// El rol es solo lectura (no se envía ni se puede cambiar desde la app).
class MenuConfigView extends StatefulWidget {
  const MenuConfigView({super.key});

  @override
  State<MenuConfigView> createState() => _MenuConfigViewState();
}

class _MenuConfigViewState extends State<MenuConfigView> {
  static const Color bugambilia = Color(0xFFD81B60);

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String _rol = '';
  String? _profileHint;

  final _nombreCtrl = TextEditingController();
  final _apCtrl = TextEditingController();
  final _amCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  final _fotoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apCtrl.dispose();
    _amCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _dirCtrl.dispose();
    _fotoCtrl.dispose();
    super.dispose();
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
      _applyUser(user);
      setState(() {
        _loading = false;
        _editing = false;
      });
    } else {
      setState(() {
        _profileHint =
            (result['message'] ?? 'No se pudo cargar el perfil').toString();
        _loading = false;
      });
    }
  }

  void _applyUser(Map<String, dynamic> user) {
    _nombreCtrl.text = (user['nombre'] ?? '').toString();
    _apCtrl.text = (user['apellido_paterno'] ?? '').toString();
    _amCtrl.text = (user['apellido_materno'] ?? '').toString();
    _emailCtrl.text = (user['email'] ?? '').toString();
    _telCtrl.text = (user['telefono'] ?? '').toString();
    _dirCtrl.text = (user['direccion'] ?? '').toString();
    _fotoCtrl.text = (user['foto_url'] ?? '').toString();
    _rol = (user['rol'] ?? '').toString().trim();
  }

  String get _displayName {
    final full = [
      _nombreCtrl.text.trim(),
      _apCtrl.text.trim(),
      _amCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : 'Usuario Ixé';
  }

  Future<void> _guardar() async {
    if (_saving) return;
    if (_nombreCtrl.text.trim().isEmpty || _apCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y apellido paterno son obligatorios'),
        ),
      );
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El correo es obligatorio')),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await ApiService().updateProfile(
      nombre: _nombreCtrl.text.trim(),
      apellidoPaterno: _apCtrl.text.trim(),
      apellidoMaterno: _amCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telefono: _telCtrl.text.trim(),
      direccion: _dirCtrl.text.trim(),
      fotoUrl: _fotoCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      if (result['user'] is Map) {
        _applyUser(Map<String, dynamic>.from(result['user'] as Map));
      }
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Perfil actualizado'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'No se pudo guardar',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingView();
    }

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
                        backgroundImage: _fotoCtrl.text.trim().startsWith('http')
                            ? NetworkImage(_fotoCtrl.text.trim())
                            : null,
                        onBackgroundImageError: _fotoCtrl.text.trim().startsWith('http')
                            ? (_, __) {}
                            : null,
                        child: _fotoCtrl.text.trim().startsWith('http')
                            ? null
                            : Text(
                                _displayName.isNotEmpty
                                    ? _displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailCtrl.text.isEmpty
                            ? 'Sin correo'
                            : _emailCtrl.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () {
                            if (_editing) {
                              _loadProfile();
                            } else {
                              setState(() => _editing = true);
                            }
                          },
                    icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                    label: Text(_editing ? 'Cancelar edición' : 'Editar perfil'),
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTitle('DATOS DE CUENTA'),
                const SizedBox(height: 10),
                _card(
                  children: [
                    if (_editing) ...[
                      _field('Nombre', _nombreCtrl),
                      _field('Apellido paterno', _apCtrl),
                      _field('Apellido materno', _amCtrl, optional: true),
                      _field(
                        'Correo',
                        _emailCtrl,
                        keyboard: TextInputType.emailAddress,
                      ),
                      _field(
                        'Teléfono',
                        _telCtrl,
                        optional: true,
                        keyboard: TextInputType.phone,
                      ),
                      _field('Dirección', _dirCtrl, optional: true),
                      _field(
                        'Foto (enlace de imagen)',
                        _fotoCtrl,
                        optional: true,
                        keyboard: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bugambilia,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _saving ? 'Guardando…' : 'Guardar cambios',
                          ),
                        ),
                      ),
                    ] else ...[
                      _infoRow('Nombre', _displayName),
                      const Divider(height: 1),
                      _infoRow(
                        'Correo',
                        _emailCtrl.text.isEmpty
                            ? 'No disponible'
                            : _emailCtrl.text,
                      ),
                      const Divider(height: 1),
                      _infoRow(
                        'Teléfono',
                        _telCtrl.text.isEmpty
                            ? 'No indicado'
                            : _telCtrl.text,
                      ),
                      const Divider(height: 1),
                      _infoRow(
                        'Dirección',
                        _dirCtrl.text.isEmpty
                            ? 'No indicada'
                            : _dirCtrl.text,
                      ),
                      const Divider(height: 1),
                      _infoRow(
                        'Rol',
                        _rolLabel,
                      ),
                    ],
                  ],
                ),
                if (_editing) ...[
                  const SizedBox(height: 10),
                  _card(
                    children: [
                      _infoRow('Rol', _rolLabel),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          'Tu rol no se puede cambiar desde el perfil.',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _sectionTitle('CUENTA'),
                const SizedBox(height: 10),
                _card(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: bugambilia),
                      title: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _rolLabel {
    switch (_rol.toLowerCase()) {
      case 'user':
        return 'Comprador';
      case 'vendedor':
        return 'Vendedor';
      case 'admin':
        return 'Administrador';
      default:
        return _rol.isEmpty ? 'No disponible' : _rol;
    }
  }

  Widget _sectionTitle(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Colors.black54,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool optional = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: optional ? '$label (opcional)' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}
