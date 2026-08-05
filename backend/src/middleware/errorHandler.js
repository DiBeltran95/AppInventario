import { ApiError } from '../utils/ApiError.js';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';

/**
 * Traduce errores de MariaDB a errores de aplicación con un código estable.
 *
 * Importa que el cliente pueda distinguir "esto no se arregla reintentando" de
 * "esto fue transitorio": la cola de sincronización descarta lo primero y
 * reintenta lo segundo. Ver ApiError.permanente.
 */
function traducirErrorSql(err) {
  switch (err.code) {
    case 'ER_DUP_ENTRY': {
      const m = /Duplicate entry '(.+)' for key '(.+)'/.exec(err.sqlMessage || '');
      const clave = m?.[2] ?? '';
      const valor = m?.[1] ?? '';
      const legible = {
        uk_productos_sku: `Ya existe un producto con el SKU "${valor}"`,
        uk_prodcod_codigo: `El código "${valor}" ya está asignado a otro producto`,
        uk_usuarios_email: `Ya existe un usuario con el correo "${valor}"`,
        uk_ventas_numero: `Ya existe una venta con el número "${valor}"`,
        uk_dispositivos_prefijo: 'Ese prefijo de folio ya está en uso',
      };
      return new ApiError(
        409,
        'DUPLICADO',
        legible[clave] ?? `Valor duplicado en ${clave || 'un índice único'}`,
        { clave, valor },
      );
    }
    case 'ER_NO_REFERENCED_ROW':
    case 'ER_NO_REFERENCED_ROW_2':
      return new ApiError(422, 'REFERENCIA_INVALIDA', 'Se referencia un registro que no existe');
    case 'ER_ROW_IS_REFERENCED':
    case 'ER_ROW_IS_REFERENCED_2':
      return new ApiError(
        409,
        'REFERENCIADO',
        'No se puede eliminar: hay registros que dependen de este',
      );
    case 'ER_DATA_TOO_LONG':
      return new ApiError(400, 'DATO_MUY_LARGO', err.sqlMessage ?? 'Un valor excede su longitud');
    case 'ER_CHECK_CONSTRAINT_VIOLATED':
    case 'ER_CONSTRAINT_FAILED':
      return new ApiError(422, 'RESTRICCION', 'Los datos violan una regla del modelo');
    case 'ER_SIGNAL_EXCEPTION':
      return new ApiError(409, 'REGLA_NEGOCIO', err.sqlMessage ?? 'Operación no permitida');
    case 'ER_LOCK_DEADLOCK':
    case 'ER_LOCK_WAIT_TIMEOUT':
      return new ApiError(
        503,
        'CONCURRENCIA',
        'La base de datos está ocupada; reintenta en unos segundos',
        null,
        { permanente: false },
      );
    case 'ECONNREFUSED':
    case 'PROTOCOL_CONNECTION_LOST':
    case 'ETIMEDOUT':
      return new ApiError(503, 'BD_NO_DISPONIBLE', 'La base de datos no está disponible', null, {
        permanente: false,
      });
    default:
      return null;
  }
}

// eslint-disable-next-line no-unused-vars -- Express identifica el handler por su aridad de 4
export function errorHandler(err, req, res, _next) {
  let error = err;

  if (!(error instanceof ApiError)) {
    const traducido = traducirErrorSql(err);
    if (traducido) {
      error = traducido;
    } else if (err.type === 'entity.parse.failed') {
      error = new ApiError(400, 'JSON_INVALIDO', 'El cuerpo de la petición no es JSON válido');
    } else if (err.type === 'entity.too.large') {
      error = new ApiError(413, 'CUERPO_MUY_GRANDE', 'El cuerpo de la petición es demasiado grande');
    } else if (err.code === 'LIMIT_FILE_SIZE') {
      error = new ApiError(413, 'ARCHIVO_MUY_GRANDE', 'El archivo supera el tamaño permitido');
    } else {
      error = new ApiError(500, 'ERROR_INTERNO', 'Error interno del servidor', null, {
        permanente: false,
      });
    }
  }

  const contexto = {
    metodo: req.method,
    ruta: req.originalUrl,
    usuario: req.usuario?.uuid,
    codigo: error.codigo,
  };

  if (error.status >= 500) {
    logger.error({ err, ...contexto }, error.message);
  } else {
    logger.warn({ ...contexto, detalles: error.detalles }, error.message);
  }

  const cuerpo = error.toJSON();
  if (!env.isProd && error.status >= 500) {
    cuerpo.error.stack = err.stack;
    cuerpo.error.sql = err.sqlMessage;
  }

  res.status(error.status).json(cuerpo);
}

export function notFoundHandler(req, res) {
  res.status(404).json({
    error: {
      codigo: 'RUTA_NO_ENCONTRADA',
      mensaje: `No existe ${req.method} ${req.originalUrl}`,
      permanente: true,
    },
  });
}
