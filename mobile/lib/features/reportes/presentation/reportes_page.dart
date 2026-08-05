import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/reportes_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../inventario/presentation/inventario_providers.dart';
import 'reportes_providers.dart';

/// Reportes.
///
/// **Se calculan en el dispositivo**, con SQL sobre la base local. No son una
/// caché de lo que devuelve el servidor: por eso funcionan en modo avión, que
/// es justo cuando el dueño quiere saber cuánto lleva vendido en el día.
class ReportesPage extends ConsumerWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoReporteProvider);
    final resumen = ref.watch(resumenReporteProvider);
    final esAdmin = ref.watch(esAdminProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Text('Reportes', style: context.textos.headlineSmall),
            const SizedBox(height: 12),

            SegmentedButton<PeriodoReporte>(
              segments: [
                for (final p in PeriodoReporte.values)
                  ButtonSegment(value: p, label: Text(p.etiqueta)),
              ],
              selected: {periodo},
              onSelectionChanged: (s) =>
                  ref.read(periodoReporteProvider.notifier).fijar(s.first),
            ),
            const SizedBox(height: 20),

            resumen.when(
              loading: () => const SkeletonBloque(alto: 120),
              error: (e, _) => EstadoError(mensaje: '$e'),
              data: (r) => _Tarjetas(resumen: r, esAdmin: esAdmin),
            ),
            const SizedBox(height: 20),

            _Seccion(
              titulo: 'Ventas por periodo',
              child: const _GraficaVentas(),
            ),
            const SizedBox(height: 20),

            _Seccion(
              titulo: 'Más vendidos',
              accion: TextButton(
                onPressed: () => context.push(Rutas.movimientos),
                child: const Text('Movimientos'),
              ),
              child: _TopProductos(esAdmin: esAdmin),
            ),
            const SizedBox(height: 20),

            if (esAdmin) ...[
              const _Seccion(
                titulo: 'Inventario por categoría',
                child: _Valorizacion(),
              ),
              const SizedBox(height: 20),
            ],

            const _Seccion(
              titulo: 'Movimientos del periodo',
              child: _ResumenMovimientos(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estructura ─────────────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child, this.accion});

  final String titulo;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(titulo, style: context.textos.titleMedium),
            const Spacer(),
            ?accion,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Tarjetas extends StatelessWidget {
  const _Tarjetas({required this.resumen, required this.esAdmin});

  final ResumenDashboard resumen;
  final bool esAdmin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tarjeta(
            etiqueta: 'Ventas 30 días',
            valor: resumen.ventasMes.format(),
            icono: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: esAdmin
              ? _Tarjeta(
                  etiqueta: 'Margen 30 días',
                  valor: resumen.margenMes.format(),
                  icono: Icons.savings_outlined,
                  color: context.dominio.exito,
                )
              : _Tarjeta(
                  etiqueta: 'Ticket promedio',
                  valor: resumen.ticketPromedio.format(),
                  icono: Icons.receipt_outlined,
                ),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.color,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 20, color: color ?? context.colores.onSurfaceVariant),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: context.textos.titleLarge?.copyWith(color: color)),
            ),
            Text(
              etiqueta,
              style: context.textos.bodySmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gráfica ────────────────────────────────────────────────────────────────

class _GraficaVentas extends ConsumerWidget {
  const _GraficaVentas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serie = ref.watch(serieReporteProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        child: SizedBox(
          height: 220,
          child: serie.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (puntos) {
              if (puntos.isEmpty || puntos.every((p) => p.total.esCero)) {
                return const EstadoVacio(
                  icono: Icons.bar_chart_rounded,
                  titulo: 'Sin ventas en el periodo',
                  compacto: true,
                );
              }

              final maximo = puntos
                  .map((p) => p.total.centavos)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble();

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maximo * 1.15,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maximo / 3,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.colores.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: maximo / 3,
                        getTitlesWidget: (valor, meta) => Text(
                          // Se abrevia a miles: «$ 1.250.000» en el eje deja
                          // sitio para tres barras y nada más.
                          _abreviar(valor),
                          style: context.textos.labelSmall?.copyWith(
                            color: context.colores.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        // Con muchas barras sólo se etiquetan algunas: si no,
                        // las fechas se solapan y no se lee ninguna.
                        interval: 1,
                        getTitlesWidget: (valor, meta) {
                          final i = valor.toInt();
                          if (i < 0 || i >= puntos.length) return const SizedBox.shrink();
                          final paso = (puntos.length / 6).ceil();
                          if (i % paso != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _etiquetaPeriodo(puntos[i].dia),
                              style: context.textos.labelSmall?.copyWith(
                                color: context.colores.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => context.colores.inverseSurface,
                      getTooltipItem: (grupo, _, rod, _) => BarTooltipItem(
                        '${_etiquetaPeriodo(puntos[grupo.x].dia)}\n'
                        '${Money(rod.toY.round()).format()}\n'
                        '${puntos[grupo.x].numVentas} venta'
                        '${puntos[grupo.x].numVentas == 1 ? '' : 's'}',
                        TextStyle(
                          color: context.colores.onInverseSurface,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < puntos.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: puntos[i].total.centavos.toDouble(),
                            color: context.colores.primary,
                            width: (200 / puntos.length).clamp(6, 22),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _abreviar(double centavos) {
    final pesos = centavos / 100;
    if (pesos >= 1000000) return '${(pesos / 1000000).toStringAsFixed(1)}M';
    if (pesos >= 1000) return '${(pesos / 1000).round()}k';
    return pesos.round().toString();
  }

  /// Los periodos semanales llegan como `2026-W31`, que no es una fecha ISO.
  static String _etiquetaPeriodo(String periodo) {
    if (periodo.contains('-W')) return 'sem ${periodo.split('-W').last}';
    if (periodo.length == 7) return periodo;
    return Fechas.formatDiaCorto(periodo);
  }
}

// ─── Listas ─────────────────────────────────────────────────────────────────

class _TopProductos extends ConsumerWidget {
  const _TopProductos({required this.esAdmin});

  final bool esAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = ref.watch(topReporteProvider).value ?? const <ProductoVendido>[];

    if (top.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: EstadoVacio(
            icono: Icons.emoji_events_outlined,
            titulo: 'Sin ventas en el periodo',
            compacto: true,
          ),
        ),
      );
    }

    final maximo = top.first.unidades.milesimas.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < top.length; i++)
              ListTile(
                dense: true,
                onTap: top[i].productoUuid == null
                    ? null
                    : () => context.push(Rutas.productoDetalle(top[i].productoUuid!)),
                leading: SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: context.textos.titleSmall?.copyWith(
                      color: i < 3 ? context.colores.primary : context.colores.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(
                  top[i].nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Barra proporcional: comparar «142 vs 138 unidades» en
                    // texto obliga a leer; en barra se ve de un vistazo.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: maximo == 0 ? 0 : top[i].unidades.milesimas / maximo,
                        minHeight: 5,
                        backgroundColor: context.colores.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${top[i].unidades.format()} uds · ${top[i].ingreso.format()}'
                      '${esAdmin ? ' · margen ${top[i].margen.format()}' : ''}',
                      style: context.textos.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Valorizacion extends ConsumerWidget {
  const _Valorizacion();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filas = ref.watch(valorizacionProvider).value ?? const [];
    if (filas.isEmpty) return const SizedBox.shrink();

    final totalCosto = Money.sumar(filas.map((f) => f.costo));
    final totalVenta = Money.sumar(filas.map((f) => f.venta));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final fila in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fila.categoria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textos.bodyMedium,
                      ),
                    ),
                    Text(
                      '${fila.productos} prod.',
                      style: context.textos.labelSmall?.copyWith(
                        color: context.colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(fila.costo.format(), style: context.textos.bodyMedium),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Text('Total a costo', style: context.textos.titleSmall),
                const Spacer(),
                Text(totalCosto.format(), style: context.textos.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Valor a precio de venta',
                  style: context.textos.bodySmall?.copyWith(
                    color: context.colores.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  totalVenta.format(),
                  style: context.textos.bodySmall?.copyWith(
                    color: context.colores.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenMovimientos extends ConsumerWidget {
  const _ResumenMovimientos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filas = ref.watch(resumenMovimientosProvider).value ?? const [];
    if (filas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: EstadoVacio(
            icono: Icons.swap_vert_rounded,
            titulo: 'Sin movimientos',
            compacto: true,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final fila in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        etiquetaMovimiento(fila.tipo),
                        style: context.textos.bodyMedium,
                      ),
                    ),
                    Text(
                      '${fila.n}',
                      style: context.textos.labelMedium?.copyWith(
                        color: context.colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 74,
                      child: Text(
                        '${fila.neto.milesimas > 0 ? '+' : ''}${fila.neto.format()}',
                        textAlign: TextAlign.right,
                        style: context.textos.titleSmall?.copyWith(
                          color: fila.neto.milesimas >= 0
                              ? context.dominio.exito
                              : context.dominio.peligro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
