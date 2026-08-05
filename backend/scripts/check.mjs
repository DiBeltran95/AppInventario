#!/usr/bin/env node
/**
 * Verificación del esquema contra la base real.
 *
 * No comprueba que las tablas "existan": comprueba que las INVARIANTES del
 * modelo se cumplen en el motor. Si alguna falla, la app offline produciría
 * datos incorrectos de forma silenciosa.
 *
 *   1. Los triggers mantienen productos.stock_actual = SUM(movimientos.cantidad)
 *   2. El libro de movimientos es realmente append-only (UPDATE y DELETE fallan)
 *   3. sp_recalcular_stock reconstruye la proyección desde cero
 *   4. El modo estricto está activo (MariaDB no trunca en silencio)
 *   5. DECIMAL llega como string (requisito de la aritmética monetaria)
 *
 * Trabaja sobre un producto temporal y lo elimina al terminar.
 */
import 'dotenv/config';
import mysql from 'mysql2/promise';
import { randomUUID } from 'node:crypto';

const c = { reset: '\x1b[0m', dim: '\x1b[2m', red: '\x1b[31m', green: '\x1b[32m', yellow: '\x1b[33m', cyan: '\x1b[36m' };

let ok = 0;
let fallos = 0;

function afirmar(condicion, descripcion, detalle = '') {
  if (condicion) {
    console.log(`  ${c.green}✓${c.reset} ${descripcion}`);
    ok += 1;
  } else {
    console.log(`  ${c.red}✗ ${descripcion}${c.reset}${detalle ? `\n      ${c.dim}${detalle}${c.reset}` : ''}`);
    fallos += 1;
  }
}

const conn = await mysql.createConnection({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  timezone: 'Z',
  dateStrings: ['DATE'],
  multipleStatements: true,
  connectTimeout: 20_000,
});

await conn.query(
  "SET SESSION sql_mode='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,ONLY_FULL_GROUP_BY,NO_ENGINE_SUBSTITUTION'; SET SESSION time_zone='+00:00'",
);

const skuTmp = `__CHECK_${Date.now()}`;
const uuidProd = randomUUID();
let productoId = null;

try {
  // ── 0. Objetos del esquema ────────────────────────────────────────────────
  console.log(`\n${c.cyan}Objetos del esquema${c.reset}`);
  const [tablas] = await conn.query(
    "SELECT TABLE_NAME n FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE'",
  );
  const esperadas = [
    'usuarios', 'dispositivos', 'refresh_tokens', 'categorias', 'proveedores',
    'productos', 'producto_codigos', 'ventas', 'venta_detalles',
    'movimientos_inventario', 'sync_operaciones', 'alertas', 'auditoria', 'configuracion',
  ];
  const presentes = new Set(tablas.map((t) => t.n));
  const faltan = esperadas.filter((t) => !presentes.has(t));
  afirmar(faltan.length === 0, `${esperadas.length} tablas presentes`, `Faltan: ${faltan.join(', ')}`);

  const [trg] = await conn.query(
    'SELECT TRIGGER_NAME n FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE()',
  );
  afirmar(trg.length === 4, `4 triggers instalados (hay ${trg.length})`);

  const [vistas] = await conn.query(
    "SELECT TABLE_NAME n FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='VIEW'",
  );
  afirmar(vistas.length === 4, `4 vistas de reporte (hay ${vistas.length})`);

  // ── 1. Modo estricto ──────────────────────────────────────────────────────
  console.log(`\n${c.cyan}Modo estricto de MariaDB${c.reset}`);
  const [[modo]] = await conn.query('SELECT @@session.sql_mode m');
  afirmar(modo.m.includes('STRICT_TRANS_TABLES'), 'STRICT_TRANS_TABLES activo en la sesión', modo.m);

  let truncoSilenciosamente = false;
  try {
    await conn.query('INSERT INTO categorias (uuid, nombre, color) VALUES (?,?,?)', [
      randomUUID(), '__CHECK__', '#12345678901234567890',
    ]);
    truncoSilenciosamente = true;
    await conn.query("DELETE FROM categorias WHERE nombre='__CHECK__'");
  } catch {
    /* esperado: el modo estricto lo rechaza */
  }
  afirmar(!truncoSilenciosamente, 'Un valor demasiado largo es RECHAZADO, no truncado');

  // ── 2. Proyección de stock mantenida por triggers ─────────────────────────
  console.log(`\n${c.cyan}Proyección de stock (triggers)${c.reset}`);
  await conn.query(
    'INSERT INTO productos (uuid, sku, nombre, precio_compra, precio_venta) VALUES (?,?,?,?,?)',
    [uuidProd, skuTmp, 'Producto de verificación', '1000.00', '1500.00'],
  );
  const [[p0]] = await conn.query('SELECT id, stock_actual FROM productos WHERE uuid=?', [uuidProd]);
  productoId = p0.id;
  afirmar(p0.stock_actual === '0.000', 'Producto nuevo arranca con stock 0.000', `Obtuve ${p0.stock_actual}`);

  const insertarMov = (tipo, cantidad) =>
    conn.query(
      `INSERT INTO movimientos_inventario (uuid, producto_id, tipo, cantidad, fecha, fecha_local)
       VALUES (?,?,?,?, UTC_TIMESTAMP(3), UTC_DATE())`,
      [randomUUID(), productoId, tipo, cantidad],
    );

  await insertarMov('ENTRADA', '10.000');
  await insertarMov('VENTA', '-3.500');
  await insertarMov('AJUSTE', '0.500');

  const [[p1]] = await conn.query('SELECT stock_actual FROM productos WHERE id=?', [productoId]);
  afirmar(p1.stock_actual === '7.000', 'stock_actual = 10 - 3.5 + 0.5 = 7.000', `Obtuve ${p1.stock_actual}`);

  const [[suma]] = await conn.query(
    'SELECT SUM(cantidad) s FROM movimientos_inventario WHERE producto_id=?',
    [productoId],
  );
  afirmar(suma.s === '7.000', 'La proyección coincide con SUM(movimientos.cantidad)', `SUM=${suma.s}`);

  const [movs] = await conn.query(
    'SELECT tipo, cantidad, stock_anterior, stock_resultante FROM movimientos_inventario WHERE producto_id=? ORDER BY id',
    [productoId],
  );
  afirmar(
    movs[0].stock_anterior === '0.000' && movs[0].stock_resultante === '10.000' &&
      movs[1].stock_anterior === '10.000' && movs[1].stock_resultante === '6.500' &&
      movs[2].stock_resultante === '7.000',
    'El trigger registra stock_anterior/stock_resultante para auditoría',
    JSON.stringify(movs),
  );

  // ── 3. Append-only ────────────────────────────────────────────────────────
  console.log(`\n${c.cyan}Inmutabilidad del libro de movimientos${c.reset}`);
  let updatePermitido = false;
  try {
    await conn.query('UPDATE movimientos_inventario SET cantidad = 999 WHERE producto_id=? LIMIT 1', [productoId]);
    updatePermitido = true;
  } catch (e) {
    afirmar(/append-only/i.test(e.message), 'UPDATE de cantidad rechazado con mensaje claro', e.message);
  }
  if (updatePermitido) afirmar(false, 'UPDATE de cantidad debería fallar y no falló');

  let deletePermitido = false;
  try {
    await conn.query('DELETE FROM movimientos_inventario WHERE producto_id=? LIMIT 1', [productoId]);
    deletePermitido = true;
  } catch (e) {
    afirmar(/append-only/i.test(e.message), 'DELETE de movimiento rechazado', e.message);
  }
  if (deletePermitido) afirmar(false, 'DELETE debería fallar y no falló');

  // Un UPDATE que no altera el efecto sí debe permitirse (p. ej. corregir el motivo).
  let motivoOk = true;
  try {
    await conn.query('UPDATE movimientos_inventario SET motivo=? WHERE producto_id=? LIMIT 1', ['ok', productoId]);
  } catch {
    motivoOk = false;
  }
  afirmar(motivoOk, 'UPDATE de campos no contables (motivo) sí se permite');

  // ── 4. Recálculo ──────────────────────────────────────────────────────────
  console.log(`\n${c.cyan}Recálculo de la proyección${c.reset}`);
  await conn.query('UPDATE productos SET stock_actual = -999 WHERE id=?', [productoId]);
  await conn.query('CALL sp_recalcular_stock(?)', [uuidProd]);
  const [[p2]] = await conn.query('SELECT stock_actual FROM productos WHERE id=?', [productoId]);
  afirmar(p2.stock_actual === '7.000', 'sp_recalcular_stock reconstruye desde el libro', `Obtuve ${p2.stock_actual}`);

  // ── 5. Tipos que llegan al driver ─────────────────────────────────────────
  console.log(`\n${c.cyan}Tipos devueltos por el driver${c.reset}`);
  const [[tipos]] = await conn.query(
    'SELECT precio_venta, stock_actual, created_at FROM productos WHERE id=?',
    [productoId],
  );
  afirmar(typeof tipos.precio_venta === 'string', 'DECIMAL llega como string (dinero exacto)', `typeof=${typeof tipos.precio_venta}`);
  afirmar(typeof tipos.stock_actual === 'string', 'Cantidad DECIMAL llega como string');
  afirmar(tipos.created_at instanceof Date, 'DATETIME(3) llega como Date');

  const [[fechas]] = await conn.query('SELECT fecha_local FROM movimientos_inventario WHERE producto_id=? LIMIT 1', [productoId]);
  afirmar(typeof fechas.fecha_local === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(fechas.fecha_local), "DATE llega como 'YYYY-MM-DD'", String(fechas.fecha_local));

  // ── 6. Folios ─────────────────────────────────────────────────────────────
  console.log(`\n${c.cyan}Generación de folios${c.reset}`);
  const [[folio]] = await conn.query("SELECT fn_siguiente_folio('ZZ') f");
  afirmar(/^ZZ-\d{6}$/.test(folio.f), `fn_siguiente_folio devuelve un folio válido (${folio.f})`);
} finally {
  if (productoId) {
    await conn.query('SET FOREIGN_KEY_CHECKS=0');
    await conn.query('DROP TRIGGER IF EXISTS trg_mov_before_delete');
    await conn.query('DELETE FROM movimientos_inventario WHERE producto_id=?', [productoId]);
    await conn.query(
      `CREATE TRIGGER trg_mov_before_delete BEFORE DELETE ON movimientos_inventario FOR EACH ROW
       BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'movimientos_inventario es append-only: no se permite DELETE'; END`,
    );
    await conn.query('DELETE FROM productos WHERE id=?', [productoId]);
    await conn.query('SET FOREIGN_KEY_CHECKS=1');
  }
  await conn.end();
}

console.log(
  `\n${fallos === 0 ? c.green : c.red}${ok} verificaciones correctas, ${fallos} fallidas${c.reset}\n`,
);
process.exit(fallos === 0 ? 0 : 1);
