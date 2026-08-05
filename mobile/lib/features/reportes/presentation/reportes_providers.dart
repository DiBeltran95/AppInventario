import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/reportes_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/fechas.dart';

/// Periodo de análisis. Todo se calcula por **día hábil de la tienda**, no por
/// UTC: en Colombia, agrupar por UTC cortaría el día a las 7 de la tarde.
enum PeriodoReporte {
  semana,
  mes,
  trimestre;

  String get etiqueta => switch (this) {
        PeriodoReporte.semana => '7 días',
        PeriodoReporte.mes => '30 días',
        PeriodoReporte.trimestre => '90 días',
      };

  int get dias => switch (this) {
        PeriodoReporte.semana => 7,
        PeriodoReporte.mes => 30,
        PeriodoReporte.trimestre => 90,
      };

  String get desde => Fechas.sumarDias(Fechas.hoy(), -(dias - 1));

  /// Con 90 días, una barra por día es ilegible en un teléfono: se agrupa.
  String get agrupacion => this == PeriodoReporte.trimestre ? 'semana' : 'dia';
}

/// Riverpod 3 retiró `StateProvider`; un `Notifier` de una sola línea cumple
/// lo mismo sin dependencias heredadas.
class PeriodoReporteNotifier extends Notifier<PeriodoReporte> {
  @override
  PeriodoReporte build() => PeriodoReporte.semana;

  void fijar(PeriodoReporte periodo) => state = periodo;
}

final periodoReporteProvider =
    NotifierProvider<PeriodoReporteNotifier, PeriodoReporte>(
  PeriodoReporteNotifier.new,
);

final serieReporteProvider = FutureProvider<List<PuntoSerie>>((ref) {
  final periodo = ref.watch(periodoReporteProvider);
  // Se observa el resumen para que la serie se recalcule al registrarse una
  // venta: `ventasPorPeriodo` es un Future, no un stream.
  ref.watch(resumenReporteProvider);
  return ref.watch(reportesDaoProvider).ventasPorPeriodo(
        desde: periodo.desde,
        hasta: Fechas.hoy(),
        agrupar: periodo.agrupacion,
      );
});

final resumenReporteProvider = StreamProvider<ResumenDashboard>(
  (ref) => ref.watch(reportesDaoProvider).observarResumen(),
);

final topReporteProvider = StreamProvider<List<ProductoVendido>>((ref) {
  final periodo = ref.watch(periodoReporteProvider);
  return ref.watch(reportesDaoProvider).observarTopProductos(
        desde: periodo.desde,
        hasta: Fechas.hoy(),
        limite: 10,
      );
});

final valorizacionProvider = StreamProvider<
    List<({String categoria, int productos, Money costo, Money venta})>>(
  (ref) => ref.watch(reportesDaoProvider).observarValorizacion(),
);

final resumenMovimientosProvider =
    FutureProvider<List<({String tipo, int n, Cantidad neto})>>((ref) {
  final periodo = ref.watch(periodoReporteProvider);
  ref.watch(resumenReporteProvider);
  return ref.watch(reportesDaoProvider).resumenMovimientos(
        desde: periodo.desde,
        hasta: Fechas.hoy(),
      );
});
