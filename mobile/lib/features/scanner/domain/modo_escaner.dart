/// Para qué se abrió la cámara.
///
/// El escáner es uno solo; lo que cambia es qué ocurre tras detectar un código.
/// Tener un único escáner evita mantener tres pantallas de cámara casi iguales
/// (y tres sitios donde arreglar el mismo problema de enfoque).
enum ModoEscaner {
  /// Añadir al carrito y seguir escaneando sin cerrar la cámara.
  venta,

  /// Registrar entrada de mercancía.
  entrada,

  /// Sólo consultar: abre la ficha del producto.
  consulta,

  /// Devolver el código leído a quien abrió el escáner (formulario de producto).
  capturarCodigo;

  static ModoEscaner desde(String? valor) => switch (valor) {
        'entrada' => ModoEscaner.entrada,
        'consulta' => ModoEscaner.consulta,
        'codigo' => ModoEscaner.capturarCodigo,
        _ => ModoEscaner.venta,
      };

  String get parametro => switch (this) {
        ModoEscaner.venta => 'venta',
        ModoEscaner.entrada => 'entrada',
        ModoEscaner.consulta => 'consulta',
        ModoEscaner.capturarCodigo => 'codigo',
      };

  String get titulo => switch (this) {
        ModoEscaner.venta => 'Vender',
        ModoEscaner.entrada => 'Entrada de mercancía',
        ModoEscaner.consulta => 'Consultar producto',
        ModoEscaner.capturarCodigo => 'Asignar código',
      };

  String get ayuda => switch (this) {
        ModoEscaner.venta => 'Apunta al código. Se agrega al carrito sin cerrar la cámara.',
        ModoEscaner.entrada => 'Escanea el producto que estás recibiendo.',
        ModoEscaner.consulta => 'Escanea para ver la ficha del producto.',
        ModoEscaner.capturarCodigo => 'Escanea el código que quieres asignar.',
      };

  /// En modo venta la cámara sigue activa tras cada lectura: vender 20
  /// artículos no puede costar 20 aperturas de cámara.
  bool get continuo => this == ModoEscaner.venta;
}
