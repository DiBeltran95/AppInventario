import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ventas_dao.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/fechas.dart';

/// Rango de fechas del historial de ventas, en días hábiles de la tienda.
enum RangoVentas {
  hoy,
  semana,
  mes,
  todo;

  String get etiqueta => switch (this) {
        RangoVentas.hoy => 'Hoy',
        RangoVentas.semana => 'Esta semana',
        RangoVentas.mes => 'Este mes',
        RangoVentas.todo => 'Todo',
      };

  /// `null` significa «sin límite inferior».
  String? get desde => switch (this) {
        RangoVentas.hoy => Fechas.hoy(),
        RangoVentas.semana => Fechas.inicioSemana(),
        RangoVentas.mes => Fechas.inicioMes(),
        RangoVentas.todo => null,
      };
}

class FiltroVentas {
  const FiltroVentas({this.rango = RangoVentas.hoy, this.busqueda = ''});

  final RangoVentas rango;
  final String busqueda;

  FiltroVentas copyWith({RangoVentas? rango, String? busqueda}) =>
      FiltroVentas(rango: rango ?? this.rango, busqueda: busqueda ?? this.busqueda);
}

class FiltroVentasNotifier extends Notifier<FiltroVentas> {
  @override
  FiltroVentas build() => const FiltroVentas();

  void porRango(RangoVentas rango) => state = state.copyWith(rango: rango);
  void buscar(String texto) => state = state.copyWith(busqueda: texto);
}

final filtroVentasProvider =
    NotifierProvider<FiltroVentasNotifier, FiltroVentas>(FiltroVentasNotifier.new);

final ventasProvider = StreamProvider<List<Venta>>((ref) {
  final filtro = ref.watch(filtroVentasProvider);
  return ref.watch(ventasDaoProvider).observarVentas(
        desde: filtro.rango.desde,
        busqueda: filtro.busqueda,
        // Se incluyen las anuladas para que el historial no mienta: una venta
        // que existió y se anuló debe seguir siendo visible.
        estado: null,
      );
});

final ventaProvider = StreamProvider.family<VentaCompleta?, String>(
  (ref, uuid) => ref.watch(ventasDaoProvider).observarVenta(uuid),
);
