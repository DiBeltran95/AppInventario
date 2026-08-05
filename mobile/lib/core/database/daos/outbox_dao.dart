import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import '../app_database.dart';

/// Cola de salida.
///
/// Regla no negociable: `encolar` se llama **dentro de la misma transacción**
/// que escribe la fila de dominio. Si la app muere entre ambas, la transacción
/// se revierte entera y no queda ni una venta sin encolar ni un encolado
/// huérfano.
class OutboxDao {
  OutboxDao(this.db);

  final AppDatabase db;
  static const _uuid = Uuid();

  /// Encola una operación. Devuelve el `client_op_id` que la hace idempotente
  /// en el servidor.
  Future<String> encolar(
    String tipo, {
    required String entidad,
    String? entidadUuid,
    required Map<String, dynamic> payload,
  }) async {
    final clientOpId = _uuid.v7();
    await db.into(db.syncOutbox).insert(
          SyncOutboxCompanion.insert(
            clientOpId: clientOpId,
            tipo: tipo,
            entidad: entidad,
            entidadUuid: Value(entidadUuid),
            payload: jsonEncode(payload),
          ),
        );
    return clientOpId;
  }

  /// Operaciones listas para enviar, en orden FIFO estricto.
  ///
  /// El orden importa: crear un producto y venderlo son dos operaciones, y la
  /// segunda falla si la primera no llegó antes.
  Future<List<SyncOutboxData>> pendientes({int limite = AppConfig.loteSubida}) {
    final ahora = DateTime.now();
    return (db.select(db.syncOutbox)
          ..where((t) =>
              t.estado.isIn(['PENDIENTE', 'ENVIANDO']) &
              t.proximoIntento.isSmallerOrEqualValue(ahora))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limite))
        .get();
  }

  Stream<int> contarPendientes() {
    final consulta = db.selectOnly(db.syncOutbox)
      ..addColumns([db.syncOutbox.id.count()])
      ..where(db.syncOutbox.estado.equals('PENDIENTE') |
          db.syncOutbox.estado.equals('ENVIANDO'));
    return consulta
        .map((f) => f.read(db.syncOutbox.id.count()) ?? 0)
        .watchSingle();
  }

  Stream<int> contarRechazadas() {
    final consulta = db.selectOnly(db.syncOutbox)
      ..addColumns([db.syncOutbox.id.count()])
      ..where(db.syncOutbox.estado.equals('RECHAZADA'));
    return consulta
        .map((f) => f.read(db.syncOutbox.id.count()) ?? 0)
        .watchSingle();
  }

  Stream<List<SyncOutboxData>> observarRechazadas() =>
      (db.select(db.syncOutbox)
            ..where((t) => t.estado.equals('RECHAZADA'))
            ..orderBy([(t) => OrderingTerm.desc(t.creadoEn)]))
          .watch();

  Future<void> marcarEnviando(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    await (db.update(db.syncOutbox)..where((t) => t.id.isIn(ids)))
        .write(const SyncOutboxCompanion(estado: Value('ENVIANDO')));
  }

  /// La operación se aplicó en el servidor: sale de la cola.
  Future<void> completar(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    await (db.delete(db.syncOutbox)..where((t) => t.id.isIn(ids))).go();
  }

  /// Error TRANSITORIO: se reintenta con backoff exponencial y jitter.
  ///
  /// El jitter evita que treinta dispositivos que recuperan la red en el mismo
  /// instante golpeen el servidor a la vez.
  Future<void> reintentarMasTarde(SyncOutboxData fila, String error, {String? codigo}) async {
    final intentos = fila.intentos + 1;

    if (intentos >= AppConfig.maxIntentos) {
      return rechazar(fila.id, 'Se agotaron los reintentos: $error', codigo: codigo);
    }

    final baseMs = AppConfig.backoffBase.inMilliseconds * (1 << (intentos - 1).clamp(0, 20));
    final topeMs = AppConfig.backoffMaximo.inMilliseconds;
    final esperaMs = baseMs.clamp(0, topeMs);
    final jitter = (esperaMs * 0.2 * (DateTime.now().microsecond / 1000000)).round();

    await (db.update(db.syncOutbox)..where((t) => t.id.equals(fila.id))).write(
      SyncOutboxCompanion(
        estado: const Value('PENDIENTE'),
        intentos: Value(intentos),
        ultimoError: Value(error),
        codigoError: Value(codigo),
        proximoIntento: Value(DateTime.now().add(Duration(milliseconds: esperaMs + jitter))),
      ),
    );
  }

  /// Error PERMANENTE: reintentarlo no cambiaría nada y bloquearía la cola.
  /// Se aparta y se muestra al usuario en «Elementos con problema».
  Future<void> rechazar(int id, String error, {String? codigo}) async {
    await (db.update(db.syncOutbox)..where((t) => t.id.equals(id))).write(
      SyncOutboxCompanion(
        estado: const Value('RECHAZADA'),
        ultimoError: Value(error),
        codigoError: Value(codigo),
      ),
    );
  }

  /// Reencola una operación rechazada tras corregir la causa.
  Future<void> reintentarRechazada(int id) async {
    await (db.update(db.syncOutbox)..where((t) => t.id.equals(id))).write(
      SyncOutboxCompanion(
        estado: const Value('PENDIENTE'),
        intentos: const Value(0),
        ultimoError: const Value(null),
        proximoIntento: Value(DateTime.now()),
      ),
    );
  }

  Future<void> descartar(int id) =>
      (db.delete(db.syncOutbox)..where((t) => t.id.equals(id))).go();

  /// Devuelve a PENDIENTE lo que quedó en ENVIANDO. Se llama al arrancar: si la
  /// app murió a mitad de un envío, esas filas seguirían bloqueadas para
  /// siempre. Reenviarlas es seguro gracias al `client_op_id`.
  Future<int> recuperarEnviandoHuerfanas() {
    return (db.update(db.syncOutbox)..where((t) => t.estado.equals('ENVIANDO'))).write(
      SyncOutboxCompanion(
        estado: const Value('PENDIENTE'),
        proximoIntento: Value(DateTime.now()),
      ),
    );
  }
}
