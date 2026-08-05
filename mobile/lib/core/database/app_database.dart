import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Base local SQLite — **fuente de verdad del dispositivo**.
///
/// La UI nunca hace una petición HTTP para pintarse: lee de aquí. La red sólo
/// alimenta estas tablas. Ése es todo el secreto del modo offline.
///
/// Convenciones que replican el servidor:
///  · `uuid` (v7, generado en el cliente) es la clave primaria de negocio.
///  · El dinero se guarda como INTEGER de centavos; las cantidades, como
///    INTEGER de milésimas. Nunca REAL: ver core/money/money.dart.
///  · `fechaLocal` es TEXT 'AAAA-MM-DD' en la zona de la tienda, para que los
///    reportes por día no se partan a medianoche UTC.
///  · Borrado lógico (`deletedAt`) en todo lo sincronizable.

// ─── Catálogo ────────────────────────────────────────────────────────────────

class Usuarios extends Table {
  TextColumn get uuid => text()();
  TextColumn get nombre => text()();
  TextColumn get email => text()();
  TextColumn get rol => text().withDefault(const Constant('VENDEDOR'))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  /// Hash PBKDF2 de la contraseña, calculado **en el dispositivo** con su
  /// propia sal. Permite iniciar sesión sin red. El hash del servidor jamás
  /// viaja hasta aquí: si robaran el teléfono, no obtendrían la credencial del
  /// servidor, sólo un derivado local.
  TextColumn get passwordHashLocal => text().nullable()();
  TextColumn get saltLocal => text().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

class Categorias extends Table {
  TextColumn get uuid => text()();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#6750A4'))();
  TextColumn get icono => text().nullable()();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

// Sin esto Drift generaría `Proveedore`: su singularización quita la «s» final
// sin saber español.
@DataClassName('Proveedor')
class Proveedores extends Table {
  TextColumn get uuid => text()();
  TextColumn get nombre => text()();
  TextColumn get nit => text().nullable()();
  TextColumn get contacto => text().nullable()();
  TextColumn get telefono => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get direccion => text().nullable()();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'idx_productos_nombre', columns: {#nombre})
@TableIndex(name: 'idx_productos_sku', columns: {#sku})
@TableIndex(name: 'idx_productos_stock', columns: {#stockActual})
class Productos extends Table {
  TextColumn get uuid => text()();
  TextColumn get sku => text()();
  TextColumn get nombre => text()();

  /// Copia en minúsculas y sin tildes de `nombre`, para que la búsqueda
  /// «gaseosa» encuentre «Gaseosa» y «cafe» encuentre «Café» sin recorrer
  /// 10.000 filas en Dart. SQLite no normaliza Unicode por su cuenta.
  TextColumn get nombreBusqueda => text().withDefault(const Constant(''))();

  TextColumn get descripcion => text().nullable()();
  TextColumn get categoriaUuid => text().nullable()();
  TextColumn get unidadMedida => text().withDefault(const Constant('UND'))();

  IntColumn get precioCompra => integer().withDefault(const Constant(0))();
  IntColumn get precioVenta => integer().withDefault(const Constant(0))();
  IntColumn get tasaIva => integer().withDefault(const Constant(1900))();

  /// Proyección local. Sólo la escribe `InventarioDao._aplicarMovimiento`.
  IntColumn get stockActual => integer().withDefault(const Constant(0))();
  IntColumn get stockMinimo => integer().withDefault(const Constant(0))();
  IntColumn get stockMaximo => integer().nullable()();

  TextColumn get imagenUrl => text().nullable()();

  /// Ruta en el almacenamiento del dispositivo mientras la foto no se ha
  /// subido. La app muestra ésta hasta que la sincronización devuelve la URL.
  TextColumn get imagenLocal => text().nullable()();

  TextColumn get ubicacion => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'idx_codigos_codigo', columns: {#codigo}, unique: true)
class ProductoCodigos extends Table {
  TextColumn get uuid => text()();
  TextColumn get productoUuid => text()();
  TextColumn get codigo => text()();
  TextColumn get tipo => text().withDefault(const Constant('INTERNO'))();
  BoolColumn get esPrincipal => boolean().withDefault(const Constant(false))();

  /// Unidades que representa el código: la caja de 12 lleva `12000` (12,000).
  IntColumn get factor => integer().withDefault(const Constant(1000))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

// ─── Operación ───────────────────────────────────────────────────────────────

@TableIndex(name: 'idx_ventas_fecha', columns: {#fechaLocal})
@TableIndex(name: 'idx_ventas_pendiente', columns: {#sincronizadaEn})
class Ventas extends Table {
  TextColumn get uuid => text()();
  TextColumn get numero => text()();
  TextColumn get usuarioUuid => text().nullable()();
  TextColumn get dispositivoUuid => text().nullable()();
  TextColumn get clienteNombre => text().nullable()();
  TextColumn get clienteDocumento => text().nullable()();

  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get descuentoTotal => integer().withDefault(const Constant(0))();
  IntColumn get impuestoTotal => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  IntColumn get costoTotal => integer().withDefault(const Constant(0))();

  TextColumn get metodoPago => text().withDefault(const Constant('EFECTIVO'))();
  IntColumn get montoRecibido => integer().nullable()();
  IntColumn get cambio => integer().nullable()();

  TextColumn get estado => text().withDefault(const Constant('COMPLETADA'))();
  TextColumn get anulaAVentaUuid => text().nullable()();
  TextColumn get motivoAnulacion => text().nullable()();
  TextColumn get notas => text().nullable()();

  DateTimeColumn get fecha => dateTime()();
  TextColumn get fechaLocal => text()();
  BoolColumn get creadaOffline => boolean().withDefault(const Constant(true))();

  /// `null` mientras la venta no haya llegado al servidor. Es lo que cuenta el
  /// chip «N pendientes».
  DateTimeColumn get sincronizadaEn => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'idx_detalles_venta', columns: {#ventaUuid})
class VentaDetalles extends Table {
  TextColumn get uuid => text()();
  TextColumn get ventaUuid => text()();
  TextColumn get productoUuid => text().nullable()();
  IntColumn get linea => integer().withDefault(const Constant(1))();

  /// Instantánea del nombre al momento de vender: si mañana renombran el
  /// producto, el ticket histórico no debe cambiar.
  TextColumn get descripcion => text()();
  TextColumn get skuSnapshot => text().nullable()();

  IntColumn get cantidad => integer()();
  IntColumn get precioUnitario => integer()();
  IntColumn get costoUnitario => integer().withDefault(const Constant(0))();
  IntColumn get descuento => integer().withDefault(const Constant(0))();
  IntColumn get tasaIva => integer().withDefault(const Constant(0))();
  IntColumn get baseGravable => integer().withDefault(const Constant(0))();
  IntColumn get impuesto => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'idx_mov_producto', columns: {#productoUuid})
@TableIndex(name: 'idx_mov_fecha', columns: {#fechaLocal})
class Movimientos extends Table {
  TextColumn get uuid => text()();
  TextColumn get productoUuid => text()();
  TextColumn get tipo => text()();

  /// Con signo: positivo suma stock, negativo lo resta.
  IntColumn get cantidad => integer()();

  IntColumn get costoUnitario => integer().nullable()();
  IntColumn get precioUnitario => integer().nullable()();
  IntColumn get stockAnterior => integer().nullable()();
  IntColumn get stockResultante => integer().nullable()();

  TextColumn get ventaUuid => text().nullable()();
  TextColumn get proveedorUuid => text().nullable()();
  TextColumn get usuarioUuid => text().nullable()();
  TextColumn get lote => text().nullable()();
  TextColumn get venceEl => text().nullable()();
  TextColumn get documentoRef => text().nullable()();
  TextColumn get motivo => text().nullable()();

  DateTimeColumn get fecha => dateTime()();
  TextColumn get fechaLocal => text()();
  BoolColumn get creadoOffline => boolean().withDefault(const Constant(true))();
  DateTimeColumn get sincronizadoEn => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

class Alertas extends Table {
  TextColumn get uuid => text()();
  TextColumn get tipo => text()();
  TextColumn get severidad => text().withDefault(const Constant('ADVERTENCIA'))();
  TextColumn get productoUuid => text().nullable()();
  TextColumn get ventaUuid => text().nullable()();
  TextColumn get mensaje => text()();
  DateTimeColumn get resueltaEn => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {uuid};
}

// ─── Sincronización ──────────────────────────────────────────────────────────

/// Cola de salida.
///
/// Cada mutación local escribe su fila de dominio **y** una fila aquí, dentro
/// de la MISMA transacción. Si la app muere en medio, o se guardan las dos o no
/// se guarda ninguna: nunca queda una venta sin encolar ni un encolado sin venta.
@TableIndex(name: 'idx_outbox_pendientes', columns: {#estado, #proximoIntento})
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Clave de idempotencia. El servidor la usa para no aplicar dos veces el
  /// mismo efecto cuando se pierde la respuesta y el cliente reintenta.
  TextColumn get clientOpId => text().unique()();

  TextColumn get tipo => text()();
  TextColumn get entidad => text()();
  TextColumn get entidadUuid => text().nullable()();
  TextColumn get payload => text()();

  IntColumn get intentos => integer().withDefault(const Constant(0))();
  TextColumn get ultimoError => text().nullable()();
  TextColumn get codigoError => text().nullable()();

  /// PENDIENTE · ENVIANDO · RECHAZADA
  TextColumn get estado => text().withDefault(const Constant('PENDIENTE'))();

  DateTimeColumn get proximoIntento => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

/// Cursor keyset por entidad para la bajada delta.
@DataClassName('SyncCursor')
class SyncCursores extends Table {
  TextColumn get entidad => text()();
  DateTimeColumn get cursorT => dateTime()();
  IntColumn get cursorI => integer().withDefault(const Constant(0))();
  DateTimeColumn get ultimoSync => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entidad};
}

class Configuracion extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();
  TextColumn get tipo => text().withDefault(const Constant('STRING'))();

  @override
  Set<Column> get primaryKey => {clave};
}

/// Estado del dispositivo. Una única fila (id = 1).
class EstadoApp extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get usuarioUuid => text().nullable()();
  TextColumn get dispositivoUuid => text().nullable()();

  /// Prefijo asignado por el servidor para numerar ventas sin colisionar con
  /// otras cajas: `A1-000042`.
  TextColumn get prefijoFolio => text().nullable()();
  IntColumn get secuenciaFolio => integer().withDefault(const Constant(0))();

  /// Hasta cuándo se puede operar sin volver a ver el servidor.
  DateTimeColumn get offlineValidoHasta => dateTime().nullable()();
  DateTimeColumn get ultimoSyncExitoso => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Usuarios,
    Categorias,
    Proveedores,
    Productos,
    ProductoCodigos,
    Ventas,
    VentaDetalles,
    Movimientos,
    Alertas,
    SyncOutbox,
    SyncCursores,
    Configuracion,
    EstadoApp,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'inventario_pos'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(estadoApp).insert(
            const EstadoAppCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
        beforeOpen: (details) async {
          // Las claves foráneas no están declaradas entre tablas a propósito
          // (la sincronización puede traer un detalle antes que su venta), pero
          // WAL sí importa: permite leer mientras el motor de sincronización
          // escribe, así la lista de productos no se congela durante un pull.
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
          if (details.wasCreated) {
            await into(estadoApp).insert(
              const EstadoAppCompanion(id: Value(1)),
              mode: InsertMode.insertOrIgnore,
            );
          }
        },
      );

  /// Borra todo salvo el estado del dispositivo. Se usa al cerrar sesión de
  /// forma definitiva o al cambiar de servidor.
  Future<void> limpiarDatos() async {
    await transaction(() async {
      final tablas = <TableInfo<Table, dynamic>>[
        ventaDetalles, ventas, movimientos, alertas, productoCodigos,
        productos, categorias, proveedores, usuarios, syncOutbox,
        syncCursores, configuracion,
      ];
      for (final tabla in tablas) {
        await delete(tabla).go();
      }
    });
  }
}

/// Normaliza texto para búsqueda: minúsculas y sin tildes.
///
/// SQLite compara «Café» y «cafe» como distintos, y `LIKE` sin normalizar
/// obligaría al usuario a escribir los acentos exactos. Se guarda una columna
/// ya normalizada en lugar de normalizar en cada consulta.
String normalizarBusqueda(String texto) {
  const conAcento = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const sinAcento = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';
  final buffer = StringBuffer();
  for (final rune in texto.runes) {
    final ch = String.fromCharCode(rune);
    final i = conAcento.indexOf(ch);
    buffer.write(i >= 0 ? sinAcento[i] : ch);
  }
  return buffer.toString().toLowerCase().trim();
}
