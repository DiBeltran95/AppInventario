/**
 * Consultas de bajada delta, una por entidad.
 *
 * Todas comparten la misma forma de paginación: cursor KEYSET sobre
 * `(updated_at, id)`.
 *
 *   WHERE updated_at > :t OR (updated_at = :t AND id > :i)
 *   ORDER BY updated_at, id
 *
 * Por qué keyset y no `WHERE updated_at > :t` a secas: varias filas pueden
 * compartir el mismo milisegundo. Con un cursor de sólo tiempo, al paginar se
 * saltan filas (si usas `>`) o se repiten para siempre (si usas `>=`). El par
 * (updated_at, id) es un orden total. Por lo mismo no se usa OFFSET: con datos
 * que cambian entre páginas, OFFSET pierde y duplica filas.
 *
 * Todas las claves foráneas se exponen como UUID, nunca como id interno: el
 * cliente no conoce —ni debe conocer— los AUTO_INCREMENT del servidor.
 *
 * Los borrados viajan como filas con `deleted_at` no nulo. Por eso el borrado
 * lógico es obligatorio: un DELETE físico no dejaría nada que sincronizar y el
 * dispositivo desconectado nunca se enteraría.
 */

const KEYSET = (alias) =>
  `(${alias}.updated_at > ? OR (${alias}.updated_at = ? AND ${alias}.id > ?))`;

export const CONSULTAS = {
  usuarios: {
    horizonte: false,
    sql: `
      SELECT u.id AS _id, u.uuid, u.nombre, u.email, u.rol, u.activo,
             u.updated_at, u.deleted_at
        FROM usuarios u
       WHERE ${KEYSET('u')}
       ORDER BY u.updated_at, u.id LIMIT ?`,
  },

  categorias: {
    horizonte: false,
    sql: `
      SELECT c.id AS _id, c.uuid, c.nombre, c.descripcion, c.color, c.icono, c.orden,
             c.updated_at, c.deleted_at
        FROM categorias c
       WHERE ${KEYSET('c')}
       ORDER BY c.updated_at, c.id LIMIT ?`,
  },

  proveedores: {
    horizonte: false,
    sql: `
      SELECT pr.id AS _id, pr.uuid, pr.nombre, pr.nit, pr.contacto, pr.telefono,
             pr.email, pr.direccion, pr.notas, pr.updated_at, pr.deleted_at
        FROM proveedores pr
       WHERE ${KEYSET('pr')}
       ORDER BY pr.updated_at, pr.id LIMIT ?`,
  },

  productos: {
    horizonte: false,
    sql: `
      SELECT p.id AS _id, p.uuid, p.sku, p.nombre, p.descripcion,
             c.uuid AS categoria_uuid, p.unidad_medida,
             p.precio_compra, p.precio_venta, p.tasa_iva,
             p.stock_actual, p.stock_minimo, p.stock_maximo,
             p.imagen_url, p.ubicacion, p.activo,
             p.updated_at, p.deleted_at
        FROM productos p
        LEFT JOIN categorias c ON c.id = p.categoria_id
       WHERE ${KEYSET('p')}
       ORDER BY p.updated_at, p.id LIMIT ?`,
  },

  producto_codigos: {
    horizonte: false,
    sql: `
      SELECT pc.id AS _id, pc.uuid, p.uuid AS producto_uuid, pc.codigo, pc.tipo,
             pc.es_principal, pc.factor, pc.updated_at, pc.deleted_at
        FROM producto_codigos pc
        JOIN productos p ON p.id = pc.producto_id
       WHERE ${KEYSET('pc')}
       ORDER BY pc.updated_at, pc.id LIMIT ?`,
  },

  ventas: {
    horizonte: true,
    sql: `
      SELECT v.id AS _id, v.uuid, v.numero, u.uuid AS usuario_uuid, v.dispositivo_uuid,
             v.cliente_nombre, v.cliente_documento,
             v.subtotal, v.descuento_total, v.impuesto_total, v.total, v.costo_total,
             v.metodo_pago, v.monto_recibido, v.cambio, v.estado,
             vo.uuid AS anula_a_venta_uuid, v.motivo_anulacion, v.notas,
             v.fecha, v.fecha_local, v.creada_offline,
             v.updated_at, v.deleted_at
        FROM ventas v
        LEFT JOIN usuarios u ON u.id = v.usuario_id
        LEFT JOIN ventas vo ON vo.id = v.anula_a_venta_id
       WHERE ${KEYSET('v')} AND v.fecha_local >= ?
       ORDER BY v.updated_at, v.id LIMIT ?`,
  },

  venta_detalles: {
    horizonte: true,
    sql: `
      SELECT d.id AS _id, d.uuid, v.uuid AS venta_uuid, p.uuid AS producto_uuid,
             d.linea, d.descripcion, d.sku_snapshot, d.cantidad,
             d.precio_unitario, d.costo_unitario, d.descuento, d.tasa_iva,
             d.base_gravable, d.impuesto, d.total, d.updated_at
        FROM venta_detalles d
        JOIN ventas v ON v.id = d.venta_id
        LEFT JOIN productos p ON p.id = d.producto_id
       WHERE ${KEYSET('d')} AND v.fecha_local >= ?
       ORDER BY d.updated_at, d.id LIMIT ?`,
  },

  movimientos_inventario: {
    horizonte: true,
    sql: `
      SELECT m.id AS _id, m.uuid, p.uuid AS producto_uuid, m.tipo, m.cantidad,
             m.costo_unitario, m.precio_unitario, m.stock_anterior, m.stock_resultante,
             v.uuid AS venta_uuid, pr.uuid AS proveedor_uuid, u.uuid AS usuario_uuid,
             m.dispositivo_uuid, m.lote, m.vence_el, m.documento_ref, m.motivo,
             m.fecha, m.fecha_local, m.creado_offline, m.updated_at
        FROM movimientos_inventario m
        JOIN productos p ON p.id = m.producto_id
        LEFT JOIN ventas v ON v.id = m.venta_id
        LEFT JOIN proveedores pr ON pr.id = m.proveedor_id
        LEFT JOIN usuarios u ON u.id = m.usuario_id
       WHERE ${KEYSET('m')} AND m.fecha_local >= ?
       ORDER BY m.updated_at, m.id LIMIT ?`,
  },

  alertas: {
    horizonte: false,
    sql: `
      SELECT a.id AS _id, a.uuid, a.tipo, a.severidad, p.uuid AS producto_uuid,
             v.uuid AS venta_uuid, a.mensaje, a.detalle, a.resuelta_en, a.updated_at
        FROM alertas a
        LEFT JOIN productos p ON p.id = a.producto_id
        LEFT JOIN ventas v ON v.id = a.venta_id
       WHERE ${KEYSET('a')}
       ORDER BY a.updated_at, a.id LIMIT ?`,
  },
};

export const ENTIDADES = Object.keys(CONSULTAS);
