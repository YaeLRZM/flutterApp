import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/venta.dart';
import '../../../services/api_service.dart';
import '../../../services/articulo_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/app_ui.dart';

/// Informe de ventas del vendedor: solo métricas derivadas de ventas/productos reales.
/// Sin visitas, tendencias, conversión ni gráficos inventados.
class InformeVentasView extends StatefulWidget {
  const InformeVentasView({super.key});

  @override
  State<InformeVentasView> createState() => _InformeVentasViewState();
}

enum _PeriodoInforme { todas, hoy, semana, mes }

enum _EstadoInforme { todas, pendientes, completadas, canceladas }

class _InformeVentasViewState extends State<InformeVentasView> {
  static const Color primary = Color(0xFFD81B60);
  static const Color secondaryText = Color(0xFF5E6668);

  final _ventaService = VentaService();
  final _articuloService = ArticuloService();

  bool _loading = true;
  bool _reloading = false;
  bool _exporting = false;
  String? _error;

  String _tiendaNombre = 'Mi tienda';
  int? _tiendaId;
  List<Venta> _ventas = [];
  int _articulosActivos = 0;
  int _articulosTotal = 0;

  _PeriodoInforme _periodo = _PeriodoInforme.todas;
  _EstadoInforme _estado = _EstadoInforme.todas;

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _cargar();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _loading || _reloading || _exporting) return;
      _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
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
      final me = await ApiService().fetchMe();
      if (me['success'] != true || me['user'] is! Map) {
        throw Exception(
          me['message']?.toString() ?? 'No se pudo cargar la sesión',
        );
      }
      final user = Map<String, dynamic>.from(me['user'] as Map);
      var tiendaNombre = 'Mi tienda';
      var tiendaId = 0;
      final vendedorRaw = user['vendedor'];
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

      final ventasResult = await _ventaService.fetchMisVentas();
      var activos = 0;
      var totalProd = 0;
      if (tiendaId > 0) {
        final productos = await _articuloService.fetchArticulosPorTienda(
          tiendaId,
          limit: 100,
        );
        totalProd = productos.length;
        activos = productos.where((p) => p.disponible).length;
      }

      if (!mounted) return;
      setState(() {
        _tiendaNombre = tiendaNombre;
        _tiendaId = tiendaId > 0 ? tiendaId : null;
        _ventas = ventasResult.ventas;
        _articulosActivos = activos;
        _articulosTotal = totalProd;
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

  /// Rango de fechas aplicado (etiquetas de producto, no técnicas).
  String get _etiquetaPeriodo {
    switch (_periodo) {
      case _PeriodoInforme.todas:
        return 'Todas las fechas';
      case _PeriodoInforme.hoy:
        return 'Hoy';
      case _PeriodoInforme.semana:
        return 'Últimos 7 días';
      case _PeriodoInforme.mes:
        return 'Este mes';
    }
  }

  String get _etiquetaEstado {
    switch (_estado) {
      case _EstadoInforme.todas:
        return 'Todos los estados';
      case _EstadoInforme.pendientes:
        return 'Pendientes';
      case _EstadoInforme.completadas:
        return 'Completadas';
      case _EstadoInforme.canceladas:
        return 'Canceladas';
    }
  }

  bool _pasaPeriodo(Venta v) {
    if (_periodo == _PeriodoInforme.todas) return true;
    final created = v.createdAt?.toLocal();
    // Sin fecha real: no forzar semántica inventada en filtros temporales.
    if (created == null) return false;

    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    switch (_periodo) {
      case _PeriodoInforme.todas:
        return true;
      case _PeriodoInforme.hoy:
        return !created.isBefore(startToday);
      case _PeriodoInforme.semana:
        return !created.isBefore(startToday.subtract(const Duration(days: 6)));
      case _PeriodoInforme.mes:
        final startMonth = DateTime(now.year, now.month, 1);
        return !created.isBefore(startMonth);
    }
  }

  bool _pasaEstado(Venta v) {
    switch (_estado) {
      case _EstadoInforme.todas:
        return true;
      case _EstadoInforme.pendientes:
        return v.estadoClave == 'pendiente';
      case _EstadoInforme.completadas:
        return v.estadoClave == 'completada';
      case _EstadoInforme.canceladas:
        return v.estadoClave == 'cancelada';
    }
  }

  List<Venta> get _filtradas {
    final list = _ventas.where((v) => _pasaPeriodo(v) && _pasaEstado(v)).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  int get _nCompletadas =>
      _filtradas.where((v) => v.estadoClave == 'completada').length;

  int get _nPendientes =>
      _filtradas.where((v) => v.estadoClave == 'pendiente').length;

  int get _nCanceladas =>
      _filtradas.where((v) => v.estadoClave == 'cancelada').length;

  /// Solo ventas completadas del filtro actual.
  double get _totalVendido => _filtradas
      .where((v) => v.estadoClave == 'completada')
      .fold<double>(0, (acc, v) => acc + v.total);

  int get _ventasEfectivas => _nCompletadas;

  String _fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

  String _fmtDate(DateTime? d) {
    if (d == null) return 'No disponible';
    final l = d.toLocal();
    final dd = l.day.toString().padLeft(2, '0');
    final mm = l.month.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final mi = l.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${l.year} $hh:$mi';
  }

  String _fmtDateShort(DateTime? d) {
    if (d == null) return 'No disponible';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.year}';
  }

  Future<void> _exportarPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final ventas = _filtradas;
      final generacion = DateTime.now();
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (context) => [
            pw.Text(
              'Informe de ventas',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Tienda: $_tiendaNombre'),
            if (_tiendaId != null) pw.Text('Identificador de tienda: $_tiendaId'),
            pw.Text('Generado: ${_fmtDate(generacion)}'),
            pw.Text('Período: $_etiquetaPeriodo'),
            pw.Text('Filtro de estado: $_etiquetaEstado'),
            pw.SizedBox(height: 16),
            pw.Text(
              'Resumen',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Ventas completadas: $_nCompletadas'),
            pw.Text('Ventas pendientes: $_nPendientes'),
            pw.Text('Ventas canceladas: $_nCanceladas'),
            pw.Text(
              'Ventas efectivas (completadas): $_ventasEfectivas',
            ),
            pw.Text(
              'Total vendido (solo completadas): ${_fmtMoney(_totalVendido)}',
            ),
            if (_articulosTotal > 0) ...[
              pw.Text('Artículos en catálogo: $_articulosTotal'),
              pw.Text('Artículos publicados: $_articulosActivos'),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
              'Detalle de ventas (${ventas.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (ventas.isEmpty)
              pw.Text('No hay ventas en el período y filtro seleccionados.')
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Id',
                  'Estado',
                  'Total',
                  'Fecha',
                  'Artículos',
                ],
                data: [
                  for (final v in ventas)
                    [
                      '${v.id}',
                      v.estadoEtiqueta,
                      _fmtMoney(v.total),
                      _fmtDateShort(v.createdAt),
                      v.detalleCount > 0
                          ? '${v.detalleCount}'
                          : (v.lineas.isNotEmpty
                              ? '${v.lineas.length}'
                              : 'No disponible'),
                    ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                },
              ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Nota: el total vendido solo incluye ventas con estado Completada. '
              'Las canceladas y pendientes no se suman a ese total.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final nombreArchivo =
          'informe_ventas_${generacion.year}${generacion.month.toString().padLeft(2, '0')}${generacion.day.toString().padLeft(2, '0')}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe PDF listo para guardar o compartir')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Informe de ventas',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : () => _cargar(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoadingView();
    if (_error != null) {
      return AppErrorView(message: _error!, onRetry: () => _cargar());
    }

    final list = _filtradas;

    return RefreshIndicator(
      color: primary,
      onRefresh: () => _cargar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            _tiendaNombre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen con datos reales de tus ventas'
            '${_tiendaId != null ? ' · tienda #$_tiendaId' : ''}.',
            style: const TextStyle(fontSize: 13, color: secondaryText),
          ),
          const SizedBox(height: 16),

          const Text(
            'Período',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'Todas las fechas',
                _periodo == _PeriodoInforme.todas,
                () => setState(() => _periodo = _PeriodoInforme.todas),
              ),
              _chip(
                'Hoy',
                _periodo == _PeriodoInforme.hoy,
                () => setState(() => _periodo = _PeriodoInforme.hoy),
              ),
              _chip(
                'Últimos 7 días',
                _periodo == _PeriodoInforme.semana,
                () => setState(() => _periodo = _PeriodoInforme.semana),
              ),
              _chip(
                'Este mes',
                _periodo == _PeriodoInforme.mes,
                () => setState(() => _periodo = _PeriodoInforme.mes),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Estado',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'Todos',
                _estado == _EstadoInforme.todas,
                () => setState(() => _estado = _EstadoInforme.todas),
              ),
              _chip(
                'Pendientes',
                _estado == _EstadoInforme.pendientes,
                () => setState(() => _estado = _EstadoInforme.pendientes),
              ),
              _chip(
                'Completadas',
                _estado == _EstadoInforme.completadas,
                () => setState(() => _estado = _EstadoInforme.completadas),
              ),
              _chip(
                'Canceladas',
                _estado == _EstadoInforme.canceladas,
                () => setState(() => _estado = _EstadoInforme.canceladas),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            'Filtros: $_etiquetaPeriodo · $_etiquetaEstado',
            style: const TextStyle(fontSize: 12, color: secondaryText),
          ),
          const SizedBox(height: 12),

          // Métricas reales
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  'Completadas',
                  '$_nCompletadas',
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  'Pendientes',
                  '$_nPendientes',
                  const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  'Canceladas',
                  '$_nCanceladas',
                  const Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  'Efectivas',
                  '$_ventasEfectivas',
                  primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _metricTile(
            'Total vendido (solo completadas)',
            _fmtMoney(_totalVendido),
            const Color(0xFF1565C0),
            wide: true,
          ),
          if (_articulosTotal > 0) ...[
            const SizedBox(height: 10),
            _metricTile(
              'Artículos publicados',
              '$_articulosActivos de $_articulosTotal',
              const Color(0xFF8E24AA),
              wide: true,
            ),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _exportarPdf,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                _exporting ? 'Generando PDF…' : 'Exportar PDF',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Ventas del informe (${list.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const AppEmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'Sin ventas en este filtro',
              subtitle:
                  'Prueba otro período o estado. Los datos se actualizan con tus ventas reales.',
            )
          else
            ...list.map(_buildVentaRow),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? primary : const Color(0xFFE0D8D4),
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

  Widget _metricTile(
    String label,
    String value,
    Color accent, {
    bool wide = false,
  }) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
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
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildVentaRow(Venta v) {
    final articulos = v.detalleCount > 0
        ? '${v.detalleCount}'
        : (v.lineas.isNotEmpty ? '${v.lineas.length}' : 'No disponible');
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
          Row(
            children: [
              Text(
                'Venta #${v.id}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                v.estadoEtiqueta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: v.estadoClave == 'completada'
                      ? const Color(0xFF2E7D32)
                      : v.estadoClave == 'pendiente'
                          ? const Color(0xFFE65100)
                          : v.estadoClave == 'cancelada'
                              ? const Color(0xFF6D4C41)
                              : secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ${_fmtMoney(v.total)}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'Fecha: ${_fmtDate(v.createdAt)}',
            style: const TextStyle(fontSize: 12, color: secondaryText),
          ),
          Text(
            'Artículos: $articulos',
            style: const TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }
}
