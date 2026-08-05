/// Rol del usuario. Determina qué puede hacer y qué información ve.
enum RolUsuario {
  admin,
  vendedor;

  static RolUsuario desde(String? valor) =>
      valor == 'ADMIN' ? RolUsuario.admin : RolUsuario.vendedor;

  String get api => this == RolUsuario.admin ? 'ADMIN' : 'VENDEDOR';
  String get etiqueta => this == RolUsuario.admin ? 'Administrador' : 'Vendedor';

  bool get puedeEditarCatalogo => this == RolUsuario.admin;
  bool get puedeAnularVentas => this == RolUsuario.admin;
  bool get puedeGestionarUsuarios => this == RolUsuario.admin;

  /// El vendedor no ve costos ni márgenes: es información sensible del negocio.
  bool get veCostos => this == RolUsuario.admin;
}

class Sesion {
  const Sesion({
    required this.usuarioUuid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.enLinea,
    this.validaHasta,
  });

  final String usuarioUuid;
  final String nombre;
  final String email;
  final RolUsuario rol;

  /// `true` si la sesión se abrió contra el servidor; `false` si se validó
  /// contra el derivado local de la contraseña.
  final bool enLinea;

  /// Hasta cuándo se puede seguir operando sin volver a ver el servidor.
  final DateTime? validaHasta;

  bool get esAdmin => rol == RolUsuario.admin;

  /// Días que quedan de operación offline. Se avisa al usuario cuando bajan de
  /// dos: quedarse fuera a mitad de un turno sería inaceptable.
  int? get diasRestantes {
    if (validaHasta == null) return null;
    final dias = validaHasta!.difference(DateTime.now().toUtc()).inDays;
    return dias < 0 ? 0 : dias;
  }

  bool get avisarCaducidad {
    final d = diasRestantes;
    return d != null && d <= 2;
  }

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}

class ResultadoLogin {
  const ResultadoLogin._({
    this.sesion,
    this.mensajeError,
    this.necesitaDescargaInicial = false,
  });

  factory ResultadoLogin.ok(Sesion sesion, {bool necesitaDescargaInicial = false}) =>
      ResultadoLogin._(sesion: sesion, necesitaDescargaInicial: necesitaDescargaInicial);

  factory ResultadoLogin.error(String mensaje) => ResultadoLogin._(mensajeError: mensaje);

  final Sesion? sesion;
  final String? mensajeError;
  final bool necesitaDescargaInicial;

  bool get exito => sesion != null;
}
