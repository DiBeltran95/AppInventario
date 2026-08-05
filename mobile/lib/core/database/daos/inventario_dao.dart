import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../money/money.dart';
import '../../utils/fechas.dart';
import '../app_database.dart';
import 'outbox_dao.dart';

/// Signo que impone cada tipo de movimiento.
/// El cliente no puede convertir una VENTA en entrada mandando cantidad
/// positiva: el tipo manda. `AJUSTE` es el único que respeta el signo enviado.
const Map<String, int> signoMovimiento = {
  'INICIAL': 1,
  'ENTRADA': 1,
  'DEVOLUCION': 1,
  'ANULACION_VENTA': 1,
  'SALIDA': -1,
  'VENTA': -1,
  'MERMA': -1,
  'TRASLADO': -1,
  'AJUSTE': 0,
};

class MovimientoConProducto {
  const MovimientoConProducto({required this.movimiento, this.producto, this.proveedor});

  final Movimiento movimiento;
  final Producto? producto;
  final Proveedor? proveedor;

  Cantidad get cantidad => Cantidad(movimiento.cantidad);
  bool get esEntrada => movimiento.cantidad > 0;
  bool get pendienteDeSync => movimiento.sincronizadoEn == null;
}

class InventarioDao {
  InventarioDao(this.db, this.outbox);

  final AppDatabase db;
  final OutboxDao outbox;
  static const _uuid = Uuid();

  // ── Escritura del libro ───────────────────────────────────────────────────

  /// Inserta un movimiento y actualiza la proyección de stock.
  ///
  /// **Éste es el único punto de la app que escribe `productos.stockActual`.**
  /// En el servidor ese papel lo cumplen los triggers; aquí no hay triggers, así
  /// que la disciplina la impone tener un solo escritor. Si el stock se
  /// escribiera también desde otro sitio, se descontaría el doble.
  ///
  /// Debe llamarse DENTRO de una transacción.
  Future<String> _aplicarMovimiento({
    required String productoUuid,
    required String tipo,
    required Cantidad cantidad,
    String? uuidExplicito,
    Money? costoUnitario,
    Money? precioUnitario,
    String? ventaUuid,
    String? proveedorUuid,
    String? usuarioUuid,
    String? lote,
    String? venceEl,
    String? documentoRef,
    String? motivo,
    DateTime? fecha,
  }) async {
    final signo = signoMovimiento[tipo];
    if (signo == null) {
      throw ArgumentError('Tipo de movimiento desconocido: $tipo');
    }
    if (cantidad.esCero) {
      throw ArgumentError('La cantidad no puede ser cero');
    }

    final magnitud = cantidad.milesimas.abs();
    final conSigno = signo == 0 ? cantidad.milesimas : signo * magnitud;

    final producto = await (db.select(db.productos)..where((t) => t.uuid.equals(productoUuid)))
        .getSingleOrNull();
    if (producto == null) {
      throw StateError('El producto $productoUuid no existe en la base local');
    }

    final stockAnterior = producto.stockActual;
    final stockResultante = stockAnterior + conSigno;
    final uuid = uuidExplicito ?? _uuid.v7();
    final instante = (fecha ?? DateTime.now()).toUtc();

    await db.into(db.movimientos).insert(
          MovimientosCompanion.insert(
            uuid: uuid,
            productoUuid: productoUuid,
            tipo: tipo,
            cantidad: conSigno,
            costoUnitario: Value(costoUnitario?.centavos),
            precioUnitario: Value(precioUnitario?.centavos),
            stockAnterior: Value(stockAnterior),
            stockResultante: Value(stockResultante),
            ventaUuid: Value(ventaUuid),
            proveedorUuid: Value(proveedorUuid),
            usuarioUuid: Value(usuarioUuid),
            lote: Value(lote),
            venceEl: Value(venceEl),
            documentoRef: Value(documentoRef),
            motivo: Value(motivo),
            fecha: instante,
            fechaLocal: Fechas.diaHabil(instante),
          ),
          mode: InsertMode.insertOrReplace,
        );

    await (db.update(db.productos)..where((t) => t.uuid.equals(productoUuid))).write(
      ProductosCompanion(
        stockActual: Value(stockResultante),
        // No se toca `updatedAt`: el stock es derivado y su verdad la fija el
        // servidor en el pull. Marcarlo como modificado provocaría un
        // ida y vuelta innecesario en la sincronización del catálogo.
      ),
    );

    return uuid;
  }

  /// Entrada de mercancía, merma, devolución… (todo lo que no es una venta).
  Future<String> registrarMovimiento({
    required String productoUuid,
    required String tipo,
    required Cantidad cantidad,
    Money? costoUnitario,
    String? proveedorUuid,
    String? usuarioUuid,
    String? lote,
    String? venceEl,
    String? documentoRef,
    String? motivo,
  }) async {
    late String uuid;

    await db.transaction(() async {
      uuid = await _aplicarMovimiento(
        productoUuid: productoUuid,
        tipo: tipo,
        cantidad: cantidad,
        costoUnitario: costoUnitario,
        proveedorUuid: proveedorUuid,
        usuarioUuid: usuarioUuid,
        lote: lote,
        venceEl: venceEl,
        documentoRef: documentoRef,
        motivo: motivo,
      );

      // Igual que en el servidor: la última entrada fija el costo de compra.
      if (tipo == 'ENTRADA' && costoUnitario != null) {
        await (db.update(db.productos)..where((t) => t.uuid.equals(productoUuid)))
            .write(ProductosCompanion(precioCompra: Value(costoUnitario.centavos)));
      }

      await outbox.encolar(
        'MOVIMIENTO_CREAR',
        entidad: 'movimientos_inventario',
        entidadUuid: uuid,
        payload: {
          'uuid': uuid,
          'producto_uuid': productoUuid,
          'tipo': tipo,
          'cantidad': cantidad.toApi(),
          'costo_unitario': costoUnitario?.toApi(),
          'proveedor_uuid': proveedorUuid,
          'lote': lote,
          'vence_el': venceEl,
          'documento_ref': documentoRef,
          'motivo': motivo,
          'fecha': DateTime.now().toUtc().toIso8601String(),
          'fecha_local': Fechas.hoy(),
          'creado_offline': true,
        },
      );
    });

    return uuid;
  }

  /// Ajuste por conteo físico: el usuario indica cuánto HAY, no la diferencia.
  /// Pedir la diferencia es una invitación a equivocarse.
  Future<String?> ajustarPorConteo({
    required String productoUuid,
    required Cantidad stockContado,
    String? motivo,
    String? usuarioUuid,
  }) async {
    String? uuid;

    await db.transaction(() async {
      final producto = await (db.select(db.productos)..where((t) => t.uuid.equals(productoUuid)))
          .getSingleOrNull();
      if (producto == null) throw StateError('Producto no encontrado');

      final diferencia = stockContado.milesimas - producto.stockActual;
      if (diferencia == 0) return;

      final anterior = Cantidad(producto.stockActual);
      uuid = await _aplicarMovimiento(
        productoUuid: productoUuid,
        tipo: 'AJUSTE',
        cantidad: Cantidad(diferencia),
        usuarioUuid: usuarioUuid,
        motivo: motivo ?? 'Conteo físico: ${anterior.format()} → ${stockContado.format()}',
      );

      await outbox.encolar(
        'CONTEO_AJUSTAR',
        entidad: 'movimientos_inventario',
        entidadUuid: uuid,
        payload: {
          'uuid': uuid,
          'producto_uuid': productoUuid,
          'stock_contado': stockContado.toApi(),
          'motivo': motivo,
          'fecha': DateTime.now().toUtc().toIso8601String(),
          'creado_offline': true,
        },
      );
    });

    return uuid;
  }

  /// Usado por VentasDao dentro de su propia transacción.
  Future<String> aplicarMovimientoDeVenta({
    required String productoUuid,
    required String tipo,
    required Cantidad cantidad,
    required String ventaUuid,
    Money? precioUnitario,
    Money? costoUnitario,
    String? usuarioUuid,
    String? motivo,
    DateTime? fecha,
  }) =>
      _aplicarMovimiento(
        productoUuid: productoUuid,
        tipo: tipo,
        cantidad: cantidad,
        ventaUuid: ventaUuid,
        precioUnitario: precioUnitario,
        costoUnitario: costoUnitario,
        usuarioUuid: usuarioUuid,
        motivo: motivo,
        fecha: fecha,
      );

  // ── Lecturas ──────────────────────────────────────────────────────────────

  Stream<List<MovimientoConProducto>> observarMovimientos({
    String? productoUuid,
    String? tipo,
    String? desde,
    String? hasta,
    int limite = 200,
  }) {
    final consulta = db.select(db.movimientos).join([
      leftOuterJoin(db.productos, db.productos.uuid.equalsExp(db.movimientos.productoUuid)),
      leftOuterJoin(db.proveedores, db.proveedores.uuid.equalsExp(db.movimientos.proveedorUuid)),
    ]);

    if (productoUuid != null) {
      consulta.where(db.movimientos.productoUuid.equals(productoUuid));
    }
    if (tipo != null) consulta.where(db.movimientos.tipo.equals(tipo));
    if (desde != null) {
      consulta.where(db.movimientos.fechaLocal.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      consulta.where(db.movimientos.fechaLocal.isSmallerOrEqualValue(hasta));
    }

    consulta
      ..orderBy([OrderingTerm.desc(db.movimientos.fecha)])
      ..limit(limite);

    return consulta.watch().map(
          (filas) => filas
              .map((f) => MovimientoConProducto(
                    movimiento: f.readTable(db.movimientos),
                    producto: f.readTableOrNull(db.productos),
                    proveedor: f.readTableOrNull(db.proveedores),
                  ))
              .toList(),
        );
  }

  Stream<List<Alerta>> observarAlertas() => (db.select(db.alertas)
        ..where((t) => t.resueltaEn.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
        ..limit(50))
      .watch();

  /// Reconstruye `stockActual` desde el libro local. Red de seguridad
  /// equivalente a `sp_recalcular_stock` del servidor.
  Future<void> recalcularStock() async {
    await db.transaction(() async {
      final sumas = await db
          .customSelect(
            'SELECT producto_uuid, COALESCE(SUM(cantidad),0) AS total '
            'FROM movimientos GROUP BY producto_uuid',
            readsFrom: {db.movimientos},
          )
          .get();

      for (final fila in sumas) {
        await (db.update(db.productos)
              ..where((t) => t.uuid.equals(fila.read<String>('producto_uuid'))))
            .write(ProductosCompanion(stockActual: Value(fila.read<int>('total'))));
      }
    });
  }
}
