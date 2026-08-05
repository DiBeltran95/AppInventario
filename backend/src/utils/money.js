/**
 * Aritmética monetaria exacta.
 *
 * Regla del proyecto: el dinero NUNCA pasa por un `number` de JavaScript.
 * `0.1 + 0.2 === 0.30000000000000004`; en una venta de 40 líneas eso produce
 * descuadres de caja que nadie sabe explicar.
 *
 * Representación interna: BigInt escalado.
 *   · dinero    -> escala 2 (centavos)
 *   · cantidad  -> escala 3 (milésimas, para venta por peso)
 *   · tasa IVA  -> escala 2 (19.00 % -> 1900)
 *
 * mysql2 devuelve DECIMAL como string precisamente para que esto sea posible.
 * No lo conviertas a Number en ningún punto del camino.
 */

const RE_DECIMAL = /^([+-]?)(\d+)(?:\.(\d+))?$/;

/** Convierte un decimal (string | number | bigint) a BigInt escalado, HALF_UP. */
export function toScaled(valor, escala) {
  if (typeof valor === 'bigint') return valor;
  if (valor === null || valor === undefined || valor === '') {
    throw new TypeError('Valor monetario vacío');
  }

  let s;
  if (typeof valor === 'number') {
    if (!Number.isFinite(valor)) throw new TypeError(`Valor no finito: ${valor}`);
    // toFixed con un dígito extra: el redondeo real lo hace este algoritmo.
    s = valor.toFixed(escala + 1);
  } else {
    s = String(valor).trim();
  }

  const m = RE_DECIMAL.exec(s);
  if (!m) throw new TypeError(`Decimal inválido: "${s}"`);

  const negativo = m[1] === '-';
  const entero = BigInt(m[2]);
  // Un dígito extra a la derecha para decidir el redondeo.
  const fraccion = ((m[3] ?? '') + '0'.repeat(escala + 1)).slice(0, escala + 1);

  let escalado = entero * 10n ** BigInt(escala) + BigInt(fraccion.slice(0, escala) || '0');
  if (Number(fraccion[escala]) >= 5) escalado += 1n; // HALF_UP sobre la magnitud

  return negativo ? -escalado : escalado;
}

/** BigInt escalado -> string decimal con la escala fijada (apto para MariaDB). */
export function fromScaled(escalado, escala) {
  const negativo = escalado < 0n;
  const abs = negativo ? -escalado : escalado;
  const divisor = 10n ** BigInt(escala);
  const entero = abs / divisor;
  const resto = (abs % divisor).toString().padStart(escala, '0');
  const cuerpo = escala > 0 ? `${entero}.${resto}` : `${entero}`;
  return negativo && escalado !== 0n ? `-${cuerpo}` : cuerpo;
}

// ── Atajos por escala ────────────────────────────────────────────────────────
export const toCents = (v) => toScaled(v, 2);
export const fromCents = (c) => fromScaled(c, 2);
export const toQty = (v) => toScaled(v, 3);
export const fromQty = (q) => fromScaled(q, 3);
export const toRate = (v) => toScaled(v, 2); // 19.00 % -> 1900n

/** División entera con redondeo HALF_UP (b debe ser positivo). */
export function divHalfUp(a, b) {
  if (b <= 0n) throw new RangeError('El divisor debe ser positivo');
  const negativo = a < 0n;
  const abs = negativo ? -a : a;
  const cociente = abs / b;
  const resto = abs % b;
  const redondeado = resto * 2n >= b ? cociente + 1n : cociente;
  return negativo ? -redondeado : redondeado;
}

/**
 * precio (centavos) × cantidad (milésimas) -> centavos, HALF_UP.
 * El producto queda en escala 5; se baja a escala 2 dividiendo entre 1000.
 */
export function multiplicarPorCantidad(centavos, cantidadMilesimas) {
  return divHalfUp(centavos * cantidadMilesimas, 1000n);
}

/**
 * Desglosa un importe con IVA INCLUIDO en base gravable + impuesto.
 * total = base × (1 + tasa/100)  ->  base = total × 10000 / (10000 + tasa×100)
 * El impuesto se obtiene por resta para que base + impuesto === total siempre,
 * sin centavos perdidos por doble redondeo.
 */
export function desglosarIvaIncluido(totalCentavos, tasaEscalada) {
  const denominador = 10000n + tasaEscalada;
  const base = divHalfUp(totalCentavos * 10000n, denominador);
  return { base, impuesto: totalCentavos - base };
}

/** Suma una lista de BigInt. */
export const sumar = (valores) => valores.reduce((a, b) => a + b, 0n);

/**
 * Calcula una línea de venta completa a partir de valores en string tal como
 * llegan del cliente. Devuelve strings listos para insertar en DECIMAL.
 *
 * El descuento se aplica sobre el importe bruto de la línea, antes de desglosar
 * el impuesto: en un precio IVA incluido, descontar reduce base e impuesto
 * proporcionalmente, que es lo correcto fiscalmente.
 */
export function calcularLinea({ precioUnitario, cantidad, descuento = '0', tasaIva = '0' }) {
  const precio = toCents(precioUnitario);
  const cant = toQty(cantidad);
  const desc = toCents(descuento);
  const tasa = toRate(tasaIva);

  if (cant === 0n) throw new RangeError('La cantidad no puede ser cero');
  if (precio < 0n) throw new RangeError('El precio no puede ser negativo');
  if (desc < 0n) throw new RangeError('El descuento no puede ser negativo');

  const bruto = multiplicarPorCantidad(precio, cant);
  if (desc > bruto) throw new RangeError('El descuento supera el importe de la línea');

  const total = bruto - desc;
  const { base, impuesto } = desglosarIvaIncluido(total, tasa);

  return {
    cantidad: fromQty(cant),
    precio_unitario: fromCents(precio),
    descuento: fromCents(desc),
    tasa_iva: fromScaled(tasa, 2),
    base_gravable: fromCents(base),
    impuesto: fromCents(impuesto),
    total: fromCents(total),
    _centavos: { bruto, descuento: desc, base, impuesto, total },
  };
}

/**
 * Totaliza una venta a partir de las líneas ya calculadas.
 * Suma los enteros de cada línea: nunca recalcula sobre los strings, que ya
 * están redondeados.
 */
export function totalizarVenta(lineas) {
  const base = sumar(lineas.map((l) => l._centavos.base));
  const impuesto = sumar(lineas.map((l) => l._centavos.impuesto));
  const descuento = sumar(lineas.map((l) => l._centavos.descuento));
  const total = sumar(lineas.map((l) => l._centavos.total));
  return {
    subtotal: fromCents(base),
    impuesto_total: fromCents(impuesto),
    descuento_total: fromCents(descuento),
    total: fromCents(total),
    _centavos: { base, impuesto, descuento, total },
  };
}
