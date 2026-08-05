import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén de tokens en el Keystore de Android.
///
/// Los tokens NO van en SQLite ni en SharedPreferences: en un dispositivo con
/// root, ambos se leen en texto plano. `flutter_secure_storage` los cifra con
/// una clave respaldada por el hardware cuando el dispositivo lo permite.
class TokenStore {
  TokenStore([FlutterSecureStorage? almacen])
      : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRefreshExpira = 'refresh_expira';
  static const _kUrlServidor = 'url_servidor';

  Future<String?> get accessToken => _almacen.read(key: _kAccess);
  Future<String?> get refreshToken => _almacen.read(key: _kRefresh);

  Future<DateTime?> get refreshExpira async {
    final v = await _almacen.read(key: _kRefreshExpira);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> guardarTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? refreshExpira,
  }) async {
    await Future.wait([
      _almacen.write(key: _kAccess, value: accessToken),
      _almacen.write(key: _kRefresh, value: refreshToken),
      if (refreshExpira != null)
        _almacen.write(key: _kRefreshExpira, value: refreshExpira.toIso8601String()),
    ]);
  }

  Future<void> guardarAccessToken(String token) => _almacen.write(key: _kAccess, value: token);

  Future<void> limpiar() async {
    await Future.wait([
      _almacen.delete(key: _kAccess),
      _almacen.delete(key: _kRefresh),
      _almacen.delete(key: _kRefreshExpira),
    ]);
  }

  Future<String?> get urlServidor => _almacen.read(key: _kUrlServidor);
  Future<void> guardarUrlServidor(String url) =>
      _almacen.write(key: _kUrlServidor, value: url);
}
