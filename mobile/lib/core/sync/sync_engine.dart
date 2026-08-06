import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/daos/outbox_dao.dart';
import '../database/daos/productos_dao.dart';
import '../database/daos/sync_dao.dart';
import '../database/daos/ventas_dao.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'connectivity_service.dart';
import 'estado_sync.dart';

/// Motor de sincronización.
///
/// Ciclo: **subir primero, bajar después**. Ese orden importa. Si se bajara
/// primero, el pull traería la versión del servidor de un producto que el
/// dispositivo acaba de editar y aún no ha enviado, y la sobrescribiría con
/// datos viejos.
class SyncEngine extends ChangeNotifier {
  SyncEngine({
    required AppDatabase db,
    required ApiClient api,
    required OutboxDao outbox,
    required SyncDao sync,
    required VentasDao ventas,
    required ProductosDao productos,
    required ConnectivityService conectividad,
  })  : _db = db,
        _api = api,
        _outbox = outbox,
        _sync = sync,
        _ventas = ventas,
        _productos = productos,
        _conectividad = conectividad;

  final AppDatabase _db;
  final ApiClient _api;
  final OutboxDao _outbox;
  final SyncDao _sync;
  final VentasDao _ventas;
  final ProductosDao _productos;
  final ConnectivityService _conectividad;

  EstadoSync _estado = const EstadoSync();
  EstadoSync get estado => _estado;

  Timer? _periodico;
  Timer? _debounce;
  StreamSubscription<bool>? _subConectividad;
  StreamSubscription<int>? _subPendientes;
  StreamSubscription<int>? _subRechazadas;
  bool _enMarcha = false;
  bool _iniciado = false;

  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;

    // Si la app murió a mitad de un envío, esas filas quedaron en ENVIANDO y no
    // volverían a salir nunca. Reenviarlas es seguro: el `client_op_id` impide
    // que el servidor las aplique dos veces.
    await _outbox.recuperarEnviandoHuerfanas();
    await _sync.purgarMovimientosDuplicadosDeVenta();

    _subPendientes = _outbox.contarPendientes().listen((n) {
      _fijar(_estado.copyWith(
        pendientes: n,
        fase: _calcularFase(pendientes: n),
      ));
    });

    _subRechazadas = _outbox.contarRechazadas().listen((n) {
      _fijar(_estado.copyWith(rechazadas: n));
    });

    _subConectividad = _conectividad.cambios.listen((hayRed) {
      _fijar(_estado.copyWith(fase: _calcularFase(hayRed: hayRed)));
      if (hayRed) {
        // Se recuperó la red: es el momento exacto que el usuario espera que
        // sus ventas «suban solas».
        unawaited(sincronizar(motivo: 'reconexión'));
      }
    });

    _periodico = Timer.periodic(AppConfig.intervaloSync, (_) {
      unawaited(sincronizar(motivo: 'periódica', silenciosa: true));
    });

    await _conectividad.iniciar();
    unawaited(sincronizar(motivo: 'arranque'));
  }

  /// Solicita una sincronización tras una mutación local, con rebote.
  /// Sin el rebote, añadir 20 artículos al carrito dispararía 20 peticiones.
  void solicitar() {
    _debounce?.cancel();
    _debounce = Timer(AppConfig.debounceSync, () {
      unawaited(sincronizar(motivo: 'cambio local', silenciosa: true));
    });
  }

  FaseSync _calcularFase({bool? hayRed, int? pendientes}) {
    final red = hayRed ?? _conectividad.hayRed;
    final n = pendientes ?? _estado.pendientes;
    if (!red) return FaseSync.sinConexion;
    if (_enMarcha) return FaseSync.sincronizando;
    return n > 0 ? FaseSync.pendiente : FaseSync.alDia;
  }

  void _fijar(EstadoSync nuevo) {
    _estado = nuevo;
    notifyListeners();
  }

  /// Ejecuta una pasada completa.
  Future<ResultadoSync> sincronizar({
    String motivo = 'manual',
    bool silenciosa = false,
  }) async {
    if (_enMarcha) return const ResultadoSync();

    if (!_conectividad.hayRed) {
      final vivo = await _conectividad.verificar();
      if (!vivo) {
        _fijar(_estado.copyWith(fase: FaseSync.sinConexion));
        return const ResultadoSync(error: 'Sin conexión');
      }
    }

    _enMarcha = true;
    _fijar(_estado.copyWith(
      fase: FaseSync.sincronizando,
      progresoTexto: 'Enviando…',
      limpiarError: true,
    ));

    var enviadas = 0;
    var rechazadas = 0;
    var recibidas = 0;
    String? error;

    try {
      final subida = await _subir();
      enviadas = subida.enviadas;
      rechazadas = subida.rechazadas;

      // Las fotos no van en la outbox JSON: se suben por multipart y luego se
      // encola un PRODUCTO_ACTUALIZAR con la URL pública.
      await _subirImagenesPendientes();
      final segunda = await _subir();
      enviadas += segunda.enviadas;
      rechazadas += segunda.rechazadas;

      _fijar(_estado.copyWith(progresoTexto: 'Descargando…'));
      recibidas = await _bajar();
      await _sync.purgarMovimientosDuplicadosDeVenta();

      await (_db.update(_db.estadoApp)..where((t) => t.id.equals(1)))
          .write(EstadoAppCompanion(ultimoSyncExitoso: Value(DateTime.now().toUtc())));
    } on ApiException catch (e) {
      error = e.mensajeUsuario;
      if (e.esDeRed) await _conectividad.verificar();
    } catch (e) {
      error = e.toString();
    } finally {
      _enMarcha = false;
      final pendientes = (await _outbox.pendientes(limite: 1)).length;
      _fijar(_estado.copyWith(
        fase: error != null
            ? (_conectividad.hayRed ? FaseSync.conError : FaseSync.sinConexion)
            : _calcularFase(pendientes: pendientes),
        ultimoSync: error == null ? DateTime.now() : null,
        ultimoError: error,
        limpiarError: error == null,
        limpiarProgreso: true,
      ));
    }

    if (kDebugMode && !silenciosa) {
      debugPrint('[sync:$motivo] ↑$enviadas ↓$recibidas ✗$rechazadas ${error ?? ''}');
    }

    return ResultadoSync(
      enviadas: enviadas,
      rechazadas: rechazadas,
      recibidas: recibidas,
      error: error,
    );
  }

  // ── Subida ────────────────────────────────────────────────────────────────

  Future<({int enviadas, int rechazadas})> _subir() async {
    var enviadas = 0;
    var rechazadas = 0;

    // Varios lotes por pasada: un dispositivo que estuvo una semana sin red
    // puede tener cientos de operaciones acumuladas.
    for (var lote = 0; lote < 20; lote++) {
      final pendientes = await _outbox.pendientes();
      if (pendientes.isEmpty) break;

      await _outbox.marcarEnviando(pendientes.map((p) => p.id));

      final Map<String, dynamic> respuesta;
      try {
        respuesta = await _api.post(
          '/sync/push',
          cuerpo: {
            'operaciones': pendientes
                .map((p) => {
                      'client_op_id': p.clientOpId,
                      'tipo': p.tipo,
                      'payload': jsonDecode(p.payload),
                      'creado_en': p.creadoEn.toUtc().toIso8601String(),
                    })
                .toList(),
          },
          // Un lote grande puede tardar; el servidor procesa las operaciones
          // en secuencia, cada una en su transacción.
          timeout: const Duration(seconds: 60),
        );
      } on ApiException catch (e) {
        // Fallo del lote completo (red, 5xx). Nada se aplicó o no sabemos qué
        // se aplicó; se reintenta todo. La idempotencia del servidor hace que
        // reenviar lo ya aplicado sea inofensivo.
        for (final p in pendientes) {
          await _outbox.reintentarMasTarde(p, e.mensaje, codigo: e.codigo);
        }
        rethrow;
      }

      final resultados = ((respuesta['data'] as Map)['resultados'] as List)
          .cast<Map<String, dynamic>>();
      final porOpId = {for (final p in pendientes) p.clientOpId: p};

      final completadas = <int>[];
      final ventasOk = <String>[];
      final movimientosOk = <String>[];
      final ventasParaMovimientos = <String>[];

      for (final r in resultados) {
        final fila = porOpId[r['client_op_id']];
        if (fila == null) continue;

        if (r['estado'] == 'OK') {
          completadas.add(fila.id);
          enviadas++;
          if (fila.entidad == 'ventas' && fila.entidadUuid != null) {
            ventasOk.add(fila.entidadUuid!);
            // Los movimientos de la venta (y de su reversa, si es anulación)
            // no son operaciones independientes: se marcan aquí.
            ventasParaMovimientos.add(fila.entidadUuid!);
            final payload = jsonDecode(fila.payload) as Map<String, dynamic>;
            final reversa = payload['uuid_reversa'] as String?;
            if (reversa != null) {
              ventasOk.add(reversa);
              ventasParaMovimientos.add(reversa);
            }
          } else if (fila.entidad == 'movimientos_inventario' && fila.entidadUuid != null) {
            movimientosOk.add(fila.entidadUuid!);
          }
        } else {
          final err = (r['error'] as Map?) ?? const {};
          final permanente = err['permanente'] == true;
          final mensaje = (err['mensaje'] as String?) ?? 'Rechazada por el servidor';
          final codigo = err['codigo'] as String?;

          if (permanente) {
            await _outbox.rechazar(fila.id, mensaje, codigo: codigo);
            rechazadas++;
          } else {
            await _outbox.reintentarMasTarde(fila, mensaje, codigo: codigo);
          }
        }
      }

      await _db.transaction(() async {
        await _outbox.completar(completadas);
        await _ventas.marcarSincronizadas(ventasOk);
        await _ventas.marcarMovimientosSincronizados(movimientosOk);
        await _ventas.marcarMovimientosDeVentasSincronizados(ventasParaMovimientos);
      });

      _fijar(_estado.copyWith(progresoTexto: 'Enviado $enviadas…'));

      // Si no se completó ninguna, seguir iterando sólo giraría en vacío.
      if (completadas.isEmpty) break;
    }

    return (enviadas: enviadas, rechazadas: rechazadas);
  }

  /// Sube fotos locales sin `imagen_url` y encola la URL para el resto de cajas.
  Future<void> _subirImagenesPendientes() async {
    final pendientes = await _productos.conImagenPendienteDeSubir();
    if (pendientes.isEmpty) return;

    _fijar(_estado.copyWith(progresoTexto: 'Subiendo fotos…'));

    for (final p in pendientes) {
      final ruta = p.imagenLocal;
      if (ruta == null) continue;
      final archivo = File(ruta);
      if (!await archivo.exists()) continue;

      try {
        final respuesta = await _api.subirImagen(archivo);
        final datos = respuesta['data'];
        final url = datos is Map ? datos['url'] as String? : null;
        if (url == null || url.isEmpty) continue;

        await _productos.actualizar(p.uuid, imagenUrl: url, imagenLocal: ruta);
      } catch (e) {
        if (kDebugMode) debugPrint('[sync] foto ${p.uuid}: $e');
        // Se reintenta en la próxima pasada; no tumba el resto del sync.
      }
    }
  }

  // ── Bajada ────────────────────────────────────────────────────────────────

  Future<int> _bajar() async {
    var total = 0;

    for (var pagina = 0; pagina < 50; pagina++) {
      final respuesta = await _api.post('/sync/pull', cuerpo: {
        'cursores': await _sync.cursores(),
        'limite': AppConfig.loteBajada,
        'dias_historial': AppConfig.diasHistorial,
      });

      final datos = respuesta['data'] as Map<String, dynamic>;
      final entidades = datos['entidades'] as Map<String, dynamic>;

      final aplicadas = await _sync.aplicarCambios(entidades);
      total += aplicadas;

      _fijar(_estado.copyWith(progresoTexto: 'Descargado $total…'));

      if (datos['hay_mas'] != true || aplicadas == 0) break;
    }

    return total;
  }

  /// Descarga completa desde cero. Se usa tras iniciar sesión por primera vez
  /// en un dispositivo, o al cambiar de servidor.
  Future<int> descargaInicial() async {
    await _sync.reiniciarCursores();
    _fijar(_estado.copyWith(fase: FaseSync.sincronizando, progresoTexto: 'Preparando datos…'));
    try {
      final n = await _bajar();
      _fijar(_estado.copyWith(fase: FaseSync.alDia, ultimoSync: DateTime.now(), limpiarProgreso: true));
      return n;
    } catch (e) {
      _fijar(_estado.copyWith(fase: FaseSync.conError, ultimoError: e.toString(), limpiarProgreso: true));
      rethrow;
    }
  }

  @override
  void dispose() {
    _periodico?.cancel();
    _debounce?.cancel();
    _subConectividad?.cancel();
    _subPendientes?.cancel();
    _subRechazadas?.cancel();
    super.dispose();
  }
}
