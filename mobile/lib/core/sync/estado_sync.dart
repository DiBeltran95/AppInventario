/// Estado de la sincronización, tal como lo muestra el chip permanente.
///
/// Este chip es el elemento de interfaz más importante de la app: el vendedor
/// tiene que saber en todo momento si su venta ya salió del dispositivo. Sin
/// él, «offline-first» se siente como «¿se guardó o no se guardó?».
enum FaseSync {
  /// Sin red utilizable. Se sigue vendiendo con normalidad.
  sinConexion,

  /// Hay red y no queda nada por enviar.
  alDia,

  /// Hay operaciones esperando a salir.
  pendiente,

  /// Enviando o bajando ahora mismo.
  sincronizando,

  /// Hubo un fallo; se reintentará solo.
  conError,
}

class EstadoSync {
  const EstadoSync({
    this.fase = FaseSync.sinConexion,
    this.pendientes = 0,
    this.rechazadas = 0,
    this.ultimoSync,
    this.ultimoError,
    this.progresoTexto,
  });

  final FaseSync fase;
  final int pendientes;

  /// Operaciones que el servidor rechazó de forma definitiva. Requieren
  /// atención humana: no se van a arreglar reintentando.
  final int rechazadas;

  final DateTime? ultimoSync;
  final String? ultimoError;
  final String? progresoTexto;

  bool get hayConexion => fase != FaseSync.sinConexion;
  bool get trabajando => fase == FaseSync.sincronizando;
  bool get todoEnviado => pendientes == 0;

  String get etiqueta => switch (fase) {
        FaseSync.sinConexion =>
          pendientes > 0 ? 'Sin conexión · $pendientes por enviar' : 'Sin conexión',
        FaseSync.alDia => 'Al día',
        FaseSync.pendiente => '$pendientes por enviar',
        FaseSync.sincronizando => progresoTexto ?? 'Sincronizando…',
        FaseSync.conError => 'Error al sincronizar',
      };

  EstadoSync copyWith({
    FaseSync? fase,
    int? pendientes,
    int? rechazadas,
    DateTime? ultimoSync,
    String? ultimoError,
    bool limpiarError = false,
    String? progresoTexto,
    bool limpiarProgreso = false,
  }) =>
      EstadoSync(
        fase: fase ?? this.fase,
        pendientes: pendientes ?? this.pendientes,
        rechazadas: rechazadas ?? this.rechazadas,
        ultimoSync: ultimoSync ?? this.ultimoSync,
        ultimoError: limpiarError ? null : (ultimoError ?? this.ultimoError),
        progresoTexto: limpiarProgreso ? null : (progresoTexto ?? this.progresoTexto),
      );
}

/// Resumen de una pasada de sincronización.
class ResultadoSync {
  const ResultadoSync({
    this.enviadas = 0,
    this.rechazadas = 0,
    this.recibidas = 0,
    this.error,
  });

  final int enviadas;
  final int rechazadas;
  final int recibidas;
  final String? error;

  bool get ok => error == null;
  bool get huboCambios => enviadas > 0 || recibidas > 0;
}
