import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../network/api_client.dart';

/// Detección de conectividad **utilizable**.
///
/// `connectivity_plus` responde a «¿hay una interfaz de red activa?», no a
/// «¿se puede hablar con mi servidor?». El wifi de una cafetería con portal
/// cautivo, o una conexión móvil sin datos, dan «conectado» y ninguna petición
/// funciona. Por eso cada cambio de interfaz se confirma con un sondeo real a
/// `/health` antes de declarar que hay red.
class ConnectivityService {
  ConnectivityService(this._api, [Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final ApiClient _api;
  final Connectivity _connectivity;

  final _controlador = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  Timer? _reintento;

  bool _hayRed = false;
  bool _verificando = false;

  bool get hayRed => _hayRed;

  /// Emite `true`/`false` sólo cuando el estado REALMENTE cambia.
  Stream<bool> get cambios => _controlador.stream;

  Future<void> iniciar() async {
    _suscripcion = _connectivity.onConnectivityChanged.listen((resultados) {
      final hayInterfaz = resultados.any((r) => r != ConnectivityResult.none);
      if (!hayInterfaz) {
        _actualizar(false);
        _reintento?.cancel();
      } else {
        // Al recuperar la interfaz, la ruta suele tardar un instante en quedar
        // utilizable. Un sondeo inmediato daría un falso negativo.
        _reintento?.cancel();
        _reintento = Timer(const Duration(milliseconds: 900), verificar);
      }
    });

    await verificar();
  }

  /// Sondeo real. Devuelve el estado resultante.
  Future<bool> verificar() async {
    if (_verificando) return _hayRed;
    _verificando = true;
    try {
      final resultados = await _connectivity.checkConnectivity();
      if (resultados.every((r) => r == ConnectivityResult.none)) {
        _actualizar(false);
        return false;
      }
      final vivo = await _api.hayServidor();
      _actualizar(vivo);
      return vivo;
    } finally {
      _verificando = false;
    }
  }

  void _actualizar(bool nuevo) {
    if (_hayRed == nuevo) return;
    _hayRed = nuevo;
    if (!_controlador.isClosed) _controlador.add(nuevo);
  }

  Future<void> dispose() async {
    _reintento?.cancel();
    await _suscripcion?.cancel();
    await _controlador.close();
  }
}
