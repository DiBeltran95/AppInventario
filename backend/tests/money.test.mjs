import test from 'node:test';
import assert from 'node:assert/strict';
import {
  toScaled, fromScaled, toCents, fromCents, toQty, fromQty,
  divHalfUp, multiplicarPorCantidad, desglosarIvaIncluido,
  calcularLinea, totalizarVenta,
} from '../src/utils/money.js';

test('toScaled convierte decimales sin pérdida', () => {
  assert.equal(toCents('12500.00'), 1_250_000n);
  assert.equal(toCents('0.01'), 1n);
  assert.equal(toCents('0'), 0n);
  assert.equal(toCents('-45.67'), -4567n);
  assert.equal(toCents('99999999999.99'), 9_999_999_999_999n);
  assert.equal(toQty('0.750'), 750n);
  assert.equal(toQty('-3.500'), -3500n);
});

test('toScaled redondea HALF_UP sobre la magnitud', () => {
  assert.equal(toCents('0.005'), 1n, '0.005 -> 0.01');
  assert.equal(toCents('0.004'), 0n, '0.004 -> 0.00');
  assert.equal(toCents('0.0049'), 0n);
  assert.equal(toCents('1.995'), 200n, '1.995 -> 2.00');
  assert.equal(toCents('-0.005'), -1n, 'el redondeo se aplica al valor absoluto');
});

test('fromScaled formatea con la escala exacta', () => {
  assert.equal(fromCents(1_250_000n), '12500.00');
  assert.equal(fromCents(5n), '0.05');
  assert.equal(fromCents(0n), '0.00');
  assert.equal(fromCents(-4567n), '-45.67');
  assert.equal(fromQty(750n), '0.750');
  assert.equal(fromScaled(1900n, 2), '19.00');
});

test('ida y vuelta es estable', () => {
  for (const v of ['0.00', '0.01', '1.99', '12500.00', '-45.67', '99999.99']) {
    assert.equal(fromCents(toCents(v)), v, v);
  }
});

test('rechaza entradas que no son decimales', () => {
  for (const v of ['abc', '1.2.3', '', '1e5', '  ', null, undefined, NaN, Infinity]) {
    assert.throws(() => toCents(v), `debería rechazar ${String(v)}`);
  }
});

test('divHalfUp redondea al alza en el empate exacto', () => {
  assert.equal(divHalfUp(5n, 2n), 3n, '2.5 -> 3');
  assert.equal(divHalfUp(4n, 2n), 2n);
  assert.equal(divHalfUp(3n, 2n), 2n, '1.5 -> 2');
  assert.equal(divHalfUp(1n, 3n), 0n);
  assert.equal(divHalfUp(2n, 3n), 1n);
  assert.equal(divHalfUp(-5n, 2n), -3n, 'simétrico en negativos');
});

test('multiplicarPorCantidad admite cantidades fraccionarias', () => {
  // 0.750 kg × 12.000,00 = 9.000,00
  assert.equal(fromCents(multiplicarPorCantidad(toCents('12000.00'), toQty('0.750'))), '9000.00');
  // 3 × 2.500,00
  assert.equal(fromCents(multiplicarPorCantidad(toCents('2500.00'), toQty('3.000'))), '7500.00');
  // 1/3 de peso: se redondea, no se arrastra error binario
  assert.equal(fromCents(multiplicarPorCantidad(toCents('1000.00'), toQty('0.333'))), '333.00');
});

test('desglosarIvaIncluido reparte sin perder centavos', () => {
  const casos = [
    ['5000.00', '19.00'],
    ['3200.00', '5.00'],
    ['1.00', '19.00'],
    ['999999.99', '19.00'],
    ['7.00', '19.00'],
    ['4200.00', '0.00'],
  ];
  for (const [total, tasa] of casos) {
    const t = toCents(total);
    const { base, impuesto } = desglosarIvaIncluido(t, toScaled(tasa, 2));
    assert.equal(base + impuesto, t, `base+IVA debe dar exactamente ${total} (tasa ${tasa})`);
    assert.ok(impuesto >= 0n, 'el impuesto nunca es negativo');
  }
  // IVA 0 %: todo es base
  const cero = desglosarIvaIncluido(toCents('4200.00'), 0n);
  assert.equal(cero.impuesto, 0n);
  assert.equal(fromCents(cero.base), '4200.00');
});

test('calcularLinea coincide con el cálculo manual', () => {
  const l = calcularLinea({ precioUnitario: '2500.00', cantidad: '2.000', tasaIva: '19.00' });
  assert.equal(l.total, '5000.00');
  assert.equal(l.base_gravable, '4201.68'); // 5000 / 1.19
  assert.equal(l.impuesto, '798.32');
  assert.equal(
    (Number(l.base_gravable) + Number(l.impuesto)).toFixed(2),
    l.total,
    'base + impuesto === total',
  );
});

test('el descuento reduce base e impuesto proporcionalmente', () => {
  const l = calcularLinea({
    precioUnitario: '10000.00', cantidad: '1.000', descuento: '1000.00', tasaIva: '19.00',
  });
  assert.equal(l.total, '9000.00', 'el descuento se aplica al bruto');
  assert.equal(l.base_gravable, '7563.03');
  assert.equal(l.impuesto, '1436.97');
  assert.equal(Number(l.base_gravable) + Number(l.impuesto), 9000);
});

test('rechaza cantidades y descuentos imposibles', () => {
  assert.throws(() => calcularLinea({ precioUnitario: '100.00', cantidad: '0.000' }), /cantidad/i);
  assert.throws(
    () => calcularLinea({ precioUnitario: '100.00', cantidad: '1.000', descuento: '200.00' }),
    /descuento/i,
  );
  assert.throws(
    () => calcularLinea({ precioUnitario: '-1.00', cantidad: '1.000' }),
    /precio/i,
  );
});

test('totalizarVenta suma enteros, no strings redondeados', () => {
  const lineas = [
    calcularLinea({ precioUnitario: '2500.00', cantidad: '2.000', tasaIva: '19.00' }),
    calcularLinea({ precioUnitario: '3200.00', cantidad: '1.000', tasaIva: '5.00' }),
  ];
  const t = totalizarVenta(lineas);
  assert.equal(t.total, '8200.00');
  assert.equal(t.subtotal, '7249.30');
  assert.equal(t.impuesto_total, '950.70');
  assert.equal(Number(t.subtotal) + Number(t.impuesto_total), 8200);
});

test('40 líneas de un centavo suman exactamente 0.40', () => {
  // El caso que revienta con double: 0.01 sumado 40 veces da 0.4000000000000002
  const lineas = Array.from({ length: 40 }, () =>
    calcularLinea({ precioUnitario: '0.01', cantidad: '1.000', tasaIva: '0.00' }),
  );
  assert.equal(totalizarVenta(lineas).total, '0.40');
});

test('una venta larga con IVA mixto cuadra al centavo', () => {
  const lineas = [];
  for (let i = 1; i <= 60; i += 1) {
    lineas.push(
      calcularLinea({
        precioUnitario: `${1000 + i * 37}.${String(i % 100).padStart(2, '0')}`,
        cantidad: `${(i % 5) + 1}.000`,
        descuento: i % 7 === 0 ? '100.00' : '0',
        tasaIva: [0, 5, 19][i % 3].toFixed(2),
      }),
    );
  }
  const t = totalizarVenta(lineas);
  assert.equal(
    (Number(t.subtotal) + Number(t.impuesto_total)).toFixed(2),
    t.total,
    'base + IVA === total en 60 líneas con tasas mezcladas',
  );
  const sumaLineas = lineas.reduce((a, l) => a + Number(l.total), 0);
  assert.equal(sumaLineas.toFixed(2), t.total, 'el total es la suma exacta de las líneas');
});
