import { query } from '../../db/pool.js';
import { txQueryOne, txExecute } from '../../db/tx.js';
import { nuevoUuid } from '../../utils/ids.js';
import { notFound, badRequest, conflict } from '../../utils/ApiError.js';
import { TIPOS_MOVIMIENTO } from '../../config/constants.js';
import { env } from '../../config/env.js';
import { diaHabil } from '../../utils/dates.js';
import { toQty, fromQty } from '../../utils/money.js';

/**
 * Bloquea la fila del producto y devuelve su estado actual.
 *
 * `FOR UPDATE` serializa los movimientos concurrentes del mismo producto: dos
 * ventas simultáneas del último artículo se aplican una tras otra en lugar de
 * leer ambas el mismo stock y pisarse.
 *
 * Quien vaya a tocar varios productos DEBE bloquearlos en orden creciente de
 * `id` — ver `bloquearProductos` — o dos transacciones que los tomen en orden
 * distinto se interbloquearán.
 */
export async function bloquearProducto(conn, productoUuid) {
  const producto = await txQueryOne(
    conn,
    `SELECT id, uuid, sku, nombre, stock_actual, precio_compra, precio_venta, tasa_iva
       FROM productos WHERE uuid = ? AND deleted_at IS NULL FOR UPDATE`,
    [productoUuid],
  );
  if (!producto) throw notFound(`Producto ${productoUuid}`);
  return producto;
}

/** Bloquea varios productos en orden determinista para no provocar deadlocks. */
export async function bloquearProductos(conn, uuids) {
  const unicos = [...new Set(uuids)];
  if (!unicos.length) return new Map();

  const marcadores = unicos.map(() => '?').join(',');
  // El ORDER BY id es lo que garantiza el orden de adquisición de bloqueos.
  const filas = await conn
    .query(
      `SELECT id, uuid, sku, nombre, stock_actual, precio_compra, precio_venta, tasa_iva
         FROM productos
        WHERE uuid IN (${marcadores}) AND deleted_at IS NULL
        ORDER BY id
          FOR UPDATE`,
      unicos,
    )
    .then(([r]) => r);

  const mapa = new Map(filas.map((f) => [f.uuid, f]));
  const faltantes = unicos.filter((u) => !mapa.has(u));
  if (faltantes.length) {
    throw badRequest('PRODUCTO_INEXISTENTE', 'Algunos productos no existen o fueron eliminados', {
      uuids: faltantes,
    });
  }
  return mapa;
}

/**
 * Inserta un movimiento en el libro. NO actualiza `productos.stock_actual`:
 * de eso se encargan los triggers (ver database/schema.sql §15). Duplicar esa
 * actualización aquí descuadraría el stock al doble.
 *
 * @param producto fila ya bloqueada con FOR UPDATE
 */
export async function insertarMovimiento(conn, producto, datos, ctx) {
  const signo = TIPOS_MOVIMIENTO[datos.tipo];
  if (signo === undefined) throw badRequest('TIPO_INVALIDO', `Tipo de movimiento inválido: ${datos.tipo}`);

  const magnitud = toQty(datos.cantidad);
  if (magnitud === 0n) throw badRequest('CANTIDAD_CERO', 'La cantidad no puede ser cero');

  // Para todos los tipos salvo AJUSTE, el signo lo impone el tipo: el cliente
  // no puede convertir una VENTA en una entrada mandando cantidad positiva.
  const abs = magnitud < 0n ? -magnitud : magnitud;
  const cantidad = signo === 0 ? magnitud : BigInt(signo) * abs;

  const stockPrevio = toQty(producto.stock_actual);
  const stockNuevo = stockPrevio + cantidad;

  if (stockNuevo < 0n && !env.ALLOW_NEGATIVE_STOCK) {
    throw conflict(
      'STOCK_INSUFICIENTE',
      `Stock insuficiente de "${producto.nombre}": hay ${fromQty(stockPrevio)} y se intentan sacar ${fromQty(-cantidad)}`,
      { producto_uuid: producto.uuid, disponible: fromQty(stockPrevio) },
    );
  }

  const uuid = datos.uuid ?? nuevoUuid();

  // Idempotencia: reenvío de la cola offline con el mismo uuid de movimiento.
  const yaExiste = await txQueryOne(conn, 'SELECT id FROM movimientos_inventario WHERE uuid = ?', [uuid]);
  if (yaExiste) return { uuid, duplicado: true, stock_resultante: producto.stock_actual };

  let proveedorId = null;
  if (datos.proveedor_uuid) {
    const prov = await txQueryOne(conn, 'SELECT id FROM proveedores WHERE uuid = ?', [datos.proveedor_uuid]);
    if (!prov) throw badRequest('PROVEEDOR_INVALIDO', 'El proveedor indicado no existe');
    proveedorId = prov.id;
  }

  const fecha = datos.fecha ? new Date(datos.fecha) : new Date();
  if (Number.isNaN(fecha.getTime())) throw badRequest('FECHA_INVALIDA', 'La fecha del movimiento no es válida');

  await txExecute(
    conn,
    `INSERT INTO movimientos_inventario
       (uuid, producto_id, tipo, cantidad, costo_unitario, precio_unitario,
        venta_id, proveedor_id, usuario_id, dispositivo_uuid,
        lote, vence_el, documento_ref, motivo, fecha, fecha_local, creado_offline)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    [
      uuid,
      producto.id,
      datos.tipo,
      fromQty(cantidad),
      datos.costo_unitario ?? null,
      datos.precio_unitario ?? null,
      datos.venta_id ?? null,
      proveedorId,
      ctx?.usuarioId ?? null,
      ctx?.dispositivoUuid ?? null,
      datos.lote ?? null,
      datos.vence_el ?? null,
      datos.documento_ref ?? null,
      datos.motivo ?? null,
      fecha,
      datos.fecha_local ?? diaHabil(fecha),
      datos.creado_offline ? 1 : 0,
    ],
  );

  // Mantiene coherente la copia en memoria para movimientos encadenados sobre
  // el mismo producto dentro de la misma transacción.
  producto.stock_actual = fromQty(stockNuevo);

  if (stockNuevo < 0n) {
    await registrarAlerta(conn, {
      tipo: 'STOCK_NEGATIVO',
      severidad: 'CRITICA',
      productoId: producto.id,
      ventaId: datos.venta_id ?? null,
      mensaje: `"${producto.nombre}" quedó en ${fromQty(stockNuevo)}. Probable venta sin conexión sobre existencias agotadas.`,
    });
  }

  return { uuid, stock_resultante: fromQty(stockNuevo), stock_anterior: fromQty(stockPrevio) };
}

export async function registrarAlerta(conn, { tipo, severidad, productoId, ventaId, mensaje, detalle }) {
  await txExecute(
    conn,
    `INSERT INTO alertas (uuid, tipo, severidad, producto_id, venta_id, mensaje, detalle)
     VALUES (?,?,?,?,?,?,?)`,
    [nuevoUuid(), tipo, severidad ?? 'ADVERTENCIA', productoId ?? null, ventaId ?? null, mensaje, detalle ? JSON.stringify(detalle) : null],
  );
}

// ── Operaciones de alto nivel ───────────────────────────────────────────────

/** Entrada/salida/merma/devolución manual sobre un producto. */
export async function crearMovimiento(conn, datos, ctx) {
  const producto = await bloquearProducto(conn, datos.producto_uuid);
  const resultado = await insertarMovimiento(conn, producto, datos, ctx);

  // El costo de compra se actualiza con la última entrada: es el criterio que
  // espera un tendero ("¿a cómo me quedó?"), más simple que un promedio móvil.
  if (datos.tipo === 'ENTRADA' && datos.costo_unitario && !resultado.duplicado) {
    await txExecute(conn, 'UPDATE productos SET precio_compra = ? WHERE id = ?', [
      datos.costo_unitario,
      producto.id,
    ]);
  }

  return {
    ...resultado,
    producto: { uuid: producto.uuid, sku: producto.sku, nombre: producto.nombre },
    tipo: datos.tipo,
  };
}

/**
 * Ajuste por conteo físico: el usuario dice cuánto hay realmente y el sistema
 * calcula el delta. Es más seguro que pedirle la diferencia, que casi siempre
 * se calcula mal.
 */
export async function ajustarPorConteo(conn, datos, ctx) {
  const producto = await bloquearProducto(conn, datos.producto_uuid);
  const actual = toQty(producto.stock_actual);
  const contado = toQty(datos.stock_contado);
  const delta = contado - actual;

  if (delta === 0n) {
    return { sin_cambios: true, stock_actual: producto.stock_actual, producto: { uuid: producto.uuid, nombre: producto.nombre } };
  }

  const resultado = await insertarMovimiento(
    conn,
    producto,
    {
      uuid: datos.uuid,
      tipo: 'AJUSTE',
      cantidad: fromQty(delta),
      motivo: datos.motivo ?? `Conteo físico: ${fromQty(actual)} -> ${fromQty(contado)}`,
      fecha: datos.fecha,
      creado_offline: datos.creado_offline,
    },
    ctx,
  );

  return {
    ...resultado,
    diferencia: fromQty(delta),
    producto: { uuid: producto.uuid, sku: producto.sku, nombre: producto.nombre },
  };
}

// ── Lecturas ────────────────────────────────────────────────────────────────

export async function listarMovimientos(filtros) {
  const where = [];
  const params = [];

  if (filtros.producto) {
    where.push('p.uuid = ?');
    params.push(filtros.producto);
  }
  if (filtros.tipo) {
    where.push('m.tipo = ?');
    params.push(filtros.tipo);
  }
  if (filtros.desde) {
    where.push('m.fecha_local >= ?');
    params.push(filtros.desde);
  }
  if (filtros.hasta) {
    where.push('m.fecha_local <= ?');
    params.push(filtros.hasta);
  }
  if (filtros.proveedor) {
    where.push('pr.uuid = ?');
    params.push(filtros.proveedor);
  }

  const sqlWhere = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (filtros.pagina - 1) * filtros.limite;

  const [items, [conteo]] = await Promise.all([
    query(
      `SELECT m.uuid, m.tipo, m.cantidad, m.costo_unitario, m.precio_unitario,
              m.stock_anterior, m.stock_resultante, m.lote, m.vence_el,
              m.documento_ref, m.motivo, m.fecha, m.fecha_local, m.creado_offline,
              p.uuid AS producto_uuid, p.sku, p.nombre AS producto_nombre,
              u.uuid AS usuario_uuid, u.nombre AS usuario_nombre,
              pr.uuid AS proveedor_uuid, pr.nombre AS proveedor_nombre,
              v.uuid AS venta_uuid, v.numero AS venta_numero
         FROM movimientos_inventario m
         JOIN productos p ON p.id = m.producto_id
         LEFT JOIN usuarios u ON u.id = m.usuario_id
         LEFT JOIN proveedores pr ON pr.id = m.proveedor_id
         LEFT JOIN ventas v ON v.id = m.venta_id
         ${sqlWhere}
        ORDER BY m.fecha DESC, m.id DESC
        LIMIT ? OFFSET ?`,
      [...params, filtros.limite, offset],
    ),
    query(
      `SELECT COUNT(*) total FROM movimientos_inventario m
         JOIN productos p ON p.id = m.producto_id
         LEFT JOIN proveedores pr ON pr.id = m.proveedor_id ${sqlWhere}`,
      params,
    ),
  ]);

  return { items, total: Number(conteo.total) };
}

export async function listarAlertas({ resueltas = false, limite = 100 } = {}) {
  return query(
    `SELECT a.uuid, a.tipo, a.severidad, a.mensaje, a.detalle, a.created_at, a.resuelta_en,
            p.uuid AS producto_uuid, p.nombre AS producto_nombre, p.sku,
            v.uuid AS venta_uuid, v.numero AS venta_numero
       FROM alertas a
       LEFT JOIN productos p ON p.id = a.producto_id
       LEFT JOIN ventas v ON v.id = a.venta_id
      WHERE a.resuelta_en IS ${resueltas ? 'NOT NULL' : 'NULL'}
      ORDER BY FIELD(a.severidad,'CRITICA','ADVERTENCIA','INFO'), a.created_at DESC
      LIMIT ?`,
    [limite],
  );
}

export async function resolverAlerta(conn, uuid, usuarioId) {
  const alerta = await txQueryOne(conn, 'SELECT id FROM alertas WHERE uuid = ?', [uuid]);
  if (!alerta) throw notFound('Alerta');
  await txExecute(
    conn,
    'UPDATE alertas SET resuelta_en = UTC_TIMESTAMP(3), resuelta_por = ? WHERE id = ?',
    [usuarioId, alerta.id],
  );
  return { uuid, resuelta: true };
}

/** Reconstruye la proyección de stock desde el libro. Red de seguridad. */
export async function recalcularStock(productoUuid = null) {
  await query('CALL sp_recalcular_stock(?)', [productoUuid ?? '']);
  return { recalculado: productoUuid ?? 'todos' };
}
