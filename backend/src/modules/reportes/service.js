import { pool, query } from '../../db/pool.js';
import { rangoPeriodo, diaHabil, sumarDias } from '../../utils/dates.js';

/**
 * Todos los agregados agrupan por `fecha_local` (el día hábil de la tienda), no
 * por la fecha UTC de la fila. El servidor corre en UTC y la tienda en
 * America/Bogota: agrupar por UTC partiría el día a las 7:00 p. m. y las ventas
 * de la noche se contarían en el día siguiente.
 *
 * `ONLY_FULL_GROUP_BY` está activo, así que cada columna no agregada aparece
 * explícitamente en el GROUP BY.
 */

const EXPR_AGRUPACION = {
  dia: 'v.fecha_local',
  semana: "DATE_FORMAT(v.fecha_local, '%x-W%v')",
  mes: "DATE_FORMAT(v.fecha_local, '%Y-%m')",
};

export async function ventasPorPeriodo({ desde, hasta, agrupar = 'dia' }) {
  const expr = EXPR_AGRUPACION[agrupar] ?? EXPR_AGRUPACION.dia;
  return query(
    `SELECT ${expr} AS periodo,
            COUNT(*)                     AS num_ventas,
            SUM(v.total)                 AS total,
            SUM(v.subtotal)              AS base,
            SUM(v.impuesto_total)        AS impuesto,
            SUM(v.descuento_total)       AS descuento,
            SUM(v.costo_total)           AS costo,
            SUM(v.total - v.costo_total) AS margen,
            ROUND(AVG(v.total), 2)       AS ticket_promedio,
            MIN(v.fecha_local)           AS primer_dia,
            MAX(v.fecha_local)           AS ultimo_dia
       FROM ventas v
      WHERE v.estado = 'COMPLETADA' AND v.deleted_at IS NULL
        AND v.fecha_local BETWEEN ? AND ?
      GROUP BY ${expr}
      ORDER BY periodo ASC`,
    [desde, hasta],
  );
}

export async function topProductos({ desde, hasta, limite = 10, por = 'unidades' }) {
  const orden = por === 'ingreso' ? 'ingreso DESC' : por === 'margen' ? 'margen DESC' : 'unidades DESC';
  return query(
    `SELECT p.uuid, p.sku, MAX(d.descripcion) AS nombre,
            SUM(d.cantidad)                                  AS unidades,
            SUM(d.total)                                     AS ingreso,
            SUM(d.costo_unitario * d.cantidad)               AS costo,
            SUM(d.total - (d.costo_unitario * d.cantidad))   AS margen,
            COUNT(DISTINCT d.venta_id)                       AS num_ventas
       FROM venta_detalles d
       JOIN ventas v    ON v.id = d.venta_id
       JOIN productos p ON p.id = d.producto_id
      WHERE v.estado = 'COMPLETADA' AND v.deleted_at IS NULL
        AND v.fecha_local BETWEEN ? AND ?
      GROUP BY p.uuid, p.sku
      ORDER BY ${orden}
      LIMIT ?`,
    [desde, hasta, limite],
  );
}

export async function stockBajo({ limite = 50 } = {}) {
  return query('SELECT * FROM v_productos_stock_bajo LIMIT ?', [limite]);
}

export async function valorizacion() {
  const [[resumen]] = await pool.query(
    `SELECT COUNT(*)                                  AS productos,
            SUM(stock_actual)                         AS unidades,
            SUM(valor_costo)                          AS valor_costo,
            SUM(valor_venta)                          AS valor_venta,
            SUM(margen_potencial)                     AS margen_potencial
       FROM v_valorizacion_inventario`,
  );
  const porCategoria = await query(
    `SELECT COALESCE(c.nombre, 'Sin categoría') AS categoria, c.uuid AS categoria_uuid,
            COUNT(p.id)                                       AS productos,
            SUM(p.stock_actual)                               AS unidades,
            ROUND(SUM(p.stock_actual * p.precio_compra), 2)   AS valor_costo,
            ROUND(SUM(p.stock_actual * p.precio_venta), 2)    AS valor_venta
       FROM productos p
       LEFT JOIN categorias c ON c.id = p.categoria_id
      WHERE p.deleted_at IS NULL AND p.activo = 1
      GROUP BY c.uuid, c.nombre
      ORDER BY valor_costo DESC`,
  );
  return { resumen, por_categoria: porCategoria };
}

export async function movimientosResumen({ desde, hasta }) {
  return query(
    `SELECT m.tipo,
            COUNT(*)                                       AS num_movimientos,
            SUM(m.cantidad)                                AS cantidad_neta,
            SUM(ABS(m.cantidad))                           AS cantidad_absoluta,
            SUM(ABS(m.cantidad) * COALESCE(m.costo_unitario, 0)) AS valor
       FROM movimientos_inventario m
      WHERE m.fecha_local BETWEEN ? AND ?
      GROUP BY m.tipo
      ORDER BY num_movimientos DESC`,
    [desde, hasta],
  );
}

/**
 * Resumen para la pantalla principal.
 *
 * Se resuelve en una sola ida a la base con varias subconsultas en lugar de 8
 * peticiones: el dashboard es lo primero que se pinta y la latencia se nota.
 */
export async function dashboard() {
  const hoy = diaHabil();
  const ayer = sumarDias(hoy, -1);
  const semana = rangoPeriodo('semana');
  const mes = rangoPeriodo('mes');

  const [[fila]] = await pool.query(
    `SELECT
       (SELECT COALESCE(SUM(total),0) FROM ventas
         WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local = ?)      AS ventas_hoy,
       (SELECT COUNT(*) FROM ventas
         WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local = ?)      AS num_ventas_hoy,
       (SELECT COALESCE(SUM(total),0) FROM ventas
         WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local = ?)      AS ventas_ayer,
       (SELECT COALESCE(SUM(total),0) FROM ventas
         WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local BETWEEN ? AND ?) AS ventas_semana,
       (SELECT COALESCE(SUM(total),0) FROM ventas
         WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local BETWEEN ? AND ?) AS ventas_mes,
       (SELECT COALESCE(SUM(total - costo_total),0) FROM ventas
         WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local BETWEEN ? AND ?) AS margen_mes,
       (SELECT COUNT(*) FROM productos WHERE deleted_at IS NULL AND activo = 1)     AS productos_activos,
       (SELECT COUNT(*) FROM productos
         WHERE deleted_at IS NULL AND activo = 1 AND stock_actual <= stock_minimo)  AS productos_stock_bajo,
       (SELECT COUNT(*) FROM productos
         WHERE deleted_at IS NULL AND activo = 1 AND stock_actual <= 0)             AS productos_agotados,
       (SELECT COALESCE(SUM(stock_actual * precio_compra),0) FROM productos
         WHERE deleted_at IS NULL AND activo = 1)                                   AS valor_inventario,
       (SELECT COUNT(*) FROM alertas WHERE resuelta_en IS NULL)                      AS alertas_abiertas`,
    [hoy, hoy, ayer, semana.desde, semana.hasta, mes.desde, mes.hasta, mes.desde, mes.hasta],
  );

  const [serie, top, bajos] = await Promise.all([
    ventasPorPeriodo({ desde: sumarDias(hoy, -13), hasta: hoy, agrupar: 'dia' }),
    topProductos({ desde: mes.desde, hasta: mes.hasta, limite: 5 }),
    stockBajo({ limite: 10 }),
  ]);

  return {
    fecha: hoy,
    resumen: fila,
    serie_14_dias: serie,
    top_productos_mes: top,
    stock_bajo: bajos,
  };
}
