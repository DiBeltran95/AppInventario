import { query, queryOne } from '../../db/pool.js';
import { txQuery, txQueryOne, txExecute } from '../../db/tx.js';
import { nuevoUuid } from '../../utils/ids.js';
import { notFound, badRequest, conflict } from '../../utils/ApiError.js';
import { QR_PREFIX } from '../../config/constants.js';
import { diaHabil } from '../../utils/dates.js';

const COLUMNAS = `
  p.uuid, p.sku, p.nombre, p.descripcion, p.unidad_medida,
  p.precio_compra, p.precio_venta, p.tasa_iva,
  p.stock_actual, p.stock_minimo, p.stock_maximo,
  p.imagen_url, p.ubicacion, p.activo,
  p.created_at, p.updated_at,
  c.uuid AS categoria_uuid, c.nombre AS categoria_nombre, c.color AS categoria_color`;

/** Traduce categoria_uuid -> id interno, validando que exista. */
async function resolverCategoria(conn, categoriaUuid) {
  if (categoriaUuid === undefined) return undefined;
  if (categoriaUuid === null || categoriaUuid === '') return null;
  const fila = await txQueryOne(conn, 'SELECT id FROM categorias WHERE uuid = ? AND deleted_at IS NULL', [
    categoriaUuid,
  ]);
  if (!fila) throw badRequest('CATEGORIA_INVALIDA', 'La categoría indicada no existe');
  return fila.id;
}

// ── Lecturas ────────────────────────────────────────────────────────────────

export async function listarProductos(filtros) {
  const where = ['p.deleted_at IS NULL'];
  const params = [];

  if (filtros.activo !== null) {
    where.push('p.activo = ?');
    params.push(filtros.activo ? 1 : 0);
  }
  if (filtros.categoria) {
    where.push('c.uuid = ?');
    params.push(filtros.categoria);
  }
  if (filtros.buscar) {
    // Se busca también por código para que el buscador manual sirva cuando la
    // cámara no lee la etiqueta (envases arrugados, poca luz).
    where.push(`(p.nombre LIKE ? OR p.sku LIKE ? OR EXISTS (
                   SELECT 1 FROM producto_codigos pc
                    WHERE pc.producto_id = p.id AND pc.deleted_at IS NULL AND pc.codigo LIKE ?))`);
    const patron = `%${filtros.buscar}%`;
    params.push(patron, patron, patron);
  }
  switch (filtros.estado_stock) {
    case 'bajo':
      where.push('p.stock_actual <= p.stock_minimo AND p.stock_actual > 0');
      break;
    case 'agotado':
      where.push('p.stock_actual <= 0');
      break;
    case 'disponible':
      where.push('p.stock_actual > p.stock_minimo');
      break;
    default:
      break;
  }

  const orden =
    {
      nombre: 'p.nombre ASC',
      stock: 'p.stock_actual ASC',
      precio: 'p.precio_venta DESC',
      reciente: 'p.created_at DESC',
    }[filtros.orden] ?? 'p.nombre ASC';

  const sqlWhere = `WHERE ${where.join(' AND ')}`;
  const offset = (filtros.pagina - 1) * filtros.limite;

  const [items, [conteo]] = await Promise.all([
    query(
      `SELECT ${COLUMNAS}
         FROM productos p
         LEFT JOIN categorias c ON c.id = p.categoria_id
         ${sqlWhere}
        ORDER BY ${orden}
        LIMIT ? OFFSET ?`,
      [...params, filtros.limite, offset],
    ),
    query(
      `SELECT COUNT(*) total FROM productos p
         LEFT JOIN categorias c ON c.id = p.categoria_id ${sqlWhere}`,
      params,
    ),
  ]);

  return { items, total: Number(conteo.total) };
}

export async function obtenerProducto(uuid) {
  const producto = await queryOne(
    `SELECT ${COLUMNAS}, p.id AS _id
       FROM productos p
       LEFT JOIN categorias c ON c.id = p.categoria_id
      WHERE p.uuid = ? AND p.deleted_at IS NULL`,
    [uuid],
  );
  if (!producto) throw notFound('Producto');

  const codigos = await query(
    'SELECT uuid, codigo, tipo, es_principal, factor FROM producto_codigos WHERE producto_id = ? AND deleted_at IS NULL',
    [producto._id],
  );
  delete producto._id;
  return { ...producto, codigos };
}

/**
 * Resolución de un código escaneado, en el orden definido en el prompt:
 *   1. inv://p/{uuid}  -> QR emitido por esta app
 *   2. producto_codigos.codigo (EAN/UPC/Code128 de fábrica)
 *   3. sku
 *
 * Devuelve también el `factor` del código: escanear la caja de 12 debe agregar
 * 12 unidades, no una.
 */
export async function buscarPorCodigo(codigoBruto) {
  const codigo = String(codigoBruto).trim();

  if (codigo.startsWith(QR_PREFIX)) {
    const uuid = codigo.slice(QR_PREFIX.length);
    const p = await queryOne(
      `SELECT ${COLUMNAS} FROM productos p
         LEFT JOIN categorias c ON c.id = p.categoria_id
        WHERE p.uuid = ? AND p.deleted_at IS NULL`,
      [uuid],
    );
    if (p) return { ...p, factor: '1.000', origen: 'QR_APP' };
  }

  const porCodigo = await queryOne(
    `SELECT ${COLUMNAS}, pc.factor, pc.tipo AS codigo_tipo
       FROM producto_codigos pc
       JOIN productos p ON p.id = pc.producto_id AND p.deleted_at IS NULL
       LEFT JOIN categorias c ON c.id = p.categoria_id
      WHERE pc.codigo = ? AND pc.deleted_at IS NULL`,
    [codigo],
  );
  if (porCodigo) return { ...porCodigo, origen: 'CODIGO' };

  const porSku = await queryOne(
    `SELECT ${COLUMNAS} FROM productos p
       LEFT JOIN categorias c ON c.id = p.categoria_id
      WHERE p.sku = ? AND p.deleted_at IS NULL`,
    [codigo],
  );
  if (porSku) return { ...porSku, factor: '1.000', origen: 'SKU' };

  return null;
}

// ── Mutaciones (usadas por REST y por /sync/push) ───────────────────────────

export async function crearProducto(conn, datos, ctx) {
  const uuid = datos.uuid ?? nuevoUuid();

  // Idempotencia estructural: si el uuid ya existe (reenvío de la cola offline),
  // se converge al mismo estado en lugar de devolver "duplicado".
  const existente = await txQueryOne(conn, 'SELECT id FROM productos WHERE uuid = ?', [uuid]);
  if (existente) return actualizarProducto(conn, uuid, datos, ctx);

  const categoriaId = await resolverCategoria(conn, datos.categoria_uuid);

  const resultado = await txExecute(
    conn,
    `INSERT INTO productos
       (uuid, sku, nombre, descripcion, categoria_id, unidad_medida,
        precio_compra, precio_venta, tasa_iva, stock_minimo, stock_maximo,
        imagen_url, ubicacion, activo)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    [
      uuid,
      datos.sku,
      datos.nombre,
      datos.descripcion ?? null,
      categoriaId ?? null,
      datos.unidad_medida ?? 'UND',
      datos.precio_compra ?? '0.00',
      datos.precio_venta ?? '0.00',
      datos.tasa_iva ?? '19.00',
      datos.stock_minimo ?? '0.000',
      datos.stock_maximo ?? null,
      datos.imagen_url ?? null,
      datos.ubicacion ?? null,
      datos.activo === false ? 0 : 1,
    ],
  );
  const productoId = resultado.insertId;

  for (const c of datos.codigos ?? []) {
    await insertarCodigo(conn, productoId, c);
  }

  if (datos.stock_inicial && Number(datos.stock_inicial) !== 0) {
    await txExecute(
      conn,
      `INSERT INTO movimientos_inventario
         (uuid, producto_id, tipo, cantidad, costo_unitario, usuario_id, dispositivo_uuid,
          motivo, fecha, fecha_local, creado_offline)
       VALUES (?,?, 'INICIAL', ?,?,?,?, 'Existencia inicial', UTC_TIMESTAMP(3), ?, 0)`,
      [
        nuevoUuid(),
        productoId,
        datos.stock_inicial,
        datos.precio_compra ?? null,
        ctx?.usuarioId ?? null,
        ctx?.dispositivoUuid ?? null,
        diaHabil(),
      ],
    );
  }

  return obtenerProductoTx(conn, uuid);
}

export async function actualizarProducto(conn, uuid, datos, _ctx) {
  const producto = await txQueryOne(conn, 'SELECT id FROM productos WHERE uuid = ?', [uuid]);
  if (!producto) throw notFound('Producto');

  const asignaciones = [];
  const valores = [];

  const directos = [
    'sku', 'nombre', 'descripcion', 'unidad_medida', 'precio_compra', 'precio_venta',
    'tasa_iva', 'stock_minimo', 'stock_maximo', 'imagen_url', 'ubicacion',
  ];
  for (const campo of directos) {
    if (datos[campo] !== undefined) {
      asignaciones.push(`${campo} = ?`);
      valores.push(datos[campo]);
    }
  }
  if (datos.activo !== undefined) {
    asignaciones.push('activo = ?');
    valores.push(datos.activo ? 1 : 0);
  }
  if (datos.categoria_uuid !== undefined) {
    asignaciones.push('categoria_id = ?');
    valores.push(await resolverCategoria(conn, datos.categoria_uuid));
  }

  // Nunca se acepta stock_actual desde el cliente: es derivado del libro de
  // movimientos. Un cliente que lo envíe está intentando algo incorrecto.
  if (datos.stock_actual !== undefined) {
    throw badRequest(
      'STOCK_NO_EDITABLE',
      'stock_actual es derivado. Para corregirlo registra un movimiento de AJUSTE.',
    );
  }

  if (!asignaciones.length) return obtenerProductoTx(conn, uuid);

  // Reactivar un producto borrado forma parte de la convergencia offline.
  asignaciones.push('deleted_at = NULL');
  valores.push(producto.id);
  await txExecute(conn, `UPDATE productos SET ${asignaciones.join(', ')} WHERE id = ?`, valores);

  return obtenerProductoTx(conn, uuid);
}

export async function eliminarProducto(conn, uuid, _ctx) {
  const producto = await txQueryOne(conn, 'SELECT id, stock_actual FROM productos WHERE uuid = ?', [uuid]);
  if (!producto) throw notFound('Producto');

  await txExecute(
    conn,
    'UPDATE productos SET deleted_at = UTC_TIMESTAMP(3), activo = 0 WHERE id = ?',
    [producto.id],
  );
  // Los códigos también, para que su valor único quede libre y el mismo EAN
  // pueda reasignarse a otro producto.
  await txExecute(
    conn,
    'UPDATE producto_codigos SET deleted_at = UTC_TIMESTAMP(3) WHERE producto_id = ? AND deleted_at IS NULL',
    [producto.id],
  );

  return { uuid, eliminado: true };
}

async function insertarCodigo(conn, productoId, codigo) {
  const uuid = codigo.uuid ?? nuevoUuid();
  const yaExiste = await txQueryOne(
    conn,
    'SELECT id, producto_id, deleted_at FROM producto_codigos WHERE codigo = ?',
    [codigo.codigo],
  );

  if (yaExiste) {
    if (yaExiste.producto_id !== productoId && !yaExiste.deleted_at) {
      throw conflict(
        'CODIGO_EN_USO',
        `El código "${codigo.codigo}" ya pertenece a otro producto`,
        { codigo: codigo.codigo },
      );
    }
    await txExecute(
      conn,
      `UPDATE producto_codigos
          SET producto_id = ?, tipo = ?, es_principal = ?, factor = ?, deleted_at = NULL
        WHERE id = ?`,
      [productoId, codigo.tipo, codigo.es_principal ? 1 : 0, codigo.factor ?? '1.000', yaExiste.id],
    );
    return uuid;
  }

  await txExecute(
    conn,
    `INSERT INTO producto_codigos (uuid, producto_id, codigo, tipo, es_principal, factor)
     VALUES (?,?,?,?,?,?)`,
    [uuid, productoId, codigo.codigo, codigo.tipo, codigo.es_principal ? 1 : 0, codigo.factor ?? '1.000'],
  );
  return uuid;
}

export async function agregarCodigo(conn, productoUuid, codigo, _ctx) {
  const producto = await txQueryOne(conn, 'SELECT id FROM productos WHERE uuid = ? AND deleted_at IS NULL', [
    productoUuid,
  ]);
  if (!producto) throw notFound('Producto');
  const uuid = await insertarCodigo(conn, producto.id, codigo);
  return txQueryOne(
    conn,
    'SELECT uuid, codigo, tipo, es_principal, factor FROM producto_codigos WHERE uuid = ?',
    [uuid],
  );
}

export async function eliminarCodigo(conn, codigoUuid, _ctx) {
  const fila = await txQueryOne(conn, 'SELECT id FROM producto_codigos WHERE uuid = ?', [codigoUuid]);
  if (!fila) throw notFound('Código');
  await txExecute(
    conn,
    'UPDATE producto_codigos SET deleted_at = UTC_TIMESTAMP(3) WHERE id = ?',
    [fila.id],
  );
  return { uuid: codigoUuid, eliminado: true };
}

/** Igual que obtenerProducto pero dentro de la transacción en curso. */
async function obtenerProductoTx(conn, uuid) {
  const producto = await txQueryOne(
    conn,
    `SELECT ${COLUMNAS}, p.id AS _id
       FROM productos p
       LEFT JOIN categorias c ON c.id = p.categoria_id
      WHERE p.uuid = ?`,
    [uuid],
  );
  if (!producto) throw notFound('Producto');
  const codigos = await txQuery(
    conn,
    'SELECT uuid, codigo, tipo, es_principal, factor FROM producto_codigos WHERE producto_id = ? AND deleted_at IS NULL',
    [producto._id],
  );
  delete producto._id;
  return { ...producto, codigos };
}
