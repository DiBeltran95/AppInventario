import { pool, query, queryOne } from '../../db/pool.js';
import { withTransaction, txQueryOne, txExecute } from '../../db/tx.js';
import { ApiError } from '../../utils/ApiError.js';
import { logger } from '../../utils/logger.js';
import { env } from '../../config/env.js';
import { CONSULTAS, ENTIDADES } from './pullQueries.js';
import { sumarDias, diaHabil } from '../../utils/dates.js';

import * as productos from '../productos/service.js';
import * as inventario from '../inventario/service.js';
import * as ventas from '../ventas/service.js';
import { repoCategorias } from '../categorias/index.js';
import { repoProveedores } from '../proveedores/index.js';

/**
 * Manejadores de operaciones de subida.
 *
 * Cada uno recibe la conexión de una transacción abierta y debe dejar el
 * sistema en el estado final de la operación. Son EXACTAMENTE los mismos
 * servicios que usan las rutas REST: no hay una "vía de sincronización" con
 * reglas distintas que pueda divergir de la vía normal.
 */
const MANEJADORES = {
  PRODUCTO_CREAR: (conn, p, ctx) => productos.crearProducto(conn, p, ctx),
  PRODUCTO_ACTUALIZAR: (conn, p, ctx) => productos.actualizarProducto(conn, p.uuid, p, ctx),
  PRODUCTO_ELIMINAR: (conn, p, ctx) => productos.eliminarProducto(conn, p.uuid, ctx),
  CODIGO_CREAR: (conn, p, ctx) => productos.agregarCodigo(conn, p.producto_uuid, p, ctx),
  CODIGO_ELIMINAR: (conn, p, ctx) => productos.eliminarCodigo(conn, p.uuid, ctx),

  CATEGORIA_CREAR: (conn, p) => repoCategorias.crearOActualizar(conn, p),
  CATEGORIA_ACTUALIZAR: (conn, p) => repoCategorias.actualizar(conn, p.uuid, p),
  CATEGORIA_ELIMINAR: (conn, p) => repoCategorias.eliminar(conn, p.uuid),

  PROVEEDOR_CREAR: (conn, p) => repoProveedores.crearOActualizar(conn, p),
  PROVEEDOR_ACTUALIZAR: (conn, p) => repoProveedores.actualizar(conn, p.uuid, p),
  PROVEEDOR_ELIMINAR: (conn, p) => repoProveedores.eliminar(conn, p.uuid),

  MOVIMIENTO_CREAR: (conn, p, ctx) => inventario.crearMovimiento(conn, p, ctx),
  CONTEO_AJUSTAR: (conn, p, ctx) => inventario.ajustarPorConteo(conn, p, ctx),

  VENTA_CREAR: (conn, p, ctx) => ventas.crearVenta(conn, p, ctx),
  VENTA_ANULAR: (conn, p, ctx) => ventas.anularVenta(conn, p, ctx),
};

const ENTIDAD_DE = {
  PRODUCTO_CREAR: 'productos', PRODUCTO_ACTUALIZAR: 'productos', PRODUCTO_ELIMINAR: 'productos',
  CODIGO_CREAR: 'producto_codigos', CODIGO_ELIMINAR: 'producto_codigos',
  CATEGORIA_CREAR: 'categorias', CATEGORIA_ACTUALIZAR: 'categorias', CATEGORIA_ELIMINAR: 'categorias',
  PROVEEDOR_CREAR: 'proveedores', PROVEEDOR_ACTUALIZAR: 'proveedores', PROVEEDOR_ELIMINAR: 'proveedores',
  MOVIMIENTO_CREAR: 'movimientos_inventario', CONTEO_AJUSTAR: 'movimientos_inventario',
  VENTA_CREAR: 'ventas', VENTA_ANULAR: 'ventas',
};

/**
 * Procesa un lote de operaciones de subida.
 *
 * Se procesan SECUENCIALMENTE, cada una en su propia transacción. Secuencial
 * porque el orden importa: crear un producto y venderlo en el mismo lote sólo
 * funciona si el alta se aplica antes. Transacción por operación —y no una
 * para todo el lote— porque una operación rechazada no debe tumbar las 49
 * válidas que van detrás.
 *
 * @returns un resultado por operación, en el mismo orden que llegaron.
 */
export async function procesarPush(operaciones, ctx) {
  const resultados = [];

  for (const op of operaciones) {
    resultados.push(await procesarOperacion(op, ctx));
  }

  if (ctx.dispositivoUuid) {
    await query('UPDATE dispositivos SET ultimo_sync_at = UTC_TIMESTAMP(3) WHERE uuid = ?', [
      ctx.dispositivoUuid,
    ]);
  }

  return resultados;
}

async function procesarOperacion(op, ctx) {
  const { client_op_id: opId, tipo, payload } = op;

  // ── 1. ¿Ya se procesó? ────────────────────────────────────────────────────
  // Esta consulta es la que impide cobrar dos veces cuando la respuesta al
  // primer intento se perdió por un corte de señal.
  const previa = await queryOne(
    'SELECT estado, http_status, respuesta FROM sync_operaciones WHERE client_op_id = ?',
    [opId],
  );
  if (previa) {
    return {
      client_op_id: opId,
      estado: previa.estado,
      http_status: previa.http_status,
      resultado: previa.respuesta ? JSON.parse(previa.respuesta) : null,
      reprocesada: false,
      idempotente: true,
    };
  }

  const manejador = MANEJADORES[tipo];
  if (!manejador) {
    return registrarRechazo(op, ctx, new ApiError(400, 'TIPO_DESCONOCIDO', `Operación no soportada: ${tipo}`));
  }

  // ── 2. Aplicar el efecto y memorizar el resultado EN LA MISMA TRANSACCIÓN ──
  // Si el efecto se confirmara y el registro de idempotencia no, un reintento
  // volvería a aplicarlo. Van juntos o no van.
  try {
    const resultado = await withTransaction(async (conn) => {
      const salida = await manejador(conn, payload, ctx);

      await txExecute(
        conn,
        `INSERT INTO sync_operaciones
           (client_op_id, tipo, entidad, entidad_uuid, usuario_id, dispositivo_uuid,
            estado, http_status, respuesta)
         VALUES (?,?,?,?,?,?, 'OK', 200, ?)`,
        [
          opId,
          tipo,
          ENTIDAD_DE[tipo] ?? 'desconocida',
          salida?.uuid ?? payload?.uuid ?? null,
          ctx.usuarioId ?? null,
          ctx.dispositivoUuid ?? null,
          JSON.stringify(salida ?? null),
        ],
      );

      return salida;
    });

    return {
      client_op_id: opId,
      estado: 'OK',
      http_status: 200,
      resultado,
      reprocesada: true,
      idempotente: false,
    };
  } catch (err) {
    // Carrera: dos envíos simultáneos del mismo op_id. El segundo choca contra
    // la PK y debe devolver lo que guardó el primero.
    if (err.code === 'ER_DUP_ENTRY' && err.sqlMessage?.includes('PRIMARY')) {
      const guardada = await queryOne(
        'SELECT estado, http_status, respuesta FROM sync_operaciones WHERE client_op_id = ?',
        [opId],
      );
      if (guardada) {
        return {
          client_op_id: opId,
          estado: guardada.estado,
          http_status: guardada.http_status,
          resultado: guardada.respuesta ? JSON.parse(guardada.respuesta) : null,
          reprocesada: false,
          idempotente: true,
        };
      }
    }
    return registrarRechazo(op, ctx, err);
  }
}

/**
 * Un error PERMANENTE (validación, referencia inexistente) se memoriza para que
 * el cliente lo saque de la cola: reintentarlo nunca va a funcionar y
 * bloquearía todo lo que viene detrás.
 *
 * Un error TRANSITORIO (base caída, deadlock) NO se memoriza: se devuelve tal
 * cual para que el cliente reintente con backoff.
 */
async function registrarRechazo(op, ctx, err) {
  const apiError =
    err instanceof ApiError
      ? err
      : new ApiError(500, 'ERROR_INTERNO', err.message ?? 'Error desconocido', null, { permanente: false });

  const cuerpo = {
    codigo: apiError.codigo,
    mensaje: apiError.message,
    detalles: apiError.detalles,
    permanente: apiError.permanente,
  };

  if (apiError.permanente) {
    try {
      await query(
        `INSERT INTO sync_operaciones
           (client_op_id, tipo, entidad, entidad_uuid, usuario_id, dispositivo_uuid,
            estado, http_status, respuesta)
         VALUES (?,?,?,?,?,?, 'ERROR', ?, ?)
         ON DUPLICATE KEY UPDATE respuesta = VALUES(respuesta)`,
        [
          op.client_op_id,
          op.tipo,
          ENTIDAD_DE[op.tipo] ?? 'desconocida',
          op.payload?.uuid ?? null,
          ctx.usuarioId ?? null,
          ctx.dispositivoUuid ?? null,
          apiError.status,
          JSON.stringify(cuerpo),
        ],
      );
    } catch (e) {
      logger.error({ err: e, opId: op.client_op_id }, 'No se pudo registrar el rechazo de sincronización');
    }
  } else {
    logger.warn({ opId: op.client_op_id, tipo: op.tipo, err: apiError.message }, 'Operación de sync fallida (transitoria)');
  }

  return {
    client_op_id: op.client_op_id,
    estado: 'ERROR',
    http_status: apiError.status,
    error: cuerpo,
    reprocesada: false,
    idempotente: false,
  };
}

// ── Bajada ──────────────────────────────────────────────────────────────────

const CURSOR_CERO = { t: '1970-01-01T00:00:00.000Z', i: 0 };

function normalizarCursor(c) {
  if (!c || typeof c !== 'object') return CURSOR_CERO;
  const t = typeof c.t === 'string' ? c.t : CURSOR_CERO.t;
  const fecha = new Date(t);
  return {
    t: Number.isNaN(fecha.getTime()) ? CURSOR_CERO.t : fecha.toISOString(),
    i: Number.isInteger(c.i) && c.i >= 0 ? c.i : 0,
  };
}

/**
 * Bajada delta.
 *
 * @param cursores  { productos: {t, i}, ventas: {t, i}, ... }
 * @param opciones  { limite, diasHistorial, entidades }
 */
export async function pull(cursores = {}, { limite, diasHistorial = 90, entidades } = {}, ctx = {}) {
  const tope = Math.min(limite ?? env.SYNC_PULL_MAX_ROWS, env.SYNC_PULL_MAX_ROWS);
  const horizonte = sumarDias(diaHabil(), -Math.abs(diasHistorial));
  const objetivo = entidades?.length ? ENTIDADES.filter((e) => entidades.includes(e)) : ENTIDADES;

  const salida = {};
  let hayMas = false;

  // Se lanzan en paralelo: son SELECT independientes y el pool tiene holgura.
  await Promise.all(
    objetivo.map(async (entidad) => {
      const def = CONSULTAS[entidad];
      const cursor = normalizarCursor(cursores[entidad]);
      const fechaCursor = new Date(cursor.t);

      const params = def.horizonte
        ? [fechaCursor, fechaCursor, cursor.i, horizonte, tope]
        : [fechaCursor, fechaCursor, cursor.i, tope];

      const [filas] = await pool.query(def.sql, params);

      const ultimo = filas.at(-1);
      const nuevoCursor = ultimo
        ? { t: new Date(ultimo.updated_at).toISOString(), i: Number(ultimo._id) }
        : cursor;

      for (const f of filas) delete f._id;

      if (filas.length >= tope) hayMas = true;

      salida[entidad] = {
        items: filas,
        cursor: nuevoCursor,
        hay_mas: filas.length >= tope,
      };
    }),
  );

  // La configuración es una decena de filas: se manda entera siempre. Paginarla
  // costaría más de lo que ahorra.
  salida.configuracion = {
    items: await query('SELECT clave, valor, tipo, updated_at FROM configuracion'),
    cursor: null,
    hay_mas: false,
  };

  if (ctx.dispositivoUuid) {
    await query('UPDATE dispositivos SET ultimo_sync_at = UTC_TIMESTAMP(3) WHERE uuid = ?', [
      ctx.dispositivoUuid,
    ]);
  }

  return {
    entidades: salida,
    hay_mas: hayMas,
    horizonte,
    servidor_utc: new Date().toISOString(),
    zona_negocio: env.BUSINESS_TIMEZONE,
  };
}

/** Diagnóstico: qué sabe el servidor de este dispositivo. */
export async function estado(ctx) {
  const dispositivo = ctx.dispositivoUuid
    ? await queryOne(
        'SELECT uuid, nombre, prefijo_folio, ultimo_sync_at, app_version FROM dispositivos WHERE uuid = ?',
        [ctx.dispositivoUuid],
      )
    : null;

  const [conteos] = await pool.query(`
    SELECT
      (SELECT COUNT(*) FROM productos WHERE deleted_at IS NULL) AS productos,
      (SELECT COUNT(*) FROM ventas WHERE deleted_at IS NULL) AS ventas,
      (SELECT COUNT(*) FROM movimientos_inventario) AS movimientos,
      (SELECT COUNT(*) FROM alertas WHERE resuelta_en IS NULL) AS alertas_abiertas`);

  const recientes = ctx.dispositivoUuid
    ? await query(
        `SELECT client_op_id, tipo, estado, http_status, created_at
           FROM sync_operaciones WHERE dispositivo_uuid = ?
          ORDER BY created_at DESC LIMIT 20`,
        [ctx.dispositivoUuid],
      )
    : [];

  return {
    dispositivo,
    conteos: conteos[0],
    operaciones_recientes: recientes,
    servidor_utc: new Date().toISOString(),
    zona_negocio: env.BUSINESS_TIMEZONE,
    limite_push: env.SYNC_PUSH_MAX_OPS,
    limite_pull: env.SYNC_PULL_MAX_ROWS,
  };
}

/**
 * Purga registros de idempotencia antiguos.
 *
 * Se conservan 30 días: mucho más que cualquier ventana realista de reintento,
 * y suficiente para investigar una duplicación reportada por el usuario.
 */
export async function purgarOperaciones(dias = 30) {
  const r = await pool.query(
    'DELETE FROM sync_operaciones WHERE created_at < DATE_SUB(UTC_TIMESTAMP(3), INTERVAL ? DAY)',
    [dias],
  );
  return { eliminadas: r[0].affectedRows };
}

/** Elimina refresh tokens caducados o revocados hace mucho. */
export async function purgarTokens() {
  const r = await pool.query(
    'DELETE FROM refresh_tokens WHERE expires_at < UTC_TIMESTAMP(3) OR revoked_at < DATE_SUB(UTC_TIMESTAMP(3), INTERVAL 7 DAY)',
  );
  return { eliminados: r[0].affectedRows };
}
