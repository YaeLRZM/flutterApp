import 'package:flutter/material.dart';

import '../../../models/articulo.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/tienda_service.dart';

/// Mi tienda del vendedor: lectura real + edición mínima (nombre/descripción).
class TiendaView extends StatefulWidget {
  const TiendaView({super.key});

  @override
  State<TiendaView> createState() => _TiendaViewState();
}

class _TiendaViewState extends State<TiendaView> {
  static const Color colorBugambilia = Color(0xFFD81B60);
  static const Color colorFondoMarfil = Color(0xFFF8F5F2);
  static const Color colorSuperficie = Colors.white;
  static const Color colorTextoSecundario = Color(0xFF5E6668);

  final _articuloService = ArticuloService();
  final _tiendaService = TiendaService();

  bool _loading = true;
  String? _error;

  int? _tiendaId;
  String _nombre = 'Mi tienda';
  String? _descripcion;
  String? _rfc;
  String? _estatusVendedor;
  int _totalProductos = 0;
  int _publicados = 0;
  List<Articulo> _previewProductos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final me = await ApiService().fetchMe();
      if (me['success'] != true || me['user'] is! Map) {
        throw Exception(
          me['message']?.toString() ?? 'No se pudo cargar la sesión del vendedor',
        );
      }

      final user = Map<String, dynamic>.from(me['user'] as Map);
      final vendedorRaw = user['vendedor'];
      if (vendedorRaw is! Map) {
        throw Exception(
          'Esta cuenta no tiene perfil de vendedor vinculado a una tienda.',
        );
      }
      final vendedor = Map<String, dynamic>.from(vendedorRaw);
      final tiendaRaw = vendedor['tienda'];
      if (tiendaRaw is! Map) {
        throw Exception('El vendedor no tiene tienda asignada.');
      }
      final tienda = Map<String, dynamic>.from(tiendaRaw);

      final tiendaId = tienda['id'] is int
          ? tienda['id'] as int
          : int.tryParse(tienda['id']?.toString() ?? '') ?? 0;
      if (tiendaId <= 0) {
        throw Exception('Tienda inválida para este vendedor.');
      }

      final nombre = tienda['nombre']?.toString().trim();
      final descripcion = tienda['descripcion']?.toString().trim();
      final rfc = tienda['rfc_moral']?.toString().trim();
      final estatus = vendedor['estatus']?.toString().trim();

      // Contador + preview liviano (reutiliza el mismo endpoint de Mis productos).
      final productos = await _articuloService.fetchArticulosPorTienda(
        tiendaId,
        limit: 100,
      );
      final publicados = productos.where((p) => p.disponible).length;

      if (!mounted) return;
      setState(() {
        _tiendaId = tiendaId;
        _nombre = (nombre == null || nombre.isEmpty) ? 'Mi tienda' : nombre;
        _descripcion =
            (descripcion == null || descripcion.isEmpty) ? null : descripcion;
        _rfc = (rfc == null || rfc.isEmpty) ? null : rfc;
        _estatusVendedor =
            (estatus == null || estatus.isEmpty) ? null : estatus;
        _totalProductos = productos.length;
        _publicados = publicados;
        _previewProductos = productos.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _abrirEdicion() async {
    final tiendaId = _tiendaId;
    if (tiendaId == null || tiendaId <= 0) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: _EditarTiendaSheet(
            tiendaId: tiendaId,
            nombre: _nombre,
            descripcion: _descripcion ?? '',
            tiendaService: _tiendaService,
          ),
        );
      },
    );

    if (!mounted || saved != true) return;
    await _cargar();
    if (!mounted) return;
    messenger?.showSnackBar(
      const SnackBar(content: Text('Tienda actualizada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondoMarfil,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_outlined, size: 48, color: Colors.black38),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: colorTextoSecundario),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBugambilia,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colorBugambilia,
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _abrirEdicion,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar tienda'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorBugambilia,
                        side: const BorderSide(color: colorBugambilia),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTarjetaInfo(),
                  const SizedBox(height: 16),
                  _buildMetricas(),
                  const SizedBox(height: 28),
                  const Text(
                    'Productos de tu tienda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorBugambilia,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vista rápida (gestión completa en Mis productos)',
                    style: TextStyle(fontSize: 12, color: colorTextoSecundario),
                  ),
                  const SizedBox(height: 12),
                  _buildListaPreview(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final initial = _nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'T';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD81B60), Color(0xFFAD1457)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colorBugambilia,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi tienda',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (_tiendaId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID tienda · $_tiendaId',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre la tienda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorBugambilia,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _descripcion ??
                'Aún no hay descripción para esta tienda. Usa «Editar tienda» para agregar una.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _descripcion == null
                  ? colorTextoSecundario.withValues(alpha: 0.8)
                  : colorTextoSecundario,
              fontStyle:
                  _descripcion == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_rfc != null) _buildChip('RFC · $_rfc', const Color(0xFF10b981)),
              if (_estatusVendedor != null)
                _buildChip(
                  'Estatus · $_estatusVendedor',
                  colorBugambilia,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorTextoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricas() {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaMetrica(
            Icons.shopping_bag_outlined,
            '$_totalProductos',
            'PRODUCTOS',
            colorBugambilia,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTarjetaMetrica(
            Icons.visibility_outlined,
            '$_publicados',
            'PUBLICADOS',
            const Color(0xFF10b981),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaMetrica(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorBugambilia,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: colorTextoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaPreview() {
    if (_previewProductos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorSuperficie,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Todavía no tienes productos en esta tienda.\nCrea el primero desde Mis productos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colorTextoSecundario, height: 1.4),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _previewProductos.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildFilaProducto(_previewProductos[i]),
        ],
      ],
    );
  }

  Widget _buildFilaProducto(Articulo a) {
    final hasImg = a.imagenUrl.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorSuperficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: hasImg
                  ? Image.network(
                      a.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE8E8E8)),
                    )
                  : const ColoredBox(color: Color(0xFFE8E8E8)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nombre.isEmpty ? 'Producto #${a.id}' : a.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${a.precio.toStringAsFixed(2)} · '
                  '${a.disponible ? 'Publicado' : 'Oculto'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: colorTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet mínimo: nombre + descripción de la tienda del vendedor.
class _EditarTiendaSheet extends StatefulWidget {
  final int tiendaId;
  final String nombre;
  final String descripcion;
  final TiendaService tiendaService;

  const _EditarTiendaSheet({
    required this.tiendaId,
    required this.nombre,
    required this.descripcion,
    required this.tiendaService,
  });

  @override
  State<_EditarTiendaSheet> createState() => _EditarTiendaSheetState();
}

class _EditarTiendaSheetState extends State<_EditarTiendaSheet> {
  static const Color primaryColor = Color(0xFFD81B60);

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombre);
    _descCtrl = TextEditingController(text: widget.descripcion);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_saving || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la tienda es obligatorio')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'nombre': nombre,
      'descripcion': _descCtrl.text.trim(),
    };

    setState(() => _saving = true);
    try {
      await widget.tiendaService.updateTienda(widget.tiendaId, payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Editar tienda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Solo nombre y descripción · #${widget.tiendaId}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Descripción',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El RFC no se edita aquí. Solo tu tienda asignada.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _saving ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
