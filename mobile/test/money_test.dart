import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:inventario_pos/core/money/money.dart';

/// Pruebas del cálculo monetario.
///
/// Importan más de lo que parece: el ticket **ya se imprimió en el dispositivo**
/// cuando el servidor recibe la venta, así que el servidor no puede «corregir»
/// un total sin descuadrar la caja. Cliente y servidor tienen que producir el
/// mismo número, al centavo, con el mismo redondeo.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
    Money.locale = 'es_CO';
    Money.decimalesVisibles = 0;
  });

  group('Money — conversión', () {
    test('parsea decimales con redondeo HALF_UP', () {
      expect(Money.parse('12500.00').centavos, 1250000);
      expect(Money.parse('0.005').centavos, 1); // 0,005 → 0,01
      expect(Money.parse('0.004').centavos, 0);
      expect(Money.parse('-1.50').centavos, -150);
    });

    test('el formato de la API siempre lleva dos decimales', () {
      expect(const Money(1250000).toApi(), '12500.00');
      expect(const Money(5).toApi(), '0.05');
      expect(const Money(0).toApi(), '0.00');
      expect(const Money(-150).toApi(), '-1.50');
    });

    test('ida y vuelta sin pérdida', () {
      for (final texto in ['0.00', '1.01', '999999.99', '12500.50']) {
        expect(Money.parse(texto).toApi(), texto);
      }
    });

    test('tryParse no lanza con basura', () {
      expect(Money.tryParse('abc').centavos, 0);
      expect(Money.tryParse(null).centavos, 0);
      expect(Money.tryParse('').centavos, 0);
    });
  });

  group('Money — aritmética', () {
    test('la suma es exacta donde el double falla', () {
      // 0.1 + 0.2 == 0.30000000000000004 en coma flotante.
      final total = Money.parse('0.10') + Money.parse('0.20');
      expect(total.centavos, 30);
      expect(total.toApi(), '0.30');
    });

    test('sumar 40 líneas no acumula error', () {
      final lineas = List.generate(40, (_) => Money.parse('0.01'));
      expect(Money.sumar(lineas).toApi(), '0.40');
    });

    test('precio × cantidad redondea HALF_UP al centavo', () {
      // 1.005 kg × $10,00 = $10,05
      expect(
        Money.parse('10.00').porCantidad(Cantidad.parse('1.005')).toApi(),
        '10.05',
      );
      // 0,750 kg × $12.500 = $9.375
      expect(
        Money.parse('12500.00').porCantidad(Cantidad.parse('0.750')).toApi(),
        '9375.00',
      );
    });
  });

  group('IVA incluido', () {
    test('base + impuesto == total, siempre', () {
      for (final centavos in [1, 99, 100, 12500, 999999, 1234567]) {
        for (final tasa in TasaIva.comunes) {
          final total = Money(centavos);
          final d = total.desglosarIva(tasa);
          expect(
            (d.base + d.impuesto).centavos,
            centavos,
            reason: 'se perdió un centavo con $centavos y ${tasa.format()}',
          );
        }
      }
    });

    test('desglosa el 19 % de un precio con IVA incluido', () {
      // $11.900 con IVA incluido → base $10.000 + IVA $1.900
      final d = Money.parse('11900.00').desglosarIva(const TasaIva(1900));
      expect(d.base.toApi(), '10000.00');
      expect(d.impuesto.toApi(), '1900.00');
    });

    test('con tasa cero el impuesto es cero', () {
      final d = Money.parse('5000.00').desglosarIva(const TasaIva.cero());
      expect(d.base.toApi(), '5000.00');
      expect(d.impuesto.toApi(), '0.00');
    });
  });

  group('Cantidad', () {
    test('guarda milésimas para permitir venta por peso', () {
      expect(Cantidad.parse('0.750').milesimas, 750);
      expect(Cantidad.unidades(3).milesimas, 3000);
    });

    test('oculta los decimales cuando la cantidad es entera', () {
      expect(Cantidad.unidades(3).format(), '3');
      expect(Cantidad.parse('0.750').format(), isNot('0'));
    });
  });

  group('calcularLinea', () {
    test('aplica descuento antes de desglosar el impuesto', () {
      final linea = calcularLinea(
        precioUnitario: Money.parse('11900.00'),
        cantidad: Cantidad.unidades(2),
        descuento: Money.parse('3800.00'),
        tasaIva: const TasaIva(1900),
      );

      expect(linea.bruto.toApi(), '23800.00');
      expect(linea.total.toApi(), '20000.00');
      // El invariante que sostiene el ticket completo.
      expect((linea.base + linea.impuesto).centavos, linea.total.centavos);
    });

    test('rechaza entradas imposibles en vez de guardar basura', () {
      expect(
        () => calcularLinea(
          precioUnitario: Money.parse('100.00'),
          cantidad: const Cantidad.cero(),
        ),
        throwsArgumentError,
      );
      expect(
        () => calcularLinea(
          precioUnitario: Money.parse('100.00'),
          cantidad: Cantidad.unidades(1),
          descuento: Money.parse('500.00'),
        ),
        throwsArgumentError,
        reason: 'un descuento mayor que la línea daría un total negativo',
      );
    });

    test('el total de una venta cuadra línea a línea', () {
      final lineas = [
        calcularLinea(
          precioUnitario: Money.parse('3300.00'),
          cantidad: Cantidad.unidades(3),
          tasaIva: const TasaIva(1900),
        ),
        calcularLinea(
          precioUnitario: Money.parse('12500.00'),
          cantidad: Cantidad.parse('0.750'),
          tasaIva: const TasaIva(500),
        ),
        calcularLinea(
          precioUnitario: Money.parse('1000.00'),
          cantidad: Cantidad.unidades(1),
        ),
      ];

      final base = Money.sumar(lineas.map((l) => l.base));
      final impuesto = Money.sumar(lineas.map((l) => l.impuesto));
      final total = Money.sumar(lineas.map((l) => l.total));

      expect((base + impuesto).centavos, total.centavos);
      expect(total.toApi(), '20275.00');
    });
  });
}
