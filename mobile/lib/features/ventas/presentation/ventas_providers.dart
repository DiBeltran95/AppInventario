import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ventas_dao.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/fechas.dart';
import '../../auth/presentation/auth_providers.dart';

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
  const FiltroVentas({this.rango = RangoVentas.hoy, this.dia, this.busqueda = ''});

  final RangoVentas rango;

  /// Día concreto ('AAAA-MM-DD'). Es lo que usa el vendedor: su pregunta no es
  /// «¿cuánto llevo este mes?» sino «¿cuánto llevo en mi turno?».
  /// `null` equivale a hoy.
  final String? dia;

  final String busqueda;

  String get diaEfectivo => dia ?? Fechas.hoy();
  bool get esHoy => diaEfectivo == Fechas.hoy();

  FiltroVentas copyWith({RangoVentas? rango, String? dia, String? busqueda}) =>
      FiltroVentas(
        rango: rango ?? this.rango,
        dia: dia ?? this.dia,
        busqueda: busqueda ?? this.busqueda,
      );
}

class FiltroVentasNotifier extends Notifier<FiltroVentas> {
  @override
  FiltroVentas build() => const FiltroVentas();

  void porRango(RangoVentas rango) => state = state.copyWith(rango: rango);
  void buscar(String texto) => state = state.copyWith(busqueda: texto);

  void porDia(String dia) => state = state.copyWith(dia: dia);

  /// Mueve el día seleccionado. No deja pasar del día de hoy: las ventas de
  /// mañana no existen todavía y una pantalla vacía parecería un fallo.
  void desplazarDia(int dias) {
    final destino = Fechas.sumarDias(state.diaEfectivo, dias);
    if (destino.compareTo(Fechas.hoy()) > 0) return;
    state = state.copyWith(dia: destino);
  }

  void volverAHoy() => state = state.copyWith(dia: Fechas.hoy());
}

final filtroVentasProvider =
    NotifierProvider<FiltroVentasNotifier, FiltroVentas>(FiltroVentasNotifier.new);

/// Historial de ventas, acotado por rol.
///
/// El vendedor ve **sólo las suyas y de un único día**. No es una preferencia
/// de interfaz: el histórico completo del negocio permite deducir la caja, los
/// márgenes por comparación y el ritmo de venta de los compañeros. Su turno es
/// lo único que le compete.
final ventasProvider = StreamProvider<List<Venta>>((ref) {
  final filtro = ref.watch(filtroVentasProvider);
  final esAdmin = ref.watch(esAdminProvider);
  final dao = ref.watch(ventasDaoProvider);

  if (esAdmin) {
    return dao.observarVentas(
      desde: filtro.rango.desde,
      busqueda: filtro.busqueda,
      // Se incluyen las anuladas para que el historial no mienta: una venta
      // que existió y se anuló debe seguir siendo visible.
      estado: null,
    );
  }

  final usuarioUuid = ref.watch(sesionProvider).value?.usuarioUuid;
  // Sin sesión resuelta no se enseña nada. Devolver la lista completa «mientras
  // carga» filtraría un segundo después, pero ese segundo ya habría mostrado
  // las ventas de todo el negocio.
  if (usuarioUuid == null) return Stream.value(const <Venta>[]);

  final dia = filtro.diaEfectivo;
  return dao.observarVentas(
    desde: dia,
    hasta: dia,
    busqueda: filtro.busqueda,
    estado: null,
    usuarioUuid: usuarioUuid,
  );
});

final ventaProvider = StreamProvider.family<VentaCompleta?, String>(
  (ref, uuid) => ref.watch(ventasDaoProvider).observarVenta(uuid),
);
