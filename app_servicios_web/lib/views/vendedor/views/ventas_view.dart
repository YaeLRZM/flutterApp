import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/venta.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';

/// Filtro de listado: estados reales del flujo de pago simulado.
/// [todas] incluye también estados vacíos o desconocidos.
enum _FiltroEstadoVenta {
  todas,
  pendientes,
  activarEfectivo,
  enCurso,
  entregadas,
  canceladas,
}

/// Mis ventas: misma entidad/API que las compras del comprador.
/// Muestra contador de confirmación automática cuando está pendiente.
class VentasView extends StatefulWidget {
  const VentasView({super.key});

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
  int _count = 0;
  double _sumaTotales = 0;
  _FiltroEstadoVenta _filtro = _FiltroEstadoVenta.todas;
  final Set<int> _busyActivateIds = {};

  /// Solo reconstruye textos de countdown (no toda la lista).
  final ValueNotifier<int> _clockTick = ValueNotifier<int>(0);
  Timer? _tick;
  Timer? _poll;

  /// Aplica el filtro de UI sobre el listado real de la API.
  /// Estados vacíos/desconocidos solo aparecen en [todas].
  List<Venta> get _ventasFiltradas {
    switch (_filtro) {
      case _FiltroEstadoVenta.todas:
        return _ventas;
      case _FiltroEstadoVenta.pendientes:
        return _ventas
            .where(
              (v) =>
                  v.estadoClave == 'pendiente' ||
                  v.estadoClave == 'pendiente_activacion' ||
                  v.estadoClave == 'listo_pagar' ||
                  v.estadoClave == 'pago_acreditado',
            )
            .toList();
      case _FiltroEstadoVenta.activarEfectivo:
        return _ventas.where((v) => v.sePuedeActivarEfectivo).toList();
      case _FiltroEstadoVenta.enCurso:
        return _ventas.where((v) => v.estadoClave == 'en_curso').toList();
      case _FiltroEstadoVenta.entregadas:
        return _ventas.where((v) => v.estadoClave == 'entregado').toList();
      case _FiltroEstadoVenta.canceladas:
        return _ventas
            .where(
              (v) =>
                  v.estadoClave == 'cancelada' ||
                  v.estadoClave == 'cancelado',
            )
            .toList();
    }
  }

  int get _countFiltrado => _ventasFiltradas.length;

  double get _sumaFiltrada =>
      _ventasFiltradas.fold<double>(0, (acc, v) => acc + v.total);

  int get _nPendientes => _ventas
      .where(
        (v) =>
            v.estadoClave == 'pendiente' ||
            v.estadoClave == 'pendiente_activacion' ||
            v.estadoClave == 'listo_pagar' ||
            v.estadoClave == 'pago_acreditado',
      )
      .length;

  int get _nActivarEfectivo =>
      _ventas.where((v) => v.sePuedeActivarEfectivo).length;

  int get _nEntregadas =>
      _ventas.where((v) => v.estadoClave == 'entregado').length;

  int get _nCanceladas => _ventas
      .where(
        (v) =>
            v.estadoClave == 'cancelada' || v.estadoClave == 'cancelado',
      )
      .length;

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
        _count = result.count;
        _sumaTotales = result.sumaTotales;
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
        return const Color(0xFF6D4C41);
      case 'entregado':
        return const Color(0xFF2ECC71);
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
    // Contadores del resumen: con filtro activo reflejan el subconjunto visible.
    final countMostrado =
        _filtro == _FiltroEstadoVenta.todas ? _count : _countFiltrado;
    final sumaMostrada =
        _filtro == _FiltroEstadoVenta.todas ? _sumaTotales : _sumaFiltrada;

    return RefreshIndicator(
      color: bugambilia,
      onRefresh: () => _cargar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Text(
            'Mis ventas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: bugambilia,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ventas de tu tienda (mismas operaciones que ve el comprador). '
            'Las pendientes se confirman solas en unos minutos.',
            style: TextStyle(fontSize: 13, color: secondaryText),
          ),
          const SizedBox(height: 16),

          // Filtro por estado real de la API.
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
                  label: 'En proceso ($_nPendientes)',
                  selected: _filtro == _FiltroEstadoVenta.pendientes,
                  onTap: () =>
                      setState(() => _filtro = _FiltroEstadoVenta.pendientes),
                ),
                const SizedBox(width: 8),
                _filtroChip(
                  label: 'Activar efectivo ($_nActivarEfectivo)',
                  selected: _filtro == _FiltroEstadoVenta.activarEfectivo,
                  onTap: () => setState(
                    () => _filtro = _FiltroEstadoVenta.activarEfectivo,
                  ),
                ),
                const SizedBox(width: 8),
                _filtroChip(
                  label: 'Entregadas ($_nEntregadas)',
                  selected: _filtro == _FiltroEstadoVenta.entregadas,
                  onTap: () =>
                      setState(() => _filtro = _FiltroEstadoVenta.entregadas),
                ),
                const SizedBox(width: 8),
                _filtroChip(
                  label: 'Canceladas ($_nCanceladas)',
                  selected: _filtro == _FiltroEstadoVenta.canceladas,
                  onTap: () =>
                      setState(() => _filtro = _FiltroEstadoVenta.canceladas),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Conteo / suma del listado visible (filtrado o total).
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: _filtro == _FiltroEstadoVenta.todas
                      ? 'VENTAS'
                      : 'VENTAS (FILTRO)',
                  value: '$countMostrado',
                  accent: bugambilia,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  label: _filtro == _FiltroEstadoVenta.todas
                      ? 'SUMA DE TOTAL'
                      : 'SUMA (FILTRO)',
                  value: _fmtMoney(sumaMostrada),
                  accent: const Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
              title: 'No hay ventas con este estado.',
              subtitle: _filtro == _FiltroEstadoVenta.activarEfectivo
                  ? 'No hay pagos en efectivo por activar.'
                  : _filtro == _FiltroEstadoVenta.entregadas
                      ? 'Aún no hay ventas entregadas.'
                      : _filtro == _FiltroEstadoVenta.canceladas
                          ? 'No hay ventas canceladas.'
                          : 'Prueba otro filtro o recarga la lista.',
            )
          else
            ...filtradas.map(_buildVentaCard),
        ],
      ),
    );
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFCC80)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  display,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE65100),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (reloj != null) ...[
                const SizedBox(width: 8),
                Text(
                  reloj,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65100),
                    fontFeatures: [FontFeature.tabularFigures()],
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
