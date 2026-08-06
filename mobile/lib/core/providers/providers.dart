import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/inventario_dao.dart';
import '../database/daos/outbox_dao.dart';
import '../database/daos/productos_dao.dart';
import '../database/daos/reportes_dao.dart';
import '../database/daos/sync_dao.dart';
import '../database/daos/ventas_dao.dart';
import '../network/api_client.dart';
import '../network/token_store.dart';
import '../sync/connectivity_service.dart';
import '../sync/estado_sync.dart';
import '../sync/sync_engine.dart';

/// Inyección de dependencias.
///
/// `appDatabaseProvider` y `apiClientProvider` se sobrescriben en `main()` con
/// las instancias ya inicializadas: abrir la base y leer el almacén seguro son
/// operaciones asíncronas y no pueden ocurrir dentro de un provider síncrono.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Sobrescribe appDatabaseProvider en main()');
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  throw UnimplementedError('Sobrescribe tokenStoreProvider en main()');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('Sobrescribe apiClientProvider en main()');
});

// ── DAOs ─────────────────────────────────────────────────────────────────────

final outboxDaoProvider = Provider<OutboxDao>(
  (ref) => OutboxDao(ref.watch(appDatabaseProvider)),
);

final productosDaoProvider = Provider<ProductosDao>(
  (ref) => ProductosDao(ref.watch(appDatabaseProvider), ref.watch(outboxDaoProvider)),
);

final inventarioDaoProvider = Provider<InventarioDao>(
  (ref) => InventarioDao(ref.watch(appDatabaseProvider), ref.watch(outboxDaoProvider)),
);

final ventasDaoProvider = Provider<VentasDao>(
  (ref) => VentasDao(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxDaoProvider),
    ref.watch(inventarioDaoProvider),
  ),
);

final syncDaoProvider = Provider<SyncDao>(
  (ref) => SyncDao(ref.watch(appDatabaseProvider)),
);

final reportesDaoProvider = Provider<ReportesDao>(
  (ref) => ReportesDao(ref.watch(appDatabaseProvider)),
);

// ── Sincronización ───────────────────────────────────────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final servicio = ConnectivityService(ref.watch(apiClientProvider));
  ref.onDispose(servicio.dispose);
  return servicio;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final motor = SyncEngine(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(apiClientProvider),
    outbox: ref.watch(outboxDaoProvider),
    sync: ref.watch(syncDaoProvider),
    ventas: ref.watch(ventasDaoProvider),
    conectividad: ref.watch(connectivityServiceProvider),
  );
  ref.onDispose(motor.dispose);
  return motor;
});

/// Estado del chip de sincronización. Es un `ChangeNotifier`, así que se
/// escucha con un `StreamController` puente para exponerlo como provider.
final estadoSyncProvider = StreamProvider<EstadoSync>((ref) {
  final motor = ref.watch(syncEngineProvider);
  final controlador = StreamController<EstadoSync>();

  void emitir() {
    if (!controlador.isClosed) controlador.add(motor.estado);
  }

  motor.addListener(emitir);
  emitir();

  ref.onDispose(() {
    motor.removeListener(emitir);
    controlador.close();
  });

  return controlador.stream;
});

/// Operaciones que el servidor rechazó de forma definitiva.
final operacionesRechazadasProvider = StreamProvider(
  (ref) => ref.watch(outboxDaoProvider).observarRechazadas(),
);

// ── Configuración del negocio ────────────────────────────────────────────────

final configuracionProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(syncDaoProvider).observarConfiguracion(),
);

final nombreNegocioProvider = Provider<String>((ref) {
  return ref.watch(configuracionProvider).maybeWhen(
        data: (c) => c['nombre_negocio'] ?? 'Mi Negocio',
        orElse: () => 'Mi Negocio',
      );
});

/// Nombre de cada usuario, indexado por UUID.
///
/// Sale de SQLite —los usuarios llegan en el pull, igual que el catálogo—, así
/// que el historial sigue diciendo quién hizo cada venta aunque no haya red.
/// Es una tabla pequeña: se lee entera una vez y la lista de ventas la consulta
/// en memoria, en lugar de hacer un join por fila.
final nombresUsuariosProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.usuarios).watch().map(
        (filas) => {for (final u in filas) u.uuid: u.nombre},
      );
});

/// Estado del dispositivo: prefijo de folio, último sync, usuario activo.
final estadoAppProvider = StreamProvider<EstadoAppData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.estadoApp)..where((t) => t.id.equals(1))).watchSingleOrNull();
});
