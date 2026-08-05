/**
 * Fechas de negocio.
 *
 * El servidor corre en UTC y la tienda opera en `America/Bogota` (UTC-5). Si los
 * reportes agruparan por la fecha UTC, el "día" de la tienda se cortaría a las
 * 7:00 p. m. y las ventas de la noche caerían en el día siguiente.
 *
 * Por eso `ventas.fecha_local` y `movimientos.fecha_local` son columnas DATE
 * calculadas en la zona del negocio, y todos los agregados usan esas columnas.
 */
import { env } from '../config/env.js';

const cacheFormatos = new Map();

function formateador(tz) {
  let f = cacheFormatos.get(tz);
  if (!f) {
    // 'en-CA' produce exactamente YYYY-MM-DD.
    f = new Intl.DateTimeFormat('en-CA', {
      timeZone: tz,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    cacheFormatos.set(tz, f);
  }
  return f;
}

/** Día hábil ('YYYY-MM-DD') correspondiente a un instante, en la zona dada. */
export function diaHabil(instante = new Date(), tz = env.BUSINESS_TIMEZONE) {
  const d = instante instanceof Date ? instante : new Date(instante);
  if (Number.isNaN(d.getTime())) throw new TypeError('Fecha inválida');
  return formateador(tz).format(d);
}

/** Valida el formato 'YYYY-MM-DD' y que sea una fecha real. */
export function esDiaHabilValido(s) {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}

/** Suma días a un 'YYYY-MM-DD' y devuelve otro 'YYYY-MM-DD'. */
export function sumarDias(diaISO, dias) {
  const d = new Date(`${diaISO}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + dias);
  return d.toISOString().slice(0, 10);
}

/**
 * Rango [desde, hasta] de días hábiles para un periodo relativo a hoy.
 * Ambos extremos inclusive, en formato 'YYYY-MM-DD'.
 */
export function rangoPeriodo(periodo, tz = env.BUSINESS_TIMEZONE) {
  const hoy = diaHabil(new Date(), tz);
  switch (periodo) {
    case 'hoy':
      return { desde: hoy, hasta: hoy };
    case 'ayer': {
      const a = sumarDias(hoy, -1);
      return { desde: a, hasta: a };
    }
    case 'semana':
      return { desde: sumarDias(hoy, -6), hasta: hoy };
    case 'mes':
      return { desde: sumarDias(hoy, -29), hasta: hoy };
    case 'trimestre':
      return { desde: sumarDias(hoy, -89), hasta: hoy };
    case 'anio':
      return { desde: sumarDias(hoy, -364), hasta: hoy };
    default:
      throw new RangeError(`Periodo desconocido: ${periodo}`);
  }
}

/** Date -> 'YYYY-MM-DD HH:MM:SS.mmm' en UTC, apto para DATETIME(3). */
export function aMySQLDateTime(d = new Date()) {
  const x = d instanceof Date ? d : new Date(d);
  return x.toISOString().slice(0, 23).replace('T', ' ');
}
