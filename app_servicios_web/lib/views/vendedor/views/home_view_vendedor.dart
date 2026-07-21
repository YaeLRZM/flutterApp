import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';

/// Panel de vendedor: solo datos reales (me + productos + conteo de ventas).
/// Sin métricas inventadas. Accesos rápidos a módulos reales.
class HomeViewVendedor extends StatefulWidget {
  final VoidCallback? onIrAProductos;
  final VoidCallback? onIrAVentas;
  final VoidCallback? onIrATienda;

  const HomeViewVendedor({
    super.key,
    this.onIrAProductos,
    this.onIrAVentas,
    this.onIrATienda,
  });

  @override
  State<HomeViewVendedor> createState() => _HomeViewVendedorState();
}

class _HomeViewVendedorState extends State<HomeViewVendedor> {
  static const Color primaryColor = Color(0xFFD81B60);
  static const Color secondaryText = Color(0xFF5E6668);

  final _articuloService = ArticuloService();
  final _ventaService = VentaService();

  bool _loading = true;
  String? _error;
  String _userNombre = 'Vendedor';
  String _tiendaNombre = 'Mi tienda';
  int _totalProductos = 0;
  int _publicados = 0;
  int _ocultos = 0;
  int _totalVentas = 0;
  double _sumaVentas = 0;

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
          me['message']?.toString() ?? 'No se pudo cargar la sesión',
        );
      }

      final user = Map<String, dynamic>.from(me['user'] as Map);
      final nombre = user['nombre']?.toString().trim();
      final vendedorRaw = user['vendedor'];
      String tiendaNombre = 'Mi tienda';
      int tiendaId = 0;

      if (vendedorRaw is Map) {
        final vendedor = Map<String, dynamic>.from(vendedorRaw);
        final tiendaRaw = vendedor['tienda'];
        if (tiendaRaw is Map) {
          final tienda = Map<String, dynamic>.from(tiendaRaw);
          final n = tienda['nombre']?.toString().trim();
          if (n != null && n.isNotEmpty) tiendaNombre = n;
          tiendaId = tienda['id'] is int
              ? tienda['id'] as int
              : int.tryParse(tienda['id']?.toString() ?? '') ?? 0;
        }
      }

      var total = 0;
      var publicados = 0;
      if (tiendaId > 0) {
        final productos = await _articuloService.fetchArticulosPorTienda(
          tiendaId,
          limit: 100,
        );
        total = productos.length;
        publicados = productos.where((p) => p.disponible).length;
      }

      // Ventas de la tienda (scope backend = tienda del vendedor).
      var ventasCount = 0;
      var ventasSuma = 0.0;
      try {
        final ventas = await _ventaService.fetchMisVentas();
        ventasCount = ventas.count;
        ventasSuma = ventas.sumaTotales;
      } catch (_) {
        // No bloquear el panel si fallan ventas; se muestra 0 / reintentar global.
      }

      if (!mounted) return;
      setState(() {
        _userNombre =
            (nombre == null || nombre.isEmpty) ? 'Vendedor' : nombre;
        _tiendaNombre = tiendaNombre;
        _totalProductos = total;
        _publicados = publicados;
        _ocultos = total - publicados;
        _totalVentas = ventasCount;
        _sumaVentas = ventasSuma;
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

  void _proximaVersion(String feature) {
    AppUi.showProximamente(context, feature: feature);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: _cargar);
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, $_userNombre!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tienda: $_tiendaNombre',
              style: const TextStyle(
                fontSize: 14,
                color: secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Resumen con datos reales de catálogo y ventas de tu tienda.',
              style: TextStyle(fontSize: 13, color: secondaryText, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Accesos rápidos a módulos reales
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip(
                  label: 'Productos',
                  icon: Icons.inventory_2_outlined,
                  onTap: widget.onIrAProductos,
                ),
                _quickChip(
                  label: 'Ventas',
                  icon: Icons.receipt_long_outlined,
                  onTap: widget.onIrAVentas,
                ),
                _quickChip(
                  label: 'Mi tienda',
                  icon: Icons.storefront_outlined,
                  onTap: widget.onIrATienda,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildStatCard(
              title: 'PRODUCTOS',
              value: '$_totalProductos',
              subtitle: 'En tu tienda (incluye ocultos)',
              icon: Icons.inventory_2_outlined,
              iconBg: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF8E24AA),
              onTap: widget.onIrAProductos,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'PUBLICADOS',
              value: '$_publicados',
              subtitle: 'Visibles en el catálogo público',
              icon: Icons.visibility_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              onTap: widget.onIrAProductos,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'OCULTOS',
              value: '$_ocultos',
              subtitle: 'No aparecen en el catálogo público',
              icon: Icons.visibility_off_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFF57C00),
              onTap: widget.onIrAProductos,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'VENTAS',
              value: '$_totalVentas',
              subtitle:
                  'Suma totales: \$${_sumaVentas.toStringAsFixed(2)} (API tienda)',
              icon: Icons.receipt_long_outlined,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
              onTap: widget.onIrAVentas,
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () => _proximaVersion('Analítica'),
              borderRadius: BorderRadius.circular(16),
              child: _buildComingSoonCard(
                icon: Icons.bar_chart_outlined,
                title: 'Analítica',
                message:
                    'Próxima versión: visitas y tendencias (sin métricas inventadas).',
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Módulos listos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Productos — crear, editar, stock, publicar/ocultar, imagen URL\n'
                    '• Mi tienda — ver y editar nombre/descripción\n'
                    '• Ventas — listado y detalle por tienda',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _quickChip({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: primaryColor),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE0BEC6)),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0BEC6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}
