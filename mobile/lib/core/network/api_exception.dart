import 'package:dio/dio.dart';

/// Error de API con la distinción que gobierna la cola de sincronización:
/// **¿reintentar o descartar?**
///
/// Un 400 por validación no se arregla reenviándolo y bloquearía todo lo que
/// venga detrás. Un 503 sí es transitorio y merece backoff.
class ApiException implements Exception {
  const ApiException({
    required this.codigo,
    required this.mensaje,
    this.status,
    this.detalles,
    required this.permanente,
  });

  final String codigo;
  final String mensaje;
  final int? status;
  final Object? detalles;
  final bool permanente;

  /// No hay red, o la hay pero el servidor no responde.
  bool get esDeRed => codigo == 'SIN_RED' || codigo == 'TIMEOUT';

  /// El token caducó: hay que refrescar o volver a iniciar sesión.
  bool get esDeSesion =>
      status == 401 || codigo == 'TOKEN_EXPIRADO' || codigo == 'REFRESH_INVALIDO';

  factory ApiException.desdeDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          codigo: 'TIMEOUT',
          mensaje: 'El servidor tardó demasiado en responder',
          permanente: false,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          codigo: 'SIN_RED',
          mensaje: 'No hay conexión con el servidor',
          permanente: false,
        );
      case DioExceptionType.cancel:
        return const ApiException(
          codigo: 'CANCELADA',
          mensaje: 'Petición cancelada',
          permanente: false,
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          codigo: 'CERTIFICADO',
          mensaje: 'El certificado del servidor no es válido',
          permanente: true,
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final cuerpo = e.response?.data;
        if (cuerpo is Map && cuerpo['error'] is Map) {
          final error = cuerpo['error'] as Map;
          return ApiException(
            codigo: (error['codigo'] as String?) ?? 'ERROR',
            mensaje: (error['mensaje'] as String?) ?? 'Error del servidor',
            status: status,
            detalles: error['detalles'],
            permanente: (error['permanente'] as bool?) ??
                (status >= 400 && status < 500 && status != 408 && status != 429),
          );
        }
        return ApiException(
          codigo: 'HTTP_$status',
          mensaje: _mensajePorStatus(status),
          status: status,
          permanente: status >= 400 && status < 500 && status != 408 && status != 429,
        );
    }
  }

  static String _mensajePorStatus(int status) => switch (status) {
        400 => 'La petición no es válida',
        401 => 'Sesión expirada',
        403 => 'No tienes permiso para esta operación',
        404 => 'No se encontró el recurso',
        409 => 'Conflicto con datos existentes',
        413 => 'El contenido enviado es demasiado grande',
        429 => 'Demasiadas peticiones; espera un momento',
        >= 500 => 'Error en el servidor',
        _ => 'Error inesperado ($status)',
      };

  /// Texto para mostrar al usuario, incluyendo el primer detalle de validación
  /// si lo hay: «Los datos no son válidos» a secas no ayuda a nadie.
  String get mensajeUsuario {
    if (detalles is List && (detalles as List).isNotEmpty) {
      final primero = (detalles as List).first;
      if (primero is Map && primero['mensaje'] != null) {
        return '$mensaje: ${primero['campo'] ?? ''} ${primero['mensaje']}'.trim();
      }
    }
    return mensaje;
  }

  @override
  String toString() => 'ApiException($codigo, $status): $mensaje';
}
