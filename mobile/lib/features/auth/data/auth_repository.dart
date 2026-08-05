import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_store.dart';
import '../../../core/security/password_hash.dart';
import '../domain/sesion.dart';

/// Autenticación con soporte offline real.
///
/// El JWT caduca a los 15 minutos; el turno de un vendedor dura ocho horas y
/// puede transcurrir entero sin señal. Por eso la sesión de la APP y la sesión
/// de la API son cosas distintas:
///
///  · El JWT sólo sirve para hablar con el servidor.
///  · Para entrar a la app basta con verificar la contraseña contra un derivado
///    PBKDF2 guardado en el dispositivo la primera vez que se inició sesión con
///    red, dentro de una ventana de gracia.
class AuthRepository {
  AuthRepository({
    required AppDatabase db,
    required ApiClient api,
    required TokenStore tokens,
  })  : _db = db,
        _api = api,
        _tokens = tokens;

  final AppDatabase _db;
  final ApiClient _api;
  final TokenStore _tokens;

  static const _uuid = Uuid();
  static const _kUltimoEmail = 'ultimo_email';
  static const _kDispositivoUuid = 'dispositivo_uuid';

  /// UUID estable del dispositivo. Se genera una vez y se conserva: es la clave
  /// con la que el servidor le asigna su prefijo de folio.
  Future<String> _uuidDispositivo() async {
    final prefs = await SharedPreferences.getInstance();
    var uuid = prefs.getString(_kDispositivoUuid);
    if (uuid == null) {
      uuid = _uuid.v7();
      await prefs.setString(_kDispositivoUuid, uuid);
    }
    return uuid;
  }

  Future<Map<String, dynamic>> _datosDispositivo() async {
    final uuid = await _uuidDispositivo();
    var nombre = 'Dispositivo';
    var plataforma = 'android';
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      nombre = '${info.manufacturer} ${info.model}';
      plataforma = 'Android ${info.version.release}';
    } catch (_) {
      // En pruebas o en otra plataforma se queda con los valores por defecto.
    }
    var version = '1.0.0';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}

    return {
      'uuid': uuid,
      'nombre': nombre,
      'plataforma': plataforma,
      'app_version': version,
    };
  }

  /// Inicia sesión. Intenta primero contra el servidor; si no hay red, cae a la
  /// verificación local.
  Future<ResultadoLogin> iniciarSesion(String email, String password) async {
    final correo = email.trim().toLowerCase();

    try {
      return await _loginEnLinea(correo, password);
    } on ApiException catch (e) {
      // Credenciales rechazadas por el servidor: no tiene sentido caer al modo
      // offline. Si la contraseña cambió, la copia local está obsoleta.
      if (!e.esDeRed) {
        if (e.status == 401 || e.status == 403) {
          return ResultadoLogin.error(e.mensajeUsuario);
        }
        rethrow;
      }
      return _loginOffline(correo, password);
    }
  }

  Future<ResultadoLogin> _loginEnLinea(String email, String password) async {
    final dispositivo = await _datosDispositivo();
    _api.dispositivoUuid = dispositivo['uuid'] as String;

    final respuesta = await _api.post(
      '/auth/login',
      sinAuth: true,
      cuerpo: {'email': email, 'password': password, 'dispositivo': dispositivo},
    );

    final datos = respuesta['data'] as Map<String, dynamic>;
    final usuario = datos['usuario'] as Map<String, dynamic>;

    await _tokens.guardarTokens(
      accessToken: datos['access_token'] as String,
      refreshToken: datos['refresh_token'] as String,
      refreshExpira: DateTime.tryParse(datos['refresh_expira'] as String? ?? ''),
    );

    // Derivado local de la contraseña, para poder entrar sin red la próxima vez.
    final salt = PasswordHash.generarSalt();
    final hash = await PasswordHash.derivar(password, salt);

    final diasGracia = (datos['offline_grace_days'] as num?)?.toInt() ??
        AppConfig.diasGraciaOffline;
    final valido = DateTime.now().toUtc().add(Duration(days: diasGracia));

    final esPrimeraVez = await _esDispositivoNuevo(usuario['uuid'] as String);

    await _db.transaction(() async {
      await _db.into(_db.usuarios).insertOnConflictUpdate(
            UsuariosCompanion.insert(
              uuid: usuario['uuid'] as String,
              nombre: usuario['nombre'] as String,
              email: usuario['email'] as String,
              rol: Value(usuario['rol'] as String? ?? 'VENDEDOR'),
              activo: const Value(true),
              passwordHashLocal: Value(hash),
              saltLocal: Value(salt),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

      await (_db.update(_db.estadoApp)..where((t) => t.id.equals(1))).write(
        EstadoAppCompanion(
          usuarioUuid: Value(usuario['uuid'] as String),
          dispositivoUuid: Value(dispositivo['uuid'] as String),
          prefijoFolio: Value((datos['dispositivo'] as Map?)?['prefijo_folio'] as String?),
          offlineValidoHasta: Value(valido),
        ),
      );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUltimoEmail, email);

    return ResultadoLogin.ok(
      Sesion(
        usuarioUuid: usuario['uuid'] as String,
        nombre: usuario['nombre'] as String,
        email: usuario['email'] as String,
        rol: RolUsuario.desde(usuario['rol'] as String?),
        enLinea: true,
        validaHasta: valido,
      ),
      necesitaDescargaInicial: esPrimeraVez,
    );
  }

  Future<ResultadoLogin> _loginOffline(String email, String password) async {
    final usuario = await (_db.select(_db.usuarios)
          ..where((t) => t.email.equals(email) & t.deletedAt.isNull()))
        .getSingleOrNull();

    if (usuario == null || usuario.passwordHashLocal == null || usuario.saltLocal == null) {
      return ResultadoLogin.error(
        'No hay conexión y este usuario nunca ha iniciado sesión en este '
        'dispositivo. Conéctate a internet la primera vez.',
      );
    }

    if (!usuario.activo) {
      return ResultadoLogin.error('La cuenta está desactivada');
    }

    final estado = await (_db.select(_db.estadoApp)..where((t) => t.id.equals(1))).getSingle();
    final limite = estado.offlineValidoHasta;
    if (limite != null && DateTime.now().toUtc().isAfter(limite)) {
      return ResultadoLogin.error(
        'Llevas demasiado tiempo sin conectarte. Conéctate a internet para '
        'seguir usando la app.',
      );
    }

    final valida = await PasswordHash.verificar(
      password,
      usuario.saltLocal!,
      usuario.passwordHashLocal!,
    );
    if (!valida) return ResultadoLogin.error('Correo o contraseña incorrectos');

    await (_db.update(_db.estadoApp)..where((t) => t.id.equals(1)))
        .write(EstadoAppCompanion(usuarioUuid: Value(usuario.uuid)));

    return ResultadoLogin.ok(
      Sesion(
        usuarioUuid: usuario.uuid,
        nombre: usuario.nombre,
        email: usuario.email,
        rol: RolUsuario.desde(usuario.rol),
        enLinea: false,
        validaHasta: limite,
      ),
    );
  }

  Future<bool> _esDispositivoNuevo(String usuarioUuid) async {
    final n = await _db.customSelect(
      'SELECT COUNT(*) AS n FROM productos',
      readsFrom: {_db.productos},
    ).getSingle();
    return n.read<int>('n') == 0;
  }

  /// Restaura la sesión al abrir la app. No requiere red.
  Future<Sesion?> sesionGuardada() async {
    final estado =
        await (_db.select(_db.estadoApp)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (estado?.usuarioUuid == null) return null;

    final usuario = await (_db.select(_db.usuarios)
          ..where((t) => t.uuid.equals(estado!.usuarioUuid!)))
        .getSingleOrNull();
    if (usuario == null || !usuario.activo) return null;

    _api.dispositivoUuid = estado!.dispositivoUuid;

    // Fuera de la ventana de gracia hay que volver a autenticarse con red.
    final limite = estado.offlineValidoHasta;
    if (limite != null && DateTime.now().toUtc().isAfter(limite)) {
      final refresh = await _tokens.refreshToken;
      if (refresh == null) return null;
    }

    return Sesion(
      usuarioUuid: usuario.uuid,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: RolUsuario.desde(usuario.rol),
      enLinea: false,
      validaHasta: limite,
    );
  }

  /// Cierra sesión. `borrarDatos` sólo debería usarse al cambiar de negocio o
  /// de servidor: **destruye las ventas que no se hayan sincronizado**.
  Future<void> cerrarSesion({bool borrarDatos = false}) async {
    try {
      final refresh = await _tokens.refreshToken;
      if (refresh != null) {
        await _api.post('/auth/logout', cuerpo: {'refresh_token': refresh});
      }
    } catch (_) {
      // Sin red no se puede revocar en el servidor; el token caducará solo.
    }

    await _tokens.limpiar();
    await (_db.update(_db.estadoApp)..where((t) => t.id.equals(1)))
        .write(const EstadoAppCompanion(usuarioUuid: Value(null)));

    if (borrarDatos) {
      await _db.limpiarDatos();
      await (_db.update(_db.estadoApp)..where((t) => t.id.equals(1)))
          .write(const EstadoAppCompanion(secuenciaFolio: Value(0)));
    }
  }

  /// Cuántas operaciones se perderían al borrar los datos locales. Se enseña
  /// antes de confirmar un cierre de sesión destructivo.
  Future<int> operacionesSinEnviar() async {
    final fila = await _db.customSelect(
      "SELECT COUNT(*) AS n FROM sync_outbox WHERE estado IN ('PENDIENTE','ENVIANDO')",
      readsFrom: {_db.syncOutbox},
    ).getSingle();
    return fila.read<int>('n');
  }

  Future<String?> ultimoEmail() async =>
      (await SharedPreferences.getInstance()).getString(_kUltimoEmail);

  Future<void> cambiarPassword(String actual, String nueva) async {
    await _api.post(
      '/auth/password',
      cuerpo: {'password_actual': actual, 'password_nueva': nueva},
    );

    // Se regenera el derivado local: si no, el login offline seguiría aceptando
    // la contraseña vieja.
    final estado = await (_db.select(_db.estadoApp)..where((t) => t.id.equals(1))).getSingle();
    if (estado.usuarioUuid != null) {
      final salt = PasswordHash.generarSalt();
      final hash = await PasswordHash.derivar(nueva, salt);
      await (_db.update(_db.usuarios)..where((t) => t.uuid.equals(estado.usuarioUuid!)))
          .write(UsuariosCompanion(
        passwordHashLocal: Value(hash),
        saltLocal: Value(salt),
      ));
    }
  }
}
