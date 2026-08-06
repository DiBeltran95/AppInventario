import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import '../../money/money.dart';
import '../app_database.dart';
import 'outbox_dao.dart';

/// Producto con su categoría resuelta, tal como lo consume la UI.
class ProductoConCategoria {
  const ProductoConCategoria({required this.producto, this.categoria});

  final Producto producto;
  final Categoria? categoria;

  String get uuid => producto.uuid;
  String get nombre => producto.nombre;
  String get sku => producto.sku;
  Money get precioVenta => Money(producto.precioVenta);
  Money get precioCompra => Money(producto.precioCompra);
  TasaIva get tasaIva => TasaIva(producto.tasaIva);
  Cantidad get stock => Cantidad(producto.stockActual);
  Cantidad get stockMinimo => Cantidad(producto.stockMinimo);

  bool get agotado => producto.stockActual <= 0;
  bool get bajoStock =>
      producto.stockActual > 0 && producto.stockActual <= producto.stockMinimo;

  Money get margenUnitario => precioVenta - precioCompra;
}

/// Resultado de resolver un código escaneado.
class ResolucionCodigo {
  const ResolucionCodigo({
    required this.producto,
    required this.factor,
    required this.origen,
  });

  final ProductoConCategoria producto;

  /// Unidades que representa el código leído: la caja de 12 devuelve 12,000.
  final Cantidad factor;

  /// QR_APP · CODIGO · SKU
  final String origen;
}

enum OrdenProductos { nombre, stockAsc, precioDesc, reciente }

enum FiltroStock { todos, bajo, agotado, disponible }

class ProductosDao {
  ProductosDao(this.db, this.outbox);

  final AppDatabase db;
  final OutboxDao outbox;
  static const _uuid = Uuid();

  // ── Lecturas reactivas ────────────────────────────────────────────────────

  /// Lista observable. La UI se suscribe y Drift la reemite sola cuando el
  /// motor de sincronización escribe: por eso no hace falta "recargar" nada.
  Stream<List<ProductoConCategoria>> observar({
    String? busqueda,
    String? categoriaUuid,
    FiltroStock filtroStock = FiltroStock.todos,
    OrdenProductos orden = OrdenProductos.nombre,
    bool soloActivos = true,
    int limite = 300,
  }) {
    final consulta = db.select(db.productos).join([
      leftOuterJoin(db.categorias, db.categorias.uuid.equalsExp(db.productos.categoriaUuid)),
    ]);

    consulta.where(db.productos.deletedAt.isNull());
    if (soloActivos) consulta.where(db.productos.activo.equals(true));

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final termino = normalizarBusqueda(busqueda);
      // Se busca contra la columna ya normalizada; comparar contra `nombre`
      // obligaría al usuario a escribir los acentos exactos.
      consulta.where(
        db.productos.nombreBusqueda.like('%$termino%') |
            db.productos.sku.lower().like('%$termino%') |
            existsQuery(
              db.selectOnly(db.productoCodigos)
                ..addColumns([db.productoCodigos.uuid])
                ..where(db.productoCodigos.productoUuid.equalsExp(db.productos.uuid) &
                    db.productoCodigos.deletedAt.isNull() &
                    db.productoCodigos.codigo.like('%$termino%')),
            ),
      );
    }

    if (categoriaUuid != null) {
      consulta.where(db.productos.categoriaUuid.equals(categoriaUuid));
    }

    switch (filtroStock) {
      case FiltroStock.bajo:
        consulta.where(db.productos.stockActual.isSmallerOrEqual(db.productos.stockMinimo) &
            db.productos.stockActual.isBiggerThanValue(0));
      case FiltroStock.agotado:
        consulta.where(db.productos.stockActual.isSmallerOrEqualValue(0));
      case FiltroStock.disponible:
        consulta.where(db.productos.stockActual.isBiggerThan(db.productos.stockMinimo));
      case FiltroStock.todos:
        break;
    }

    consulta.orderBy(switch (orden) {
      OrdenProductos.nombre => [OrderingTerm.asc(db.productos.nombre)],
      OrdenProductos.stockAsc => [OrderingTerm.asc(db.productos.stockActual)],
      OrdenProductos.precioDesc => [OrderingTerm.desc(db.productos.precioVenta)],
      OrdenProductos.reciente => [OrderingTerm.desc(db.productos.updatedAt)],
    });
    consulta.limit(limite);

    return consulta.watch().map(
          (filas) => filas
              .map((f) => ProductoConCategoria(
                    producto: f.readTable(db.productos),
                    categoria: f.readTableOrNull(db.categorias),
                  ))
              .toList(),
        );
  }

  Stream<ProductoConCategoria?> observarUno(String uuid) {
    final consulta = db.select(db.productos).join([
      leftOuterJoin(db.categorias, db.categorias.uuid.equalsExp(db.productos.categoriaUuid)),
    ])
      ..where(db.productos.uuid.equals(uuid));
    return consulta.watchSingleOrNull().map(
          (f) => f == null
              ? null
              : ProductoConCategoria(
                  producto: f.readTable(db.productos),
                  categoria: f.readTableOrNull(db.categorias),
                ),
        );
  }

  Future<ProductoConCategoria?> obtener(String uuid) async {
    final f = await (db.select(db.productos).join([
      leftOuterJoin(db.categorias, db.categorias.uuid.equalsExp(db.productos.categoriaUuid)),
    ])
          ..where(db.productos.uuid.equals(uuid)))
        .getSingleOrNull();
    if (f == null) return null;
    return ProductoConCategoria(
      producto: f.readTable(db.productos),
      categoria: f.readTableOrNull(db.categorias),
    );
  }

  Stream<List<ProductoConCategoria>> observarStockBajo({int limite = 20}) =>
      observar(filtroStock: FiltroStock.bajo, orden: OrdenProductos.stockAsc, limite: limite);

  /// Productos más vendidos en los últimos [dias], para la rejilla de venta
  /// rápida.
  ///
  /// En una tienda con un catálogo pequeño, unas dos docenas de productos
  /// concentran la mayoría de las ventas. Tocarlos en una rejilla es más rápido
  /// que apuntar la cámara: no hay que enfocar, ni buscar buena luz, ni pelearse
  /// con una etiqueta arrugada.
  ///
  /// Los que aún no se han vendido nunca se incluyen al final (ordenados por
  /// nombre) para que la rejilla no aparezca medio vacía en una tienda recién
  /// configurada.
  Stream<List<ProductoConCategoria>> observarFrecuentes({
    int limite = 24,
    int dias = 30,
  }) {
    final desde = _diaHace(dias);

    return db
        .customSelect(
          '''
          SELECT p.uuid,
                 -- El CASE es imprescindible: al filtrar la venta en el ON del
                 -- LEFT JOIN, las líneas de una venta ANULADA siguen llegando
                 -- (con v en NULL) y `SUM(d.cantidad)` las contaría igual. Una
                 -- venta anulada no puede empujar un producto al top.
                 COALESCE(SUM(CASE WHEN v.uuid IS NOT NULL THEN d.cantidad ELSE 0 END), 0)
                   AS vendido
            FROM productos p
            LEFT JOIN venta_detalles d ON d.producto_uuid = p.uuid
            LEFT JOIN ventas v
                   ON v.uuid = d.venta_uuid
                  AND v.estado = 'COMPLETADA'
                  AND v.deleted_at IS NULL
                  AND v.fecha_local >= ?
           WHERE p.deleted_at IS NULL AND p.activo = 1
           GROUP BY p.uuid
           ORDER BY vendido DESC, p.nombre ASC
           LIMIT ?
          ''',
          variables: [Variable<String>(desde), Variable<int>(limite)],
          readsFrom: {db.productos, db.ventaDetalles, db.ventas},
        )
        .watch()
        .asyncMap((filas) async {
      final orden = [for (final f in filas) f.read<String>('uuid')];
      if (orden.isEmpty) return const <ProductoConCategoria>[];

      final resultado = await (db.select(db.productos).join([
        leftOuterJoin(db.categorias, db.categorias.uuid.equalsExp(db.productos.categoriaUuid)),
      ])
            ..where(db.productos.uuid.isIn(orden)))
          .get();

      final porUuid = {
        for (final f in resultado)
          f.readTable(db.productos).uuid: ProductoConCategoria(
            producto: f.readTable(db.productos),
            categoria: f.readTableOrNull(db.categorias),
          ),
      };

      // Se respeta el orden del ranking: `IN (...)` no lo garantiza.
      return [for (final uuid in orden) if (porUuid[uuid] != null) porUuid[uuid]!];
    });
  }

  static String _diaHace(int dias) {
    final d = DateTime.now().toUtc().subtract(Duration(days: dias));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<Categoria>> categorias() => (db.select(db.categorias)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.orden), (t) => OrderingTerm.asc(t.nombre)]))
      .get();

  Stream<List<Categoria>> observarCategorias() => (db.select(db.categorias)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.orden), (t) => OrderingTerm.asc(t.nombre)]))
      .watch();

  Stream<List<Proveedor>> observarProveedores() => (db.select(db.proveedores)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
      .watch();

  Future<List<ProductoCodigo>> codigosDe(String productoUuid) =>
      (db.select(db.productoCodigos)
            ..where((t) => t.productoUuid.equals(productoUuid) & t.deletedAt.isNull()))
          .get();

  // ── Resolución de escaneo (SIN RED) ───────────────────────────────────────

  /// Resuelve un código leído por la cámara.
  ///
  /// Orden fijado en el contrato:
  ///   1. `inv://p/{uuid}`  → QR emitido por esta app
  ///   2. `producto_codigos.codigo` → EAN/UPC/Code128 de fábrica
  ///   3. `sku`
  ///
  /// Todo contra SQLite: escanear no toca la red ni cuando la hay. Ése es el
  /// motivo de que el escáner sea igual de rápido en modo avión.
  Future<ResolucionCodigo?> resolverCodigo(String codigoBruto) async {
    final codigo = codigoBruto.trim();
    if (codigo.isEmpty) return null;

    if (codigo.startsWith(AppConfig.qrPrefix)) {
      final uuid = codigo.substring(AppConfig.qrPrefix.length);
      final p = await obtener(uuid);
      if (p != null && p.producto.deletedAt == null) {
        return ResolucionCodigo(
          producto: p,
          factor: Cantidad.unidades(1),
          origen: 'QR_APP',
        );
      }
    }

    final porCodigo = await (db.select(db.productoCodigos)
          ..where((t) => t.codigo.equals(codigo) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (porCodigo != null) {
      final p = await obtener(porCodigo.productoUuid);
      if (p != null && p.producto.deletedAt == null) {
        return ResolucionCodigo(
          producto: p,
          factor: Cantidad(porCodigo.factor),
          origen: 'CODIGO',
        );
      }
    }

    final porSku = await (db.select(db.productos)
          ..where((t) => t.sku.equals(codigo) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (porSku != null) {
      final p = await obtener(porSku.uuid);
      if (p != null) {
        return ResolucionCodigo(producto: p, factor: Cantidad.unidades(1), origen: 'SKU');
      }
    }

    return null;
  }

  // ── Mutaciones locales (escriben dominio + outbox en una transacción) ─────

  Future<String> crear({
    required String sku,
    required String nombre,
    String? descripcion,
    String? categoriaUuid,
    String unidadMedida = 'UND',
    Money precioCompra = const Money.cero(),
    Money precioVenta = const Money.cero(),
    TasaIva tasaIva = const TasaIva(1900),
    Cantidad stockMinimo = const Cantidad.cero(),
    String? imagenUrl,
    String? imagenLocal,
    String? ubicacion,
    List<({String codigo, String tipo})> codigos = const [],
  }) async {
    final uuid = _uuid.v7();

    await db.transaction(() async {
      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              uuid: uuid,
              sku: sku,
              nombre: nombre,
              nombreBusqueda: Value(normalizarBusqueda(nombre)),
              descripcion: Value(descripcion),
              categoriaUuid: Value(categoriaUuid),
              unidadMedida: Value(unidadMedida),
              precioCompra: Value(precioCompra.centavos),
              precioVenta: Value(precioVenta.centavos),
              tasaIva: Value(tasaIva.escalada),
              stockMinimo: Value(stockMinimo.milesimas),
              imagenUrl: Value(imagenUrl),
              imagenLocal: Value(imagenLocal),
              ubicacion: Value(ubicacion),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

      final codigosPayload = <Map<String, dynamic>>[];
      for (final c in codigos) {
        final codigoUuid = _uuid.v7();
        await db.into(db.productoCodigos).insert(
              ProductoCodigosCompanion.insert(
                uuid: codigoUuid,
                productoUuid: uuid,
                codigo: c.codigo,
                tipo: Value(c.tipo),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
              mode: InsertMode.insertOrReplace,
            );
        codigosPayload.add({'uuid': codigoUuid, 'codigo': c.codigo, 'tipo': c.tipo});
      }

      await outbox.encolar(
        'PRODUCTO_CREAR',
        entidad: 'productos',
        entidadUuid: uuid,
        payload: {
          'uuid': uuid,
          'sku': sku,
          'nombre': nombre,
          'descripcion': descripcion,
          'categoria_uuid': categoriaUuid,
          'unidad_medida': unidadMedida,
          'precio_compra': precioCompra.toApi(),
          'precio_venta': precioVenta.toApi(),
          'tasa_iva': tasaIva.toApi(),
          'stock_minimo': stockMinimo.toApi(),
          'imagen_url': imagenUrl,
          'ubicacion': ubicacion,
          'codigos': codigosPayload,
        },
      );
    });

    return uuid;
  }

  Future<void> actualizar(
    String uuid, {
    String? sku,
    String? nombre,
    String? descripcion,
    String? categoriaUuid,
    bool limpiarCategoria = false,
    String? unidadMedida,
    Money? precioCompra,
    Money? precioVenta,
    TasaIva? tasaIva,
    Cantidad? stockMinimo,
    String? imagenUrl,
    /// Ruta de la foto en el dispositivo. No viaja en el payload: al servidor
    /// no le sirve una ruta del sistema de archivos de este teléfono.
    String? imagenLocal,
    String? ubicacion,
    bool? activo,
  }) async {
    await db.transaction(() async {
      await (db.update(db.productos)..where((t) => t.uuid.equals(uuid))).write(
        ProductosCompanion(
          sku: sku == null ? const Value.absent() : Value(sku),
          nombre: nombre == null ? const Value.absent() : Value(nombre),
          nombreBusqueda:
              nombre == null ? const Value.absent() : Value(normalizarBusqueda(nombre)),
          descripcion: descripcion == null ? const Value.absent() : Value(descripcion),
          categoriaUuid: limpiarCategoria
              ? const Value(null)
              : (categoriaUuid == null ? const Value.absent() : Value(categoriaUuid)),
          unidadMedida: unidadMedida == null ? const Value.absent() : Value(unidadMedida),
          precioCompra:
              precioCompra == null ? const Value.absent() : Value(precioCompra.centavos),
          precioVenta: precioVenta == null ? const Value.absent() : Value(precioVenta.centavos),
          tasaIva: tasaIva == null ? const Value.absent() : Value(tasaIva.escalada),
          stockMinimo: stockMinimo == null ? const Value.absent() : Value(stockMinimo.milesimas),
          imagenUrl: imagenUrl == null ? const Value.absent() : Value(imagenUrl),
          imagenLocal: imagenLocal == null ? const Value.absent() : Value(imagenLocal),
          ubicacion: ubicacion == null ? const Value.absent() : Value(ubicacion),
          activo: activo == null ? const Value.absent() : Value(activo),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      // `stock_actual` no aparece por ningún lado a propósito: es derivado del
      // libro de movimientos. Para corregirlo se registra un AJUSTE.
      final payload = <String, dynamic>{'uuid': uuid};
      if (sku != null) payload['sku'] = sku;
      if (nombre != null) payload['nombre'] = nombre;
      if (descripcion != null) payload['descripcion'] = descripcion;
      if (limpiarCategoria) {
        payload['categoria_uuid'] = null;
      } else if (categoriaUuid != null) {
        payload['categoria_uuid'] = categoriaUuid;
      }
      if (unidadMedida != null) payload['unidad_medida'] = unidadMedida;
      if (precioCompra != null) payload['precio_compra'] = precioCompra.toApi();
      if (precioVenta != null) payload['precio_venta'] = precioVenta.toApi();
      if (tasaIva != null) payload['tasa_iva'] = tasaIva.toApi();
      if (stockMinimo != null) payload['stock_minimo'] = stockMinimo.toApi();
      if (imagenUrl != null) payload['imagen_url'] = imagenUrl;
      if (ubicacion != null) payload['ubicacion'] = ubicacion;
      if (activo != null) payload['activo'] = activo;

      await outbox.encolar(
        'PRODUCTO_ACTUALIZAR',
        entidad: 'productos',
        entidadUuid: uuid,
        payload: payload,
      );
    });
  }

  /// Borrado lógico. Un borrado físico no llegaría nunca al otro dispositivo y
  /// rompería el histórico de ventas.
  Future<void> eliminar(String uuid) async {
    await db.transaction(() async {
      final ahora = DateTime.now().toUtc();
      await (db.update(db.productos)..where((t) => t.uuid.equals(uuid)))
          .write(ProductosCompanion(deletedAt: Value(ahora), activo: const Value(false), updatedAt: Value(ahora)));
      await (db.update(db.productoCodigos)..where((t) => t.productoUuid.equals(uuid)))
          .write(ProductoCodigosCompanion(deletedAt: Value(ahora), updatedAt: Value(ahora)));
      await outbox.encolar(
        'PRODUCTO_ELIMINAR',
        entidad: 'productos',
        entidadUuid: uuid,
        payload: {'uuid': uuid},
      );
    });
  }

  /// Solo actualiza la ruta local (sin outbox). Se usa al mover la foto del
  /// caché temporal de `image_picker` a Documents.
  Future<void> fijarImagenLocal(String uuid, String ruta) async {
    await (db.update(db.productos)..where((t) => t.uuid.equals(uuid))).write(
      ProductosCompanion(imagenLocal: Value(ruta)),
    );
  }

  /// Productos con foto en el dispositivo que aún no tienen URL pública.
  /// El SyncEngine los sube cuando hay red para que el resto de cajas los vean.
  Future<List<Producto>> conImagenPendienteDeSubir() {
    return (db.select(db.productos)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.imagenLocal.isNotNull() &
                (t.imagenUrl.isNull() | t.imagenUrl.equals('')),
          ))
        .get();
  }

  Future<String> agregarCodigo(String productoUuid, String codigo, String tipo) async {
    final uuid = _uuid.v7();
    await db.transaction(() async {
      await db.into(db.productoCodigos).insert(
            ProductoCodigosCompanion.insert(
              uuid: uuid,
              productoUuid: productoUuid,
              codigo: codigo,
              tipo: Value(tipo),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
            mode: InsertMode.insertOrReplace,
          );
      await outbox.encolar(
        'CODIGO_CREAR',
        entidad: 'producto_codigos',
        entidadUuid: uuid,
        payload: {
          'uuid': uuid,
          'producto_uuid': productoUuid,
          'codigo': codigo,
          'tipo': tipo,
          'es_principal': false,
          'factor': '1.000',
        },
      );
    });
    return uuid;
  }

  Future<void> eliminarCodigo(String codigoUuid) async {
    await db.transaction(() async {
      await (db.update(db.productoCodigos)..where((t) => t.uuid.equals(codigoUuid)))
          .write(ProductoCodigosCompanion(deletedAt: Value(DateTime.now().toUtc())));
      await outbox.encolar(
        'CODIGO_ELIMINAR',
        entidad: 'producto_codigos',
        entidadUuid: codigoUuid,
        payload: {'uuid': codigoUuid},
      );
    });
  }

  /// ¿Este código ya está asignado? Se comprueba ANTES de guardar para dar un
  /// error inmediato en el formulario en vez de un rechazo diferido de la cola.
  Future<Producto?> productoDelCodigo(String codigo) async {
    final fila = await (db.select(db.productoCodigos)
          ..where((t) => t.codigo.equals(codigo) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (fila == null) return null;
    return (db.select(db.productos)..where((t) => t.uuid.equals(fila.productoUuid)))
        .getSingleOrNull();
  }

  Future<bool> skuDisponible(String sku, {String? exceptoUuid}) async {
    final consulta = db.select(db.productos)
      ..where((t) => t.sku.equals(sku) & t.deletedAt.isNull());
    final existente = await consulta.getSingleOrNull();
    return existente == null || existente.uuid == exceptoUuid;
  }

  /// Sugiere un SKU libre a partir del nombre: `Gaseosa cola 400 ml` → `GAS-001`.
  Future<String> sugerirSku(String nombre) async {
    final base = normalizarBusqueda(nombre)
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(1)
        .join();
    final prefijo = (base.isEmpty ? 'PRD' : base.substring(0, base.length.clamp(0, 3)))
        .toUpperCase()
        .padRight(3, 'X');

    for (var i = 1; i <= 999; i++) {
      final candidato = '$prefijo-${i.toString().padLeft(3, '0')}';
      if (await skuDisponible(candidato)) return candidato;
    }
    return '$prefijo-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }
}
