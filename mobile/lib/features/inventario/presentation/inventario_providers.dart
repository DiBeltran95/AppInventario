import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/inventario_dao.dart';
import '../../../core/providers/providers.dart';

/// Criterios del historial de movimientos.
///
/// Se implementa `==` y `hashCode` a mano porque es el argumento de un
/// `family`: sin igualdad por valor, Riverpod crearía un provider nuevo (y una
/// consulta nueva) en cada `build`.
class FiltroMovimientos {
  const FiltroMovimientos({
    this.productoUuid,
    this.tipo,
    this.desde,
    this.hasta,
    this.limite = 200,
  });

  final String? productoUuid;
  final String? tipo;
  final String? desde;
  final String? hasta;
  final int limite;

  FiltroMovimientos copyWith({
    String? productoUuid,
    String? tipo,
    bool limpiarTipo = false,
    String? desde,
    String? hasta,
    int? limite,
  }) =>
      FiltroMovimientos(
        productoUuid: productoUuid ?? this.productoUuid,
        tipo: limpiarTipo ? null : (tipo ?? this.tipo),
        desde: desde ?? this.desde,
        hasta: hasta ?? this.hasta,
        limite: limite ?? this.limite,
      );

  @override
  bool operator ==(Object other) =>
      other is FiltroMovimientos &&
      other.productoUuid == productoUuid &&
      other.tipo == tipo &&
      other.desde == desde &&
      other.hasta == hasta &&
      other.limite == limite;

  @override
  int get hashCode => Object.hash(productoUuid, tipo, desde, hasta, limite);
}

final movimientosProvider =
    StreamProvider.family<List<MovimientoConProducto>, FiltroMovimientos>(
  (ref, filtro) => ref.watch(inventarioDaoProvider).observarMovimientos(
        productoUuid: filtro.productoUuid,
        tipo: filtro.tipo,
        desde: filtro.desde,
        hasta: filtro.hasta,
        limite: filtro.limite,
      ),
);

/// Etiquetas legibles para los tipos de movimiento. En la interfaz no aparece
/// `ANULACION_VENTA` en mayúsculas y con guion bajo.
String etiquetaMovimiento(String tipo) => switch (tipo) {
      'INICIAL' => 'Inventario inicial',
      'ENTRADA' => 'Entrada',
      'SALIDA' => 'Salida',
      'VENTA' => 'Venta',
      'AJUSTE' => 'Ajuste',
      'MERMA' => 'Merma',
      'DEVOLUCION' => 'Devolución',
      'ANULACION_VENTA' => 'Anulación de venta',
      'TRASLADO' => 'Traslado',
      _ => tipo,
    };
