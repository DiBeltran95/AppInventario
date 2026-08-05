/// Configuración de la app.
///
/// La URL del servidor no se compila dentro del binario: se guarda en
/// preferencias y se puede cambiar desde Ajustes. Una tienda que mueve su
/// backend no debería necesitar un APK nuevo.
class AppConfig {
  const AppConfig._();

  static const String nombreApp = 'Inventario POS';
  static const String versionApi = '/api/v1';

  /// Prefijo de los QR emitidos por esta app. Debe coincidir con `QR_PREFIX`
  /// del backend (backend/src/config/constants.js).
  static const String qrPrefix = 'inv://p/';

  /// Zona horaria del negocio. Determina el «día hábil» de los reportes.
  static const String zonaNegocio = 'America/Bogota';

  /// El desfase se aplica de forma fija porque Colombia no usa horario de
  /// verano. Para desplegar en un país que sí lo use, hay que sustituir esto
  /// por el paquete `timezone`.
  static const Duration desfaseNegocio = Duration(hours: -5);

  /// Servidor de producción.
  ///
  /// **HTTPS obligatorio**: en release, Android bloquea el tráfico en claro, y
  /// por aquí viajan credenciales y ventas.
  static const String urlProduccion = 'https://inventarios.alwaysdata.net';

  /// Valor inicial de la URL del servidor.
  ///
  /// Apunta a producción incluso en debug: es lo que hace que un APK recién
  /// instalado funcione sin tocar Ajustes. Para desarrollar contra un backend
  /// local se cambia desde la propia app (login → «Configurar servidor»), y la
  /// elección queda guardada en el almacén seguro.
  ///
  /// Si necesitas que una compilación concreta nazca apuntando a otro sitio:
  ///   flutter build apk --dart-define=API_URL=http://10.0.2.2:3100
  ///
  /// Recuerda que en el emulador de Android `localhost` es el propio emulador:
  /// la máquina anfitriona se alcanza en 10.0.2.2. Es el error nº 1 al probar
  /// una app contra un backend local.
  static String get urlPorDefecto => const String.fromEnvironment(
        'API_URL',
        defaultValue: urlProduccion,
      );

  // ── Sincronización ────────────────────────────────────────────────────────

  /// Operaciones por lote de subida. El servidor acepta hasta 200.
  static const int loteSubida = 50;

  /// Filas por entidad y por página de bajada.
  static const int loteBajada = 500;

  /// Días de historial de ventas y movimientos que se conservan en el
  /// dispositivo. Más allá, los reportes se consultan en el servidor.
  static const int diasHistorial = 90;

  /// Espera tras una mutación local antes de intentar sincronizar. Evita
  /// disparar una petición por cada artículo añadido al carrito.
  static const Duration debounceSync = Duration(seconds: 3);

  /// Sincronización periódica con la app en primer plano.
  static const Duration intervaloSync = Duration(minutes: 5);

  /// Backoff exponencial ante fallo transitorio: 5 s, 10 s, 20 s… hasta 15 min.
  static const Duration backoffBase = Duration(seconds: 5);
  static const Duration backoffMaximo = Duration(minutes: 15);

  /// Tras esto, la operación se marca RECHAZADA aunque el error fuera
  /// transitorio: algo va mal de forma persistente y hay que avisar al usuario
  /// en lugar de reintentar para siempre.
  static const int maxIntentos = 12;

  /// Tiempo máximo del sondeo de conectividad real (`/health`). Corto a
  /// propósito: si el servidor no contesta en 4 s, para el usuario no hay red.
  static const Duration timeoutSalud = Duration(seconds: 4);

  static const Duration timeoutConexion = Duration(seconds: 10);
  static const Duration timeoutRespuesta = Duration(seconds: 30);

  // ── Escaneo ───────────────────────────────────────────────────────────────

  /// Ventana en la que se ignora un código ya leído. Sin esto, la cámara
  /// dispararía la misma detección 30 veces por segundo.
  static const Duration ventanaAntirrebote = Duration(milliseconds: 1200);

  /// Duración del «Deshacer» tras añadir un artículo al carrito.
  static const Duration ventanaDeshacer = Duration(seconds: 4);

  // ── Seguridad ─────────────────────────────────────────────────────────────

  /// Iteraciones de PBKDF2 para el hash local de la contraseña.
  /// 150.000 tarda ~250 ms en un gama media; se ejecuta en un isolate para no
  /// bloquear la interfaz.
  static const int iteracionesPbkdf2 = 150000;

  /// Días que se permite operar sin que el dispositivo vea al servidor. Lo
  /// devuelve el backend en el login; esto es sólo el valor de reserva.
  static const int diasGraciaOffline = 7;
}
