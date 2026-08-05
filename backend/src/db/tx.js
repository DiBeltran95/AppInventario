/**
 * Transacciones con reintento ante deadlock.
 *
 * Dos dispositivos que sincronizan ventas del mismo producto a la vez toman
 * bloqueos de fila en distinto orden y MariaDB aborta una de las transacciones
 * con ER_LOCK_DEADLOCK. Es una condición esperada, no un error: se reintenta.
 */
import { pool } from './pool.js';
import { logger } from '../utils/logger.js';

const REINTENTABLES = new Set([
  'ER_LOCK_DEADLOCK', // 1213
  'ER_LOCK_WAIT_TIMEOUT', // 1205
]);

const MAX_INTENTOS = 3;

/**
 * Ejecuta `fn(conn)` dentro de una transacción.
 * `fn` recibe la conexión: todas sus consultas DEBEN usarla, o quedarán fuera
 * de la transacción.
 */
export async function withTransaction(fn) {
  let ultimoError;

  for (let intento = 1; intento <= MAX_INTENTOS; intento += 1) {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const resultado = await fn(conn);
      await conn.commit();
      return resultado;
    } catch (err) {
      try {
        await conn.rollback();
      } catch (rollbackErr) {
        logger.error({ err: rollbackErr }, 'Fallo el rollback');
      }

      ultimoError = err;
      if (!REINTENTABLES.has(err.code) || intento === MAX_INTENTOS) throw err;

      const espera = 40 * 2 ** (intento - 1) + Math.floor(Math.random() * 40);
      logger.warn({ code: err.code, intento, espera }, 'Deadlock: reintentando transacción');
      await new Promise((r) => setTimeout(r, espera));
    } finally {
      conn.release();
    }
  }

  throw ultimoError;
}

/** Helpers para usar dentro de una transacción sin repetir el destructuring. */
export async function txQuery(conn, sql, params = []) {
  const [rows] = await conn.query(sql, params);
  return rows;
}

export async function txQueryOne(conn, sql, params = []) {
  const rows = await txQuery(conn, sql, params);
  return rows.length ? rows[0] : null;
}

export async function txExecute(conn, sql, params = []) {
  const [result] = await conn.query(sql, params);
  return result;
}
