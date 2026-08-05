import 'dart:convert';
import 'dart:math';


import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Verificación de contraseña **sin conexión**.
///
/// Por qué existe: el JWT caduca a los 15 minutos. Si el vendedor abre la app
/// en modo avión al día siguiente, no hay nadie a quien preguntarle si la
/// contraseña es correcta. Se guarda un derivado local de la contraseña la
/// primera vez que inicia sesión con red, y luego se compara contra él.
///
/// Por qué PBKDF2 y no el hash Argon2id del servidor: ese hash **nunca sale**
/// del servidor. Si el teléfono se pierde, el atacante obtiene un derivado
/// local con su propia sal, inútil contra la API. Argon2 sería preferible por
/// resistencia a GPU, pero no hay implementación Dart pura mantenida; PBKDF2
/// con 150.000 iteraciones es la alternativa estándar y ampliamente auditada.
class PasswordHash {
  const PasswordHash._();

  static final _aleatorio = Random.secure();

  static String generarSalt([int bytes = 16]) {
    final datos = Uint8List.fromList(
      List<int>.generate(bytes, (_) => _aleatorio.nextInt(256)),
    );
    return base64Url.encode(datos);
  }

  /// Deriva el hash en un isolate: 150.000 iteraciones bloquearían el hilo de
  /// interfaz unos 250 ms y la pantalla de login se congelaría.
  static Future<String> derivar(String password, String saltBase64) {
    return compute(
      _derivarSincrono,
      _EntradaDerivacion(password, saltBase64, AppConfig.iteracionesPbkdf2),
    );
  }

  /// Comparación en tiempo constante: comparar con `==` filtra información por
  /// el tiempo de respuesta.
  static Future<bool> verificar(String password, String saltBase64, String hashEsperado) async {
    final calculado = await derivar(password, saltBase64);
    return _igualdadConstante(calculado, hashEsperado);
  }

  static bool _igualdadConstante(String a, String b) {
    if (a.length != b.length) return false;
    var diferencia = 0;
    for (var i = 0; i < a.length; i++) {
      diferencia |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diferencia == 0;
  }
}

class _EntradaDerivacion {
  const _EntradaDerivacion(this.password, this.salt, this.iteraciones);
  final String password;
  final String salt;
  final int iteraciones;
}

String _derivarSincrono(_EntradaDerivacion e) {
  final clave = _pbkdf2(
    password: utf8.encode(e.password),
    salt: base64Url.decode(e.salt),
    iteraciones: e.iteraciones,
    longitud: 32,
  );
  return base64Url.encode(clave);
}

/// PBKDF2-HMAC-SHA256 (RFC 8018).
Uint8List _pbkdf2({
  required List<int> password,
  required List<int> salt,
  required int iteraciones,
  required int longitud,
}) {
  final hmac = Hmac(sha256, password);
  const tamanoBloque = 32; // SHA-256
  final bloques = (longitud / tamanoBloque).ceil();
  final salida = Uint8List(bloques * tamanoBloque);

  for (var i = 1; i <= bloques; i++) {
    // U1 = HMAC(password, salt || INT_BE32(i))
    final entrada = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..buffer.asByteData().setUint32(salt.length, i, Endian.big);

    var u = Uint8List.fromList(hmac.convert(entrada).bytes);
    final acumulado = Uint8List.fromList(u);

    for (var j = 1; j < iteraciones; j++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var k = 0; k < tamanoBloque; k++) {
        acumulado[k] ^= u[k];
      }
    }

    salida.setRange((i - 1) * tamanoBloque, i * tamanoBloque, acumulado);
  }

  return Uint8List.sublistView(salida, 0, longitud);
}
