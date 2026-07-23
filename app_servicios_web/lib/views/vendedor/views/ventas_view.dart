import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';

/// Filtro de listado (cuadros rápidos + chips).
/// Alineado con el panel admin: ventas reales, en proceso, devoluciones, etc.
/// [todas] incluye también estados vacíos o desconocidos.
enum _FiltroEstadoVenta {
  todas,
  /// Operaciones activas: sin canceladas ni devoluciones.
  ventas,
  /// Ingreso válido (misma lógica de monto: sin canceladas ni devueltas).
  monto,
  /// Flujo de pago aún no finalizado (no incluye devoluciones).
  enProceso,
  /// Solo efectivo pendiente de activar (acción del vendedor).
  activarEfectivo,
  entregadas,
  canceladas,
  /// En devolución + ya devueltas.
  devoluciones,
}

/// Mis ventas: misma entidad/API que las compras del comprador.
/// Muestra contador de confirmación automática cuando está pendiente.
class VentasView extends StatefulWidget {
  /// Si true, abre el filtro de pagos en efectivo por activar (desde notificaciones).
  final bool abrirActivarEfectivo;

  const VentasView({super.key, this.abrirActivarEfectivo = false});

  @override
  State<VentasView> createState() => _VentasViewState();
}

class _VentasViewState extends State<VentasView> {
  static const Color bugambilia = Color(0xFFD81B60);
  static const Color background = Color(0xFFF8F5F2);
  static const Color secondaryText = Color(0xFF5E6668);

  final _ventaService = VentaService();

  bool _loading = true;
  bool _reloading = false;
  String? _error;
  /// Listado completo de la API (sin filtrar).
  List<Venta> _ventas = [];
  late _FiltroEstadoVenta _filtro = widget.abrirActivarEfectivo
      ? _FiltroEstadoVenta.activarEfectivo
      : _FiltroEstadoVenta.todas;
  final Set<int> _busyActivateIds = {};

  /// Solo reconstruye textos de countdown (no toda la lista).
  final ValueNotifier<int> _clockTick = ValueNotifier<int>(0);
  Timer? _tick;
  Timer? _poll;

  @override
  void didUpdateWidget(covariant VentasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.abrirActivarEfectivo && !oldWidget.abrirActivarEfectivo) {
      setState(() => _filtro = _FiltroEstadoVenta.activarEfectivo);
    }
  }

  /// ¿Es una venta “real” (activa)? No cancelada ni en vía de devolución.
  static bool _esVentaActiva(Venta v) {
    const excluidos = {
      'cancelada',
      'cancelado',
      'devolucion_en_proceso',
      'devuelto',
    };
    final e = v.estadoClave;
    return e.isNotEmpty && !excluidos.contains(e);
  }

  static bool _esEnProceso(Venta v) {
    const estados = {
      'pendiente',
      'pendiente_activacion',
      'listo_pagar',
      'pago_acreditado',
      'en_curso',
    };
    return estados.contains(v.estadoClave);
  }

  static bool _esEntregada(Venta v) {
    final e = v.estadoClave;
    return e == 'entregado' || e == 'completada';
  }

  static bool _esCancelada(Venta v) {
    final e = v.estadoClave;
    return e == 'cancelada' || e == 'cancelado';
  }

  static bool _esDevolucion(Venta v) {
    final e = v.estadoClave;
    return e == 'devolucion_en_proceso' || e == 'devuelto';
  }

  /// Aplica el filtro de UI sobre el listado real de la API.
  /// Estados vacíos/desconocidos solo aparecen en [todas].
  List<Venta> get _ventasFiltradas {
    switch (_filtro) {
      case _FiltroEstadoVenta.todas:
        return _ventas;
      case _FiltroEstadoVenta.ventas:
        return _ventas.where(_esVentaActiva).toList();
      case _FiltroEstadoVenta.monto:
        // Mismas filas que suman en “Monto total”.
        return _ventas.where((v) => v.cuentaComoIngreso).toList();
      case _FiltroEstadoVenta.enProceso:
        return _ventas.where(_esEnProceso).toList();
      case _FiltroEstadoVenta.activarEfectivo:
        return _ventas.where((v) => v.sePuedeActivarEfectivo).toList();
      case _FiltroEstadoVenta.entregadas:
        return _ventas.where(_esEntregada).toList();
      case _FiltroEstadoVenta.canceladas:
        return _ventas.where(_esCancelada).toList();
      case _FiltroEstadoVenta.devoluciones:
        return _ventas.where(_esDevolucion).toList();
    }
  }

  int get _countFiltrado => _ventasFiltradas.length;

  /// Suma solo ingreso válido del subconjunto filtrado (sin canceladas/devueltas).
  double get _sumaFiltrada => _ventasFiltradas
      .where((v) => v.cuentaComoIngreso)
      .fold<double>(0, (acc, v) => acc + v.total);

  /// Conteos de cuadros: siempre sobre el listado completo (no el filtro activo),
  /// para que el número del cuadro coincida al hacer clic.
  int get _nVentas => _ventas.where(_esVentaActiva).length;

  double get _montoTotal => _ventas
      .where((v) => v.cuentaComoIngreso)
      .fold<double>(0, (acc, v) => acc + v.total);

  int get _nEnProceso => _ventas.where(_esEnProceso).length;

  int get _nActivarEfectivo =>
      _ventas.where((v) => v.sePuedeActivarEfectivo).length;

  int get _nEntregadas => _ventas.where(_esEntregada).length;

  int get _nCanceladas => _ventas.where(_esCancelada).length;

  int get _nDevoluciones => _ventas.where(_esDevolucion).length;

  bool get _hayFiltroActivo => _filtro != _FiltroEstadoVenta.todas;

  void _filtrarPorCuadro(_FiltroEstadoVenta grupo) {
    setState(() {
      // Toggle: segundo clic en el mismo cuadro quita el filtro.
      if (_filtro == grupo) {
        _filtro = _FiltroEstadoVenta.todas;
      } else {
        _filtro = grupo;
      }
    });
  }

  void _limpiarFiltros() {
    setState(() => _filtro = _FiltroEstadoVenta.todas);
  }

  @override
  void initState() {
    super.initState();
    _cargar();
    // Countdown y auto-refresh usan el listado completo (no el filtrado).
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final conTimer =
          _ventas.where((v) => v.debeMostrarContadorConfirmacion);
      if (conTimer.isEmpty) return;
      _clockTick.value = _clockTick.value + 1;
      if (conTimer.any((v) {
        final left = v.tiempoRestanteAutoCompletar;
        return left != null && left == Duration.zero;
      })) {
        _cargar(silencioso: true);
      }
    });
    // Backend completa vencidas al listar; polling captura compras nuevas y cambios.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _loading || _reloading) return;
      _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    _clockTick.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (_reloading) return;
    _reloading = true;
    if (!silencioso && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _ventaService.fetchMisVentas();
      if (!mounted) return;
      setState(() {
        _ventas = result.ventas;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso) {
        _reloading = false;
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _reloading = false;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase().trim()) {
      case 'pendiente':
      case 'pendiente_activacion':
      case 'listo_pagar':
        return const Color(0xFFE65100);
      case 'pago_acreditado':
        return const Color(0xFF1565C0);
      case 'en_curso':
        return const Color(0xFF6A1B9A);
      case 'cancelada':
      case 'cancelado':
        return const Color(0xFFC62828);
      case 'entregado':
      case 'completada':
        return const Color(0xFF2ECC71);
      case 'devolucion_en_proceso':
        return const Color(0xFF7B1FA2);
      case 'devuelto':
        return const Color(0xFF4527A0);
      default:
        return secondaryText;
    }
  }

  Future<void> _activarEfectivo(Venta v) async {
    if (_busyActivateIds.contains(v.id)) return;
    setState(() => _busyActivateIds.add(v.id));
    try {
      await _ventaService.activarEfectivo(v.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago en efectivo activado. El código ya está listo.'),
        ),
      );
      await _cargar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyActivateIds.remove(v.id));
    }
  }

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtDate(DateTime? d) {
    if (d == null) return 'No disponible';
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView();
    }

    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: () => _cargar());
    }

    final filtradas = _ventasFiltradas;

    return RefreshIndicator(
      color: bugambilia,
      onRefresh: () => _cargar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis ventas',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: bugambilia,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Toca un cuadro para filtrar. '
                      'Las pendientes se confirman solas en unos minutos.',
                      style: TextStyle(fontSize: 13, color: secondaryText),
                    ),
                  ],
                ),
              ),
              if (_hayFiltroActivo) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _limpiarFiltros,
                  style: TextButton.styleFrom(
                    foregroundColor: bugambilia,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Limpiar filtros',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Cuadros informativos = filtros rápidos (misma lógica que admin).
          // Conteos fijos del listado completo; el clic filtra el listado.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _summaryTile(
                label: 'Ventas',
                value: '$_nVentas',
                hint: 'Sin canceladas ni devoluciones',
                accent: bugambilia,
                selected: _filtro == _FiltroEstadoVenta.ventas,
                onTap: () => _filtrarPorCuadro(_FiltroEstadoVenta.ventas),
              ),
              _summaryTile(
                label: 'Monto total',
                value: _fmtMoney(_montoTotal),
                hint: 'Sin canceladas ni devueltas',
                accent: const Color(0xFF2ECC71),
                selected: _filtro == _FiltroEstadoVenta.monto,
                onTap: () => _filtrarPorCuadro(_FiltroEstadoVenta.monto),
              ),
              _summaryTile(
                label: 'Entregadas',
                value: '$_nEntregadas',
                hint: 'Completadas con éxito',
                accent: const Color(0xFF27AE60),
                selected: _filtro == _FiltroEstadoVenta.entregadas,
                onTap: () => _filtrarPorCuadro(_FiltroEstadoVenta.entregadas),
              ),
              _summaryTile(
                label: 'En proceso',
                value: '$_nEnProceso',
                hint: 'Aún no finalizan',
                accent: const Color(0xFFE67E22),
                selected: _filtro == _FiltroEstadoVenta.enProceso,
                onTap: () => _filtrarPorCuadro(_FiltroEstadoVenta.enProceso),
              ),
              _summaryTile(
                label: 'Canceladas',
                value: '$_nCanceladas',
                hint: 'Requieren atención',
                accent: const Color(0xFFE74C3C),
                selected: _filtro == _FiltroEstadoVenta.canceladas,
                onTap: () => _filtrarPorCuadro(_FiltroEstadoVenta.canceladas),
              ),
              _summaryTile(
                label: 'Devoluciones',
                value: '$_nDevoluciones',
                hint: 'En proceso y devueltas',
                accent: const Color(0xFF8E44AD),
                selected: _filtro == _FiltroEstadoVenta.devoluciones,
                onTap: () =>
                    _filtrarPorCuadro(_FiltroEstadoVenta.devoluciones),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chip extra del vendedor + acceso a “todas”.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filtroChip(
                  label: 'Todas (${_ventas.length})',
                  selected: _filtro == _FiltroEstadoVenta.todas,
                  onTap: () =>
                      setState(() => _filtro = _FiltroEstadoVenta.todas),
                ),
                const SizedBox(width: 8),
                _filtroChip(
                  label: 'Activar efectivo ($_nActivarEfectivo)',
                  selected: _filtro == _FiltroEstadoVenta.activarEfectivo,
                  onTap: () => setState(
                    () => _filtro = _FiltroEstadoVenta.activarEfectivo,
                  ),
                ),
                if (_hayFiltroActivo) ...[
                  const SizedBox(width: 8),
                  _filtroChip(
                    label: 'Limpiar filtros',
                    selected: false,
                    onTap: _limpiarFiltros,
                  ),
                ],
              ],
            ),
          ),
          if (_hayFiltroActivo) ...[
            const SizedBox(height: 10),
            Text(
              'Mostrando $_countFiltrado de ${_ventas.length} · '
              'suma visible ${_fmtMoney(_sumaFiltrada)}',
              style: const TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
          const SizedBox(height: 20),

          if (_ventas.isEmpty)
            const AppEmptyView(
              icon: Icons.inbox_outlined,
              title: 'Aún no hay ventas en tu tienda.',
              subtitle:
                  'Cuando un comprador complete una compra de tus productos, aparecerá aquí.',
            )
          else if (filtradas.isEmpty)
            AppEmptyView(
              icon: Icons.filter_list_off_outlined,
              title: 'No hay ventas con este filtro.',
              subtitle: _mensajeVacioFiltro(),
            )
          else
            ...filtradas.map(_buildVentaCard),
        ],
      ),
    );
  }

  String _mensajeVacioFiltro() {
    switch (_filtro) {
      case _FiltroEstadoVenta.activarEfectivo:
        return 'No hay pagos en efectivo por activar.';
      case _FiltroEstadoVenta.entregadas:
        return 'Aún no hay ventas entregadas.';
      case _FiltroEstadoVenta.canceladas:
        return 'No hay ventas canceladas.';
      case _FiltroEstadoVenta.devoluciones:
        return 'No hay devoluciones por ahora.';
      case _FiltroEstadoVenta.enProceso:
        return 'No hay ventas en proceso.';
      case _FiltroEstadoVenta.ventas:
        return 'No hay ventas activas (sin cancelar ni devolver).';
      case _FiltroEstadoVenta.monto:
        return 'No hay compras que sumen al monto total.';
      case _FiltroEstadoVenta.todas:
        return 'Prueba otro filtro o recarga la lista.';
    }
  }

  Widget _filtroChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? bugambilia : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? bugambilia : const Color(0xFFE0D8D4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required Color accent,
    String? hint,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: accent, width: 4),
              top: BorderSide(
                color: selected ? accent : const Color(0xFFE8E2DE),
                width: selected ? 1.5 : 1,
              ),
              right: BorderSide(
                color: selected ? accent : const Color(0xFFE8E2DE),
                width: selected ? 1.5 : 1,
              ),
              bottom: BorderSide(
                color: selected ? accent : const Color(0xFFE8E2DE),
                width: selected ? 1.5 : 1,
              ),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: selected ? accent : Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? accent.withValues(alpha: 0.85)
                        : Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalle(Venta v) async {
    await showModalBottomSheet<void>(
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
          child: _VentaDetalleSheet(
            ventaId: v.id,
            ventaService: _ventaService,
            clockTick: _clockTick,
          ),
        );
      },
    );
    // Al cerrar el detalle, refrescar por si cambió el estado.
    if (mounted) _cargar(silencioso: true);
  }

  Widget _buildVentaCard(Venta v) {
    final estado = v.estadoEtiqueta;
    final tieneEstado = v.estado.trim().isNotEmpty;
    final color = _estadoColor(v.estado);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirDetalle(v),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          key: ValueKey('venta_${v.id}_${v.estado}'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (tieneEstado ? color : secondaryText)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tieneEstado ? estado : 'No disponible',
                      style: TextStyle(
                        color: tieneEstado ? color : secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Venta #${v.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _fmtMoney(v.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: bugambilia,
                ),
              ),
              if (v.debeMostrarContadorConfirmacion) ...[
                const SizedBox(height: 10),
                _VentaCountdownChip(
                  venta: v,
                  clock: _clockTick,
                  esVendedor: true,
                ),
              ],
              if (v.esperaActivacionVendedor) ...[
                const SizedBox(height: 8),
                const Text(
                  'Pago en efectivo: espera tu activación',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _kv('Fecha', _fmtDate(v.createdAt)),
              if (v.userId > 0) _kv('Cliente', 'Cliente #${v.userId}'),
              _kv('Pago', v.metodoPagoEtiqueta),
              _kv(
                'Artículos',
                v.detalleCount > 0 ? '${v.detalleCount}' : '0',
              ),
              if (v.formaPagoId != null && v.formaPagoId! > 0)
                _kv('Forma de pago', v.etiquetaFormaPago),
              if (v.sePuedeActivarEfectivo) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busyActivateIds.contains(v.id)
                        ? null
                        : () => _activarEfectivo(v),
                    icon: _busyActivateIds.contains(v.id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_2, size: 18),
                    label: Text(
                      _busyActivateIds.contains(v.id)
                          ? 'Activando…'
                          : 'Activar pago en efectivo',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bugambilia,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                'Toca para ver detalle',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalle: GET /api/ventas/{id} (misma entidad que la compra del comprador).
class _VentaDetalleSheet extends StatefulWidget {
  final int ventaId;
  final VentaService ventaService;
  final ValueNotifier<int> clockTick;

  const _VentaDetalleSheet({
    required this.ventaId,
    required this.ventaService,
    required this.clockTick,
  });

  @override
  State<_VentaDetalleSheet> createState() => _VentaDetalleSheetState();
}

class _VentaDetalleSheetState extends State<_VentaDetalleSheet> {
  static const Color secondaryText = Color(0xFF5E6668);

  bool _loading = true;
  bool _reloading = false;
  String? _error;
  Venta? _venta;
  Timer? _poll;
  Timer? _expireWatch;

  @override
  void initState() {
    super.initState();
    _cargar();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || _reloading) return;
      final e = _venta?.estadoClave;
      if (e == null ||
          e == 'entregado' ||
          e == 'cancelada' ||
          e == 'cancelado') {
        return;
      }
      _cargar(silencioso: true);
    });
    _expireWatch = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _reloading) return;
      if (_venta?.debeMostrarContadorConfirmacion != true) return;
      final left = _venta?.tiempoRestanteAutoCompletar;
      if (left != null && left == Duration.zero) {
        _cargar(silencioso: true);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _expireWatch?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (_reloading) return;
    _reloading = true;
    if (!silencioso && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final v = await widget.ventaService.fetchVentaPorId(widget.ventaId);
      if (!mounted) return;
      setState(() {
        _venta = v;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso) {
        _reloading = false;
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _reloading = false;
    }
  }

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtDate(DateTime? d) {
    if (d == null) return 'No disponible';
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 14),
              Text(
                'Detalle de la venta #${widget.ventaId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoadingView(),
                )
              else if (_error != null)
                AppErrorView(message: _error!, onRetry: () => _cargar())
              else if (_venta == null)
                const AppEmptyView(
                  title: 'No disponible',
                  subtitle: 'No se pudo mostrar el detalle de esta venta.',
                )
              else
                _buildDetalle(_venta!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalle(Venta v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row('Venta', 'Venta #${v.id}'),
        _row('Estado', v.estadoEtiqueta),
        _row('Total', _fmtMoney(v.total)),
        _row('Fecha', _fmtDate(v.createdAt)),
        _row('Cliente', v.etiquetaCliente),
        _row('Forma de pago', v.etiquetaFormaPago),
        if (v.debeMostrarContadorConfirmacion) ...[
          const SizedBox(height: 12),
          _VentaCountdownChip(
            venta: v,
            clock: widget.clockTick,
            esVendedor: true,
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Artículos vendidos',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (v.lineas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No hay artículos en esta venta.',
              style: TextStyle(color: secondaryText, fontSize: 13),
            ),
          )
        else
          ...v.lineas.map(_buildLinea),
      ],
    );
  }

  Widget _buildLinea(DetalleVentaLinea line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.etiquetaArticulo,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          _row('Cantidad', '${line.cantidad}'),
          _row('Precio unitario', _fmtMoney(line.precioUnitario)),
          _row('Subtotal', _fmtMoney(line.subtotal)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contador visible: chip naranja + reloj; escucha [clock] cada segundo.
/// No depende de labels de rol para pintarse — solo de [Venta] pendiente.
class _VentaCountdownChip extends StatelessWidget {
  final Venta venta;
  final ValueNotifier<int> clock;
  final bool esVendedor;

  const _VentaCountdownChip({
    required this.venta,
    required this.clock,
    this.esVendedor = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: clock,
      builder: (context, tick, child) {
        // Forzar lectura de tick para que el builder no se elimine por lint
        // y recalcular restante con DateTime.now() en cada tick.
        final _ = tick;
        final msg = venta.mensajeTiempoConfirmacion(esVendedor: esVendedor);
        final display = msg.trim().isEmpty
            ? 'Se completará automáticamente'
            : msg;
        final reloj = venta.relojRestanteTexto;
        final esDevolucion = venta.esDevolucionEnProceso;
        final bg =
            esDevolucion ? const Color(0xFFF3E5F5) : const Color(0xFFFFF3E0);
        final border =
            esDevolucion ? const Color(0xFFCE93D8) : const Color(0xFFFFCC80);
        final fg =
            esDevolucion ? const Color(0xFF6A1B9A) : const Color(0xFFE65100);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.timer_outlined, size: 18, color: fg),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (esDevolucion)
                      Text(
                        'Tiempo restante de devolución',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                    Text(
                      display,
                      style: TextStyle(
                        fontSize: 12,
                        color: fg,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (reloj != null) ...[
                const SizedBox(width: 8),
                Text(
                  reloj,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
