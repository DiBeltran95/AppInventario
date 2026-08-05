#!/usr/bin/env node
/**
 * Datos iniciales.
 *
 * Idempotente: se puede ejecutar varias veces. Los productos se insertan con
 * ON DUPLICATE KEY UPDATE sobre el SKU y el stock inicial sólo se crea si el
 * producto aún no tiene movimientos — así una segunda ejecución no infla el
 * inventario.
 *
 * Uso:
 *   node scripts/seed.mjs
 *   node scripts/seed.mjs --password "MiClaveSegura"
 */
import 'dotenv/config';
import mysql from 'mysql2/promise';
import * as argon2 from '@node-rs/argon2';
import { v7 as uuidv7 } from 'uuid';

const c = { reset: '\x1b[0m', dim: '\x1b[2m', green: '\x1b[32m', cyan: '\x1b[36m', yellow: '\x1b[33m' };

const args = process.argv.slice(2);
const idxPass = args.indexOf('--password');
const PASSWORD_ADMIN = idxPass >= 0 ? args[idxPass + 1] : 'Admin1234';
const PASSWORD_VENDEDOR = 'Vendedor1234';

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
  "SET SESSION sql_mode='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'; SET SESSION time_zone='+00:00'",
);

const hash = (p) => argon2.hash(p, { memoryCost: 19_456, timeCost: 2, parallelism: 1 });

// ── Configuración ────────────────────────────────────────────────────────────
const CONFIG = [
  ['nombre_negocio', 'Mi Tienda', 'STRING', 'Nombre que aparece en el ticket'],
  ['nit', '900123456-7', 'STRING', 'NIT o identificación fiscal'],
  ['direccion', 'Calle 10 # 5-23, Popayán', 'STRING', null],
  ['telefono', '3001234567', 'STRING', null],
  ['moneda', 'COP', 'STRING', null],
  ['zona_horaria', process.env.BUSINESS_TIMEZONE ?? 'America/Bogota', 'STRING', null],
  ['iva_por_defecto', '19.00', 'DECIMAL', 'Tasa aplicada a productos nuevos'],
  ['permitir_stock_negativo', 'true', 'BOOL', 'Acepta sobreventa offline y genera alerta'],
  ['ticket_pie', '¡Gracias por su compra!', 'STRING', null],
  ['offline_grace_days', String(process.env.OFFLINE_GRACE_DAYS ?? 7), 'INT', 'Días que la app opera sin ver el servidor'],
];

// ── Catálogo de ejemplo ──────────────────────────────────────────────────────
const CATEGORIAS = [
  { nombre: 'Bebidas', color: '#0EA5E9', icono: 'local_drink', orden: 1 },
  { nombre: 'Snacks', color: '#F59E0B', icono: 'cookie', orden: 2 },
  { nombre: 'Aseo', color: '#10B981', icono: 'cleaning_services', orden: 3 },
  { nombre: 'Granos y abarrotes', color: '#8B5CF6', icono: 'rice_bowl', orden: 4 },
  { nombre: 'Lácteos', color: '#EC4899', icono: 'egg', orden: 5 },
];

const PROVEEDORES = [
  { nombre: 'Distribuidora del Cauca', nit: '891500123-4', contacto: 'Marta Ruiz', telefono: '3145550101' },
  { nombre: 'Alimentos del Valle S.A.S.', nit: '900777888-1', contacto: 'Jorge Peña', telefono: '3185550202' },
];

const PRODUCTOS = [
  // sku, nombre, categoría, compra, venta, iva, stock, mínimo, unidad, ean
  ['BEB-001', 'Gaseosa cola 400 ml', 'Bebidas', '1800.00', '2500.00', '19.00', '48.000', '12.000', 'UND', '7702004003515'],
  ['BEB-002', 'Agua sin gas 600 ml', 'Bebidas', '900.00', '1500.00', '19.00', '60.000', '24.000', 'UND', '7702090031508'],
  ['BEB-003', 'Jugo de naranja 1 L', 'Bebidas', '3200.00', '4500.00', '19.00', '18.000', '6.000', 'UND', '7702025103218'],
  ['SNK-001', 'Papas fritas naturales 45 g', 'Snacks', '1500.00', '2200.00', '19.00', '35.000', '15.000', 'UND', '7702189025487'],
  ['SNK-002', 'Galletas de avena x6', 'Snacks', '2400.00', '3500.00', '19.00', '8.000', '10.000', 'PAQ', '7702025010219'],
  ['ASE-001', 'Jabón en barra 300 g', 'Aseo', '2100.00', '3000.00', '19.00', '22.000', '8.000', 'UND', '7702191140016'],
  ['ASE-002', 'Detergente en polvo 1 kg', 'Aseo', '6800.00', '9500.00', '19.00', '14.000', '5.000', 'UND', '7702191001225'],
  ['GRA-001', 'Arroz blanco 500 g', 'Granos y abarrotes', '2300.00', '3200.00', '5.00', '40.000', '10.000', 'UND', '7702084010015'],
  ['GRA-002', 'Fríjol cargamanto 500 g', 'Granos y abarrotes', '4500.00', '6200.00', '5.00', '16.000', '6.000', 'UND', '7702084020021'],
  ['GRA-003', 'Panela pulverizada 500 g', 'Granos y abarrotes', '2800.00', '3900.00', '0.00', '25.000', '8.000', 'UND', null],
  ['LAC-001', 'Leche entera 1 L', 'Lácteos', '3100.00', '4200.00', '0.00', '30.000', '12.000', 'UND', '7702001005017'],
  ['LAC-002', 'Queso campesino 500 g', 'Lácteos', '9500.00', '13000.00', '0.00', '6.000', '4.000', 'UND', null],
  ['LAC-003', 'Yogur de fresa 1 L', 'Lácteos', '5200.00', '7000.00', '0.00', '3.000', '6.000', 'UND', '7702001320011'],
];

console.log(`${c.cyan}Sembrando ${process.env.DB_NAME}...${c.reset}\n`);

await conn.beginTransaction();
try {
  // 1. Configuración
  for (const [clave, valor, tipo, descripcion] of CONFIG) {
    await conn.query(
      `INSERT INTO configuracion (clave, valor, tipo, descripcion) VALUES (?,?,?,?)
       ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion)`,
      [clave, valor, tipo, descripcion],
    );
  }
  console.log(`  ${c.green}✓${c.reset} ${CONFIG.length} claves de configuración`);

  // 2. Usuarios
  const usuarios = [
    ['Administrador', 'admin@inventario.local', PASSWORD_ADMIN, 'ADMIN'],
    ['Vendedor', 'vendedor@inventario.local', PASSWORD_VENDEDOR, 'VENDEDOR'],
  ];
  let adminId = null;
  for (const [nombre, email, pass, rol] of usuarios) {
    const [existe] = await conn.query('SELECT id FROM usuarios WHERE email = ?', [email]);
    if (existe.length) {
      if (rol === 'ADMIN') adminId = existe[0].id;
      console.log(`  ${c.dim}·${c.reset} ${email} ya existía (contraseña sin cambios)`);
      continue;
    }
    const [r] = await conn.query(
      'INSERT INTO usuarios (uuid, nombre, email, password_hash, rol) VALUES (?,?,?,?,?)',
      [uuidv7(), nombre, email, await hash(pass), rol],
    );
    if (rol === 'ADMIN') adminId = r.insertId;
    console.log(`  ${c.green}✓${c.reset} Usuario ${email} (${rol})`);
  }

  // 3. Categorías
  const idCategoria = new Map();
  for (const cat of CATEGORIAS) {
    const [existe] = await conn.query('SELECT id FROM categorias WHERE nombre = ?', [cat.nombre]);
    if (existe.length) {
      idCategoria.set(cat.nombre, existe[0].id);
      continue;
    }
    const [r] = await conn.query(
      'INSERT INTO categorias (uuid, nombre, color, icono, orden) VALUES (?,?,?,?,?)',
      [uuidv7(), cat.nombre, cat.color, cat.icono, cat.orden],
    );
    idCategoria.set(cat.nombre, r.insertId);
  }
  console.log(`  ${c.green}✓${c.reset} ${CATEGORIAS.length} categorías`);

  // 4. Proveedores
  for (const p of PROVEEDORES) {
    await conn.query(
      `INSERT INTO proveedores (uuid, nombre, nit, contacto, telefono) VALUES (?,?,?,?,?)
       ON DUPLICATE KEY UPDATE nombre = VALUES(nombre)`,
      [uuidv7(), p.nombre, p.nit, p.contacto, p.telefono],
    );
  }
  console.log(`  ${c.green}✓${c.reset} ${PROVEEDORES.length} proveedores`);

  // 5. Productos + códigos + stock inicial
  let creados = 0;
  let conStock = 0;
  for (const [sku, nombre, categoria, compra, venta, iva, stock, minimo, unidad, ean] of PRODUCTOS) {
    const [existe] = await conn.query('SELECT id FROM productos WHERE sku = ?', [sku]);
    let productoId;

    if (existe.length) {
      productoId = existe[0].id;
    } else {
      const [r] = await conn.query(
        `INSERT INTO productos
           (uuid, sku, nombre, categoria_id, unidad_medida, precio_compra, precio_venta,
            tasa_iva, stock_minimo)
         VALUES (?,?,?,?,?,?,?,?,?)`,
        [uuidv7(), sku, nombre, idCategoria.get(categoria), unidad, compra, venta, iva, minimo],
      );
      productoId = r.insertId;
      creados += 1;
    }

    if (ean) {
      await conn.query(
        `INSERT INTO producto_codigos (uuid, producto_id, codigo, tipo, es_principal)
         VALUES (?,?,?, 'EAN13', 1)
         ON DUPLICATE KEY UPDATE producto_id = VALUES(producto_id), deleted_at = NULL`,
        [uuidv7(), productoId, ean],
      );
    }

    // Stock inicial sólo si el producto no tiene historial: así reejecutar el
    // seed no duplica existencias.
    const [movs] = await conn.query(
      'SELECT COUNT(*) n FROM movimientos_inventario WHERE producto_id = ?',
      [productoId],
    );
    if (Number(movs[0].n) === 0) {
      await conn.query(
        `INSERT INTO movimientos_inventario
           (uuid, producto_id, tipo, cantidad, costo_unitario, usuario_id, motivo, fecha, fecha_local)
         VALUES (?,?, 'INICIAL', ?,?,?, 'Carga inicial del catálogo', UTC_TIMESTAMP(3), UTC_DATE())`,
        [uuidv7(), productoId, stock, compra, adminId],
      );
      conStock += 1;
    }
  }
  console.log(`  ${c.green}✓${c.reset} ${PRODUCTOS.length} productos (${creados} nuevos, ${conStock} con stock inicial)`);

  await conn.commit();
} catch (err) {
  await conn.rollback();
  console.error('\nFallo el sembrado:', err);
  await conn.end();
  process.exit(1);
}

const [[resumen]] = await conn.query(`
  SELECT (SELECT COUNT(*) FROM productos WHERE deleted_at IS NULL) p,
         (SELECT COUNT(*) FROM categorias WHERE deleted_at IS NULL) c,
         (SELECT COUNT(*) FROM usuarios WHERE deleted_at IS NULL) u,
         (SELECT COALESCE(SUM(stock_actual * precio_compra),0) FROM productos WHERE deleted_at IS NULL) v`);

console.log(`
${c.green}Listo.${c.reset}
  Productos: ${resumen.p}   Categorías: ${resumen.c}   Usuarios: ${resumen.u}
  Valor del inventario a costo: $${Number(resumen.v).toLocaleString('es-CO')}

${c.yellow}Credenciales de acceso${c.reset}
  admin@inventario.local     ${PASSWORD_ADMIN}      (ADMIN)
  vendedor@inventario.local  ${PASSWORD_VENDEDOR}   (VENDEDOR)

  ${c.dim}Cámbialas antes de usar esto con datos reales.${c.reset}
`);

await conn.end();
