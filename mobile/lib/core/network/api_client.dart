import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Cliente HTTP.
///
/// Toda la red de la app pasa por aquí. La UI **no** lo usa nunca de forma
/// directa: sólo lo usa el motor de sincronización y el login. Si una pantalla
/// necesitara llamar a la API para pintarse, sería señal de que el modelo
/// offline se rompió.
class ApiClient {
  ApiClient({required TokenStore tokenStore, String? urlBase, Dio? dio})
      : _tokens = tokenStore,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = urlBase ?? AppConfig.urlPorDefecto
      ..connectTimeout = AppConfig.timeoutConexion
      ..receiveTimeout = AppConfig.timeoutRespuesta
      ..sendTimeout = AppConfig.timeoutRespuesta
      ..contentType = Headers.jsonContentType
      // Se aceptan todos los códigos y se decide aquí: así un 401 llega al
      // interceptor de refresco en lugar de convertirse en excepción antes.
      ..validateStatus = (s) => s != null && s < 500;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opciones, handler) async {
          if (opciones.extra['sinAuth'] != true) {
            final token = await _tokens.accessToken;
            if (token != null) opciones.headers['Authorization'] = 'Bearer $token';
          }
          if (dispositivoUuid != null) {
            opciones.headers['X-Dispositivo'] = dispositivoUuid;
          }
          handler.next(opciones);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, request: false),
      );
    }
  }

  final Dio _dio;
  final TokenStore _tokens;

  String? dispositivoUuid;

  /// Se invoca cuando el refresco falla de forma definitiva: la sesión murió y
  /// hay que llevar al usuario al login.
  void Function()? alPerderSesion;

  String get urlBase => _dio.options.baseUrl;

  set urlBase(String url) => _dio.options.baseUrl = url.replaceAll(RegExp(r'/+$'), '');

  /// Refresco en curso. Si diez peticiones reciben 401 a la vez, sólo una
  /// refresca y las demás esperan a ese mismo futuro; sin esto se dispararían
  /// diez rotaciones y la detección de reúso del servidor revocaría la familia
  /// entera, echando al usuario.
  Future<bool>? _refrescoEnCurso;

  // ── Métodos ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String ruta, {
    Map<String, dynamic>? query,
    bool sinAuth = false,
  }) =>
      _ejecutar(() => _dio.get<dynamic>(
            '${AppConfig.versionApi}$ruta',
            queryParameters: query,
            options: Options(extra: {'sinAuth': sinAuth}),
          ));

  Future<Map<String, dynamic>> post(
    String ruta, {
    Object? cuerpo,
    bool sinAuth = false,
    Duration? timeout,
  }) =>
      _ejecutar(() => _dio.post<dynamic>(
            '${AppConfig.versionApi}$ruta',
            data: cuerpo,
            options: Options(
              extra: {'sinAuth': sinAuth},
              receiveTimeout: timeout,
            ),
          ));

  Future<Map<String, dynamic>> patch(String ruta, {Object? cuerpo}) => _ejecutar(
      () => _dio.patch<dynamic>('${AppConfig.versionApi}$ruta', data: cuerpo));

  Future<Map<String, dynamic>> delete(String ruta) =>
      _ejecutar(() => _dio.delete<dynamic>('${AppConfig.versionApi}$ruta'));

  /// Sondeo de conectividad REAL.
  ///
  /// `connectivity_plus` sólo sabe si hay una interfaz de red activa. Estar
  /// conectado al wifi de una cafetería con portal cautivo da «conectado» y
  /// ninguna petición funciona. Esto confirma que la API responde de verdad.
  Future<bool> hayServidor() async {
    try {
      final r = await _dio.get<dynamic>(
        '/health',
        options: Options(
          extra: {'sinAuth': true},
          receiveTimeout: AppConfig.timeoutSalud,
          sendTimeout: AppConfig.timeoutSalud,
        ),
      );
      return r.statusCode == 200 && (r.data is Map) && (r.data as Map)['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _ejecutar(
    Future<Response<dynamic>> Function() peticion, {
    bool esReintento = false,
  }) async {
    late Response<dynamic> respuesta;
    try {
      respuesta = await peticion();
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }

    if (respuesta.statusCode == 401 && !esReintento) {
      final refrescado = await _refrescarToken();
      if (refrescado) return _ejecutar(peticion, esReintento: true);
      alPerderSesion?.call();
    }

    if (respuesta.statusCode! >= 400) {
      throw ApiException.desdeDio(
        DioException.badResponse(
          statusCode: respuesta.statusCode!,
          requestOptions: respuesta.requestOptions,
          response: respuesta,
        ),
      );
    }

    final datos = respuesta.data;
    if (datos is Map<String, dynamic>) return datos;
    return {'data': datos};
  }

  Future<bool> _refrescarToken() {
    return _refrescoEnCurso ??= _hacerRefresco().whenComplete(() {
      _refrescoEnCurso = null;
    });
  }

  Future<bool> _hacerRefresco() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;

    try {
      final r = await _dio.post<dynamic>(
        '${AppConfig.versionApi}/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(extra: {'sinAuth': true}),
      );
      if (r.statusCode != 200) {
        await _tokens.limpiar();
        return false;
      }
      final datos = (r.data as Map)['data'] as Map;
      await _tokens.guardarTokens(
        accessToken: datos['access_token'] as String,
        refreshToken: datos['refresh_token'] as String,
        refreshExpira: DateTime.tryParse(datos['refresh_expira'] as String? ?? ''),
      );
      return true;
    } catch (_) {
      // Un fallo de red al refrescar NO debe borrar los tokens: el usuario
      // sigue autenticado, simplemente no hay señal ahora mismo.
      return false;
    }
  }
}
