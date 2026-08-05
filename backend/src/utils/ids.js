/**
 * Identificadores.
 *
 * UUID v7 en lugar de v4: los primeros 48 bits son el timestamp en ms, así que
 * los UUID quedan ordenados por tiempo de creación. Eso importa porque son
 * claves de negocio indexadas: con v4 los inserts caen en posiciones aleatorias
 * del índice B-tree y lo fragmentan; con v7 se insertan al final.
 */
import { v7 as uuidv7, validate as uuidValidate } from 'uuid';
import crypto from 'node:crypto';

export const nuevoUuid = () => uuidv7();

export const esUuid = (v) => typeof v === 'string' && uuidValidate(v);

/** SHA-256 en hex. Se usa para no guardar refresh tokens en claro. */
export const sha256 = (valor) => crypto.createHash('sha256').update(valor).digest('hex');

/** Token opaco aleatorio (para refresh tokens). */
export const tokenAleatorio = (bytes = 48) => crypto.randomBytes(bytes).toString('base64url');

/**
 * Prefijo de folio para un dispositivo nuevo: 2 caracteres del alfabeto
 * Crockford (sin I, L, O, U para que nadie confunda 1/I ni 0/O al leer un
 * ticket impreso). 32² = 1024 combinaciones, suficientes para cualquier tienda.
 */
const ALFABETO = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
export function prefijoFolioAleatorio(longitud = 2) {
  const bytes = crypto.randomBytes(longitud);
  let s = '';
  for (let i = 0; i < longitud; i += 1) s += ALFABETO[bytes[i] % ALFABETO.length];
  return s;
}
