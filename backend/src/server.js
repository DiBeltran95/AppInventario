import { crearApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './utils/logger.js';
import { pingDatabase, closePool } from './db/pool.js';

const app = crearApp();

// Se comprueba la base ANTES de aceptar tráfico: es preferible fallar al
// arrancar que devolver 500 a la primera venta que llegue.
try {
  const bd = await pingDatabase();
  logger.info({ motor: bd.version, ahora: bd.ahora }, 'Base de datos conectada');
} catch (err) {
  logger.error({ err }, `No se pudo conectar a ${env.DB_HOST}/${env.DB_NAME}`);

  // Un volcado de stack no le dice a nadie qué hacer. Los tres fallos de
  // despliegue que ocurren de verdad tienen causas muy concretas.
  const pistas = {
    ER_ACCESS_DENIED_ERROR: [
      `MariaDB rechazó al usuario "${env.DB_USER}". La contraseña llegó con ${env.DB_PASSWORD.length} caracteres.`,
      'Si ese número no coincide con tu contraseña real, sobran comillas o espacios en la variable DB_PASSWORD.',
      'Compruébala directamente:',
      `  mysql -h ${env.DB_HOST} -u ${env.DB_USER} -p ${env.DB_NAME} -e "SELECT 1"`,
    ],
    ER_BAD_DB_ERROR: [
      `El usuario existe pero la base "${env.DB_NAME}" no. Créala en el panel o corrige DB_NAME.`,
    ],
    ENOTFOUND: [`El host "${env.DB_HOST}" no resuelve. Revisa DB_HOST.`],
    ETIMEDOUT: [
      `Sin respuesta de ${env.DB_HOST}:${env.DB_PORT}. Puede ser un cortafuegos o que la base`,
      'sólo acepte conexiones desde la propia red del alojamiento.',
    ],
  }[err?.code];

  if (pistas) {
    for (const linea of pistas) logger.error(linea);
  } else {
    logger.error('Revisa las variables DB_* del entorno (o de backend/.env en local).');
  }
  process.exit(1);
}

/**
 * Escucha en DOBLE PILA (IPv6 + IPv4) salvo que se pida otra cosa.
 *
 * `0.0.0.0` es el comodín de **IPv4 solamente**. Parece que escucha «en todas
 * partes», pero un proxy que se conecte por IPv6 —lo normal en alojamientos
 * modernos como alwaysdata, cuya red es IPv6 nativa— se encuentra la puerta
 * cerrada y el usuario ve un 502 «connection failure», con el proceso vivo y
 * los logs diciendo que todo está bien. Es de los fallos más difíciles de ver.
 *
 * Omitir `host` hace que Node se enlace a `::`, que acepta IPv6 y también IPv4
 * (mapeado). `HOST` sólo se fija para restringir la escucha a propósito.
 *
 * `exclusive: true` es imprescindible en Windows. Node activa SO_REUSEADDR por
 * defecto y Windows, a diferencia de Linux, permite que un segundo proceso se
 * enlace a un puerto YA ocupado: arranca, imprime "escuchando" y no recibe una
 * sola petición porque el tráfico se lo queda el primero. Con `exclusive` el
 * conflicto sale como EADDRINUSE, que es lo que uno espera.
 */
const servidor = app.listen(
  { port: env.PORT, exclusive: true, ...(env.HOST ? { host: env.HOST } : {}) },
  () => {
    const dir = servidor.address();
    // Se registra la dirección REAL, no la que creemos: es el dato que dice si
    // el proxy va a poder alcanzarnos.
    logger.info(
      `API escuchando en ${dir.address}:${dir.port} (${dir.family})` +
        (dir.family === 'IPv6' ? ' — acepta IPv6 e IPv4' : ' — SÓLO IPv4'),
    );
    logger.info(`  Salud:  http://localhost:${env.PORT}/health`);
    logger.info(`  Base:   /api/v1`);
    logger.info(`  Zona de negocio: ${env.BUSINESS_TIMEZONE} · Moneda: ${env.CURRENCY}`);
  },
);

servidor.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    logger.error(
      `El puerto ${env.PORT} ya está ocupado por otro proceso. ` +
        'Cámbialo con PORT=3100 en backend/.env o libera el puerto.',
    );
  } else {
    logger.error({ err }, 'Error del servidor HTTP');
  }
  process.exit(1);
});

/**
 * Apagado ordenado.
 *
 * Importa especialmente aquí: si el proceso muere a mitad de un /sync/push, una
 * transacción a medias podría dejar una venta aplicada sin su registro de
 * idempotencia. Se deja de aceptar conexiones, se terminan las que están en
 * curso y sólo entonces se cierra el pool.
 */
let cerrando = false;
async function apagar(senal) {
  if (cerrando) return;
  cerrando = true;
  logger.info(`${senal} recibida; cerrando...`);

  const forzar = setTimeout(() => {
    logger.error('El cierre ordenado tardó demasiado; forzando salida');
    process.exit(1);
  }, 15_000);
  forzar.unref();

  servidor.close(async () => {
    try {
      await closePool();
      logger.info('Cerrado correctamente');
      process.exit(0);
    } catch (err) {
      logger.error({ err }, 'Error al cerrar el pool');
      process.exit(1);
    }
  });
}

process.on('SIGTERM', () => apagar('SIGTERM'));
process.on('SIGINT', () => apagar('SIGINT'));
process.on('unhandledRejection', (err) => {
  logger.error({ err }, 'Promesa rechazada sin manejar');
});
process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'Excepción no capturada; cerrando');
  apagar('uncaughtException');
});
