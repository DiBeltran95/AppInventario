import 'package:intl/intl.dart';

/// Aritmética exacta para dinero y cantidades.
///
/// Regla del proyecto: **en la app no existe un `double` que represente dinero**.
/// `0.1 + 0.2 == 0.30000000000000004`; en un carrito de 40 líneas eso produce
/// tickets que no cuadran con la caja.
///
/// Representación:
///  · [Money]    → `int` de centavos      (escala 2)
///  · [Cantidad] → `int` de milésimas     (escala 3, permite venta por peso)
///
/// En SQLite se guardan como INTEGER; en la API viajan como string decimal
/// (`"12500.00"`), nunca como número JSON —que volvería a ser IEEE-754—.

/// Convierte un decimal en texto a entero escalado, con redondeo HALF_UP.
/// Es el mismo algoritmo que `toScaled` en el backend: si divergieran, el
/// cliente y el servidor calcularían totales distintos para la misma venta.
int _aEscalado(String texto, int escala) {
  final limpio = texto.trim();
  final m = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?$').firstMatch(limpio);
  if (m == null) {
    throw FormatException('Decimal inválido: "$texto"');
  }

  final negativo = m.group(1) == '-';
  final entero = BigInt.parse(m.group(2)!);
  // Un dígito extra a la derecha para decidir el redondeo.
  final fraccion = ((m.group(3) ?? '') + '0' * (escala + 1)).substring(0, escala + 1);

  var escalado = entero * BigInt.from(10).pow(escala) +
      BigInt.parse(fraccion.substring(0, escala).isEmpty ? '0' : fraccion.substring(0, escala));
  if (int.parse(fraccion[escala]) >= 5) escalado += BigInt.one;

  final resultado = negativo ? -escalado : escalado;
  return resultado.toInt();
}

String _deEscalado(int valor, int escala) {
  final negativo = valor < 0;
  final abs = valor.abs();
  final divisor = _pow10(escala);
  final entero = abs ~/ divisor;
  final resto = (abs % divisor).toString().padLeft(escala, '0');
  final cuerpo = escala > 0 ? '$entero.$resto' : '$entero';
  return negativo && valor != 0 ? '-$cuerpo' : cuerpo;
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

/// División entera con redondeo HALF_UP. [b] debe ser positivo.
int _divHalfUp(int a, int b) {
  assert(b > 0);
  final negativo = a < 0;
  final abs = a.abs();
  final cociente = abs ~/ b;
  final resto = abs % b;
  final redondeado = resto * 2 >= b ? cociente + 1 : cociente;
  return negativo ? -redondeado : redondeado;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Importe monetario, almacenado en centavos.
class Money implements Comparable<Money> {
  const Money(this.centavos);

  const Money.cero() : centavos = 0;

  /// Desde el formato de la API o de la base local: `"12500.00"`.
  factory Money.parse(String texto) => Money(_aEscalado(texto, 2));

  /// Tolerante: devuelve cero si el texto no es un decimal válido.
  factory Money.tryParse(String? texto) {
    if (texto == null || texto.isEmpty) return const Money.cero();
    try {
      return Money.parse(texto);
    } on FormatException {
      return const Money.cero();
    }
  }

  /// Desde unidades enteras de la moneda: `Money.deUnidades(2500)` = $2.500,00.
  factory Money.deUnidades(int unidades) => Money(unidades * 100);

  final int centavos;

  /// Cuántos decimales se muestran. El peso colombiano no usa centavos en la
  /// práctica, así que por defecto se ocultan; el valor exacto sigue guardado.
  static int decimalesVisibles = 0;
  static String simbolo = r'$';
  static String locale = 'es_CO';

  static NumberFormat? _cacheFormato;
  static int? _cacheDecimales;
  static String? _cacheLocale;

  static NumberFormat get _formato {
    if (_cacheFormato == null || _cacheDecimales != decimalesVisibles || _cacheLocale != locale) {
      _cacheFormato = NumberFormat.currency(
        locale: locale,
        symbol: '$simbolo ',
        decimalDigits: decimalesVisibles,
      );
      _cacheDecimales = decimalesVisibles;
      _cacheLocale = locale;
    }
    return _cacheFormato!;
  }

  bool get esCero => centavos == 0;
  bool get esNegativo => centavos < 0;
  bool get esPositivo => centavos > 0;

  /// Formato para la API y para SQLite: siempre 2 decimales.
  String toApi() => _deEscalado(centavos, 2);

  /// Formato para el usuario: `$ 12.500`.
  String format() => _formato.format(centavos / 100);

  /// Sin símbolo, para campos de formulario.
  String formatSinSimbolo() =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimalesVisibles)
          .format(centavos / 100);

  Money operator +(Money otro) => Money(centavos + otro.centavos);
  Money operator -(Money otro) => Money(centavos - otro.centavos);
  Money operator -() => Money(-centavos);
  bool operator >(Money otro) => centavos > otro.centavos;
  bool operator <(Money otro) => centavos < otro.centavos;
  bool operator >=(Money otro) => centavos >= otro.centavos;
  bool operator <=(Money otro) => centavos <= otro.centavos;

  /// precio × cantidad, con redondeo HALF_UP al centavo.
  Money porCantidad(Cantidad cantidad) =>
      Money(_divHalfUp(centavos * cantidad.milesimas, 1000));

  Money porEntero(int n) => Money(centavos * n);

  /// Reparte un importe con IVA **incluido** en base gravable e impuesto.
  ///
  /// El impuesto se obtiene por resta para que `base + impuesto == total`
  /// siempre, sin centavos perdidos por redondear dos veces.
  ({Money base, Money impuesto}) desglosarIva(TasaIva tasa) {
    final denominador = 10000 + tasa.escalada;
    final base = _divHalfUp(centavos * 10000, denominador);
    return (base: Money(base), impuesto: Money(centavos - base));
  }

  @override
  int compareTo(Money otro) => centavos.compareTo(otro.centavos);

  @override
  bool operator ==(Object other) => other is Money && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => format();

  static Money sumar(Iterable<Money> valores) =>
      Money(valores.fold(0, (a, m) => a + m.centavos));
}

// ─────────────────────────────────────────────────────────────────────────────

/// Cantidad de producto, almacenada en milésimas de unidad.
class Cantidad implements Comparable<Cantidad> {
  const Cantidad(this.milesimas);

  const Cantidad.cero() : milesimas = 0;

  factory Cantidad.parse(String texto) => Cantidad(_aEscalado(texto, 3));

  factory Cantidad.tryParse(String? texto) {
    if (texto == null || texto.isEmpty) return const Cantidad.cero();
    try {
      return Cantidad.parse(texto);
    } on FormatException {
      return const Cantidad.cero();
    }
  }

  factory Cantidad.unidades(int n) => Cantidad(n * 1000);

  final int milesimas;

  bool get esCero => milesimas == 0;
  bool get esNegativa => milesimas < 0;
  bool get esEntera => milesimas % 1000 == 0;

  String toApi() => _deEscalado(milesimas, 3);

  /// `3` para unidades enteras, `0,750` cuando hay fracción. Mostrar «3,000
  /// unidades» en una tienda es ruido.
  String format() {
    if (esEntera) return (milesimas ~/ 1000).toString();
    return NumberFormat.decimalPatternDigits(locale: Money.locale, decimalDigits: 3)
        .format(milesimas / 1000);
  }

  String formatConUnidad(String unidad) => '${format()} $unidad';

  Cantidad operator +(Cantidad otra) => Cantidad(milesimas + otra.milesimas);
  Cantidad operator -(Cantidad otra) => Cantidad(milesimas - otra.milesimas);
  Cantidad operator -() => Cantidad(-milesimas);
  bool operator >(Cantidad otra) => milesimas > otra.milesimas;
  bool operator <(Cantidad otra) => milesimas < otra.milesimas;
  bool operator >=(Cantidad otra) => milesimas >= otra.milesimas;
  bool operator <=(Cantidad otra) => milesimas <= otra.milesimas;

  @override
  int compareTo(Cantidad otra) => milesimas.compareTo(otra.milesimas);

  @override
  bool operator ==(Object other) => other is Cantidad && other.milesimas == milesimas;

  @override
  int get hashCode => milesimas.hashCode;

  @override
  String toString() => format();

  static Cantidad sumar(Iterable<Cantidad> valores) =>
      Cantidad(valores.fold(0, (a, c) => a + c.milesimas));
}

// ─────────────────────────────────────────────────────────────────────────────

/// Tasa de impuesto, almacenada con 2 decimales (`19.00 %` → `1900`).
class TasaIva {
  const TasaIva(this.escalada);

  const TasaIva.cero() : escalada = 0;

  factory TasaIva.parse(String texto) => TasaIva(_aEscalado(texto, 2));

  factory TasaIva.porcentaje(num p) => TasaIva((p * 100).round());

  final int escalada;

  bool get esCero => escalada == 0;

  String toApi() => _deEscalado(escalada, 2);

  /// `19 %` o `12,5 %`.
  String format() {
    final entero = escalada % 100 == 0;
    return entero ? '${escalada ~/ 100} %' : '${(escalada / 100).toStringAsFixed(2)} %';
  }

  /// Tasas habituales en Colombia.
  static const List<TasaIva> comunes = [
    TasaIva(0),
    TasaIva(500),
    TasaIva(1900),
  ];

  @override
  bool operator ==(Object other) => other is TasaIva && other.escalada == escalada;

  @override
  int get hashCode => escalada.hashCode;

  @override
  String toString() => format();
}

// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del cálculo de una línea de venta.
///
/// Réplica exacta de `calcularLinea` del backend. Que ambos lados produzcan el
/// mismo número no es un detalle: el ticket ya se imprimió en el dispositivo
/// cuando el servidor recibe la venta, así que el servidor no puede «corregir»
/// el total sin descuadrar la caja.
class LineaCalculada {
  const LineaCalculada({
    required this.bruto,
    required this.descuento,
    required this.base,
    required this.impuesto,
    required this.total,
  });

  final Money bruto;
  final Money descuento;
  final Money base;
  final Money impuesto;
  final Money total;
}

LineaCalculada calcularLinea({
  required Money precioUnitario,
  required Cantidad cantidad,
  Money descuento = const Money.cero(),
  TasaIva tasaIva = const TasaIva.cero(),
}) {
  if (cantidad.esCero) {
    throw ArgumentError('La cantidad no puede ser cero');
  }
  if (precioUnitario.esNegativo) {
    throw ArgumentError('El precio no puede ser negativo');
  }
  if (descuento.esNegativo) {
    throw ArgumentError('El descuento no puede ser negativo');
  }

  final bruto = precioUnitario.porCantidad(cantidad);
  if (descuento > bruto) {
    throw ArgumentError('El descuento supera el importe de la línea');
  }

  final total = bruto - descuento;
  final desglose = total.desglosarIva(tasaIva);

  return LineaCalculada(
    bruto: bruto,
    descuento: descuento,
    base: desglose.base,
    impuesto: desglose.impuesto,
    total: total,
  );
}
