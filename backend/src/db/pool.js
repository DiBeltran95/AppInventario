/**
 * Pool de conexiones a MariaDB.
 *
 * Dos ajustes aquí NO son opcionales:
 *
 * 1. `SET SESSION sql_mode`. El servidor llega con un sql_mode SIN
 *    STRICT_TRANS_TABLES: MariaDB truncaría un VARCHAR(64) que recibe 200
 *    caracteres y devolvería éxito. Se fuerza modo estricto en cada conexión.
 *
 * 2. `decimalNumbers` se deja en false (por defecto). mysql2 devuelve DECIMAL
 *    como string y así debe quedarse: convertirlo a Number reintroduce el error
 *    de coma flotante en el dinero. Ver src/utils/money.js.
 */
import mysql from 'mysql2/promise';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';

const SESSION_INIT = [
  "SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,ONLY_FULL_GROUP_BY,NO_ENGINE_SUBSTITUTION'",
  "SET SESSION time_zone = '+00:00'",
  'SET SESSION transaction_isolation = "READ-COMMITTED"',
].join('; ');

export const pool = mysql.createPool({
  host: env.DB_HOST,
  port: env.DB_PORT,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  database: env.DB_NAME,
  waitForConnections: true,
  connectionLimit: env.DB_CONNECTION_LIMIT,
  maxIdle: env.DB_CONNECTION_LIMIT,
  idleTimeout: 60_000,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10_000,
  charset: 'utf8mb4_unicode_ci',
  // Interpreta y envía DATETIME como UTC. El servidor corre en UTC.
  timezone: 'Z',
  // DATE como 'YYYY-MM-DD' (día hábil), DATETIME como Date.
  dateStrings: ['DATE'],
  supportBigNumbers: true,
  bigNumberStrings: false,
  multipleStatements: true, // sólo lo usa el inicializador de sesión
  ...(env.DB_SSL ? { ssl: { rejectUnauthorized: true } } : {}),
});

pool.on('connection', (conn) => {
  conn.query(SESSION_INIT, (err) => {
    if (err) logger.error({ err }, 'No se pudo inicializar la sesión de MariaDB');
  });
});

/** Consulta simple. Devuelve sólo las filas. */
export async function query(sql, params = []) {
  const [rows] = await pool.query(sql, params);
  return rows;
}

/** Consulta que espera 0 o 1 fila. */
export async function queryOne(sql, params = []) {
  const rows = await query(sql, params);
  return rows.length ? rows[0] : null;
}

/** Verifica que la base responde y es la versión esperada. */
export async function pingDatabase() {
  const row = await queryOne('SELECT VERSION() AS version, NOW(3) AS ahora');
  return row;
}

export async function closePool() {
  await pool.end();
}

export default pool;
