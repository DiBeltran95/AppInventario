/**
 * Configuración validada al arranque.
 *
 * Se valida con Zod y se falla rápido: es preferible que el proceso no arranque
 * a que reviente en la primera petición por un secreto ausente.
 */
import 'dotenv/config';
import { z } from 'zod';

const bool = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1');

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),

  /// Interfaz de escucha. Vacío = doble pila (IPv6 + IPv4), que es lo que hace
  /// falta detrás de un proxy que puede llamar por cualquiera de las dos.
  /// Sólo se fija para restringir la escucha a propósito (p. ej. '127.0.0.1').
  HOST: z.string().optional(),
  CORS_ORIGINS: z.string().default(''),

  DB_HOST: z.string().min(1),
  DB_PORT: z.coerce.number().int().positive().default(3306),
  DB_USER: z.string().min(1),
  DB_PASSWORD: z.string(),
  DB_NAME: z.string().min(1),
  DB_CONNECTION_LIMIT: z.coerce.number().int().positive().default(10),
  DB_SSL: bool.default('false'),

  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET debe tener al menos 32 caracteres'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET debe tener al menos 32 caracteres'),
  JWT_ACCESS_TTL: z.string().default('15m'),
  JWT_REFRESH_TTL_DAYS: z.coerce.number().int().positive().default(30),

  BUSINESS_TIMEZONE: z.string().default('America/Bogota'),
  CURRENCY: z.string().length(3).default('COP'),
  ALLOW_NEGATIVE_STOCK: bool.default('true'),
  DEFAULT_TAX_RATE: z.coerce.number().min(0).max(100).default(19),
  OFFLINE_GRACE_DAYS: z.coerce.number().int().positive().default(7),

  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_UPLOAD_MB: z.coerce.number().positive().default(5),
  PUBLIC_BASE_URL: z.string().url().default('http://localhost:3000'),

  RATE_LIMIT_WINDOW_MIN: z.coerce.number().int().positive().default(15),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(600),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(10),
  SYNC_PUSH_MAX_OPS: z.coerce.number().int().positive().default(200),
  SYNC_PULL_MAX_ROWS: z.coerce.number().int().positive().default(500),
});

/**
 * Quita las comillas que envuelven un valor.
 *
 * En un archivo `.env`, dotenv ya interpreta `CLAVE='valor'` y entrega `valor`
 * sin comillas. Pero en el **panel de variables de entorno** de un alojamiento
 * (alwaysdata, Heroku, Railway…) el valor se toma **literal**: escribir ahí
 * `'mi-clave'` produce una contraseña de 10 caracteres que empieza y termina en
 * comilla, y MariaDB responde `ER_ACCESS_DENIED_ERROR`.
 *
 * El síntoma es cruel porque el `.env` local funciona y el servidor no, con la
 * misma contraseña a la vista. Se limpia y se avisa: dejarlo pasar en silencio
 * escondería que la configuración del panel está mal escrita.
 */
function limpiarComillas(clave, valor) {
  if (typeof valor !== 'string' || valor.length < 2) return valor;

  const primera = valor[0];
  const ultima = valor[valor.length - 1];
  if ((primera !== "'" && primera !== '"') || primera !== ultima) return valor;

  const limpio = valor.slice(1, -1);
  console.warn(
    `[config] ${clave} venía envuelta en comillas (${primera}…${primera}) y se han quitado. ` +
      'Si la definiste en el panel de tu alojamiento, bórralas allí: ese panel guarda ' +
      'el valor tal cual, comillas incluidas.',
  );
  return limpio;
}

const entorno = {};
for (const clave of Object.keys(schema.shape)) {
  if (process.env[clave] !== undefined) {
    entorno[clave] = limpiarComillas(clave, process.env[clave]);
  }
}

const parsed = schema.safeParse(entorno);

if (!parsed.success) {
  const detalle = parsed.error.issues
    .map((i) => `  · ${i.path.join('.')}: ${i.message}`)
    .join('\n');
  console.error(
    `\n[config] Variables de entorno inválidas o ausentes:\n${detalle}\n\n` +
      'Copia backend/.env.example a backend/.env y complétalo.\n',
  );
  process.exit(1);
}

export const env = {
  ...parsed.data,
  isProd: parsed.data.NODE_ENV === 'production',
  isDev: parsed.data.NODE_ENV === 'development',
  corsOrigins: parsed.data.CORS_ORIGINS.split(',')
    .map((s) => s.trim())
    .filter(Boolean),
};

// En producción, secretos de ejemplo son un fallo de despliegue, no un aviso.
if (env.isProd) {
  const inseguros = ['cambia-esto', 'secret', 'changeme'];
  for (const clave of ['JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET']) {
    if (inseguros.some((p) => env[clave].toLowerCase().includes(p))) {
      console.error(`[config] ${clave} conserva un valor de ejemplo. Abortando.`);
      process.exit(1);
    }
  }
  if (env.JWT_ACCESS_SECRET === env.JWT_REFRESH_SECRET) {
    console.error('[config] JWT_ACCESS_SECRET y JWT_REFRESH_SECRET deben ser distintos. Abortando.');
    process.exit(1);
  }
}

export default env;
