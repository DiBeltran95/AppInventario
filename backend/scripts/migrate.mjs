#!/usr/bin/env node
/**
 * Aplica database/schema.sql contra MariaDB.
 *
 * Por qué existe en lugar de `mysql < schema.sql`:
 *
 *  1. `DELIMITER` es una directiva del CLIENTE mysql, no del servidor. Ningún
 *     driver la entiende. Sin interpretarla aquí, cada `;` dentro del cuerpo de
 *     un trigger partiría la sentencia por la mitad.
 *  2. Permite reportar exactamente qué sentencia falló, con su número.
 *  3. No exige tener el cliente `mysql` instalado (aquí no lo hay).
 *
 * Uso:
 *   node scripts/migrate.mjs            aplica el esquema (idempotente)
 *   node scripts/migrate.mjs --drop     BORRA todo y lo recrea
 *   node scripts/migrate.mjs --dry-run  sólo lista las sentencias
 */
import 'dotenv/config';
import mysql from 'mysql2/promise';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import readline from 'node:readline/promises';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RAIZ = resolve(__dirname, '..', '..');
const DIR_DB = join(RAIZ, 'database');

const args = new Set(process.argv.slice(2));
const DROP = args.has('--drop');
const DRY = args.has('--dry-run');
const FORZAR = args.has('--yes') || args.has('-y');

const c = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

/**
 * Parte un script SQL en sentencias respetando la directiva DELIMITER.
 *
 * Limitación conocida y aceptada: no analiza literales de cadena, así que un
 * `;` al final de una línea dentro de una cadena partiría mal la sentencia.
 * El schema.sql de este proyecto no tiene ese caso.
 */
export function partirSql(sql) {
  const sentencias = [];
  let delimitador = ';';
  let buffer = '';

  for (const linea of sql.split(/\r?\n/)) {
    const limpia = linea.trim();

    // Líneas de comentario puro: nunca forman parte de una sentencia.
    if (limpia === '' || limpia.startsWith('--')) {
      if (!buffer.trim()) continue;
      if (limpia.startsWith('--')) continue;
    }

    const cambio = /^DELIMITER\s+(\S+)\s*$/i.exec(limpia);
    if (cambio) {
      if (buffer.trim()) {
        sentencias.push(buffer.trim());
        buffer = '';
      }
      delimitador = cambio[1];
      continue;
    }

    buffer += `${linea}\n`;

    if (limpia.endsWith(delimitador)) {
      const completa = buffer.trim();
      const cuerpo = completa.slice(0, completa.length - delimitador.length).trim();
      if (cuerpo) sentencias.push(cuerpo);
      buffer = '';
    }
  }

  if (buffer.trim()) sentencias.push(buffer.trim());
  return sentencias;
}

function etiqueta(sentencia) {
  const s = sentencia.replace(/\s+/g, ' ').trim();
  const m =
    /^(CREATE (?:OR REPLACE )?(?:TABLE|VIEW|TRIGGER|PROCEDURE|FUNCTION|INDEX)(?: IF NOT EXISTS)?)\s+`?([\w$]+)`?/i.exec(
      s,
    ) ||
    /^(DROP (?:TABLE|VIEW|TRIGGER|PROCEDURE|FUNCTION)(?: IF EXISTS)?)\s+`?([\w$]+)`?/i.exec(s) ||
    /^(SET|ALTER|INSERT|UPDATE)\b/i.exec(s);
  if (!m) return s.slice(0, 60);
  return m[2] ? `${m[1].toUpperCase()} ${m[2]}` : m[1].toUpperCase();
}

async function borrarTodo(conn, baseDatos) {
  console.log(`${c.yellow}Eliminando objetos existentes...${c.reset}`);
  await conn.query('SET FOREIGN_KEY_CHECKS = 0');

  const [triggers] = await conn.query(
    'SELECT TRIGGER_NAME n FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = ?',
    [baseDatos],
  );
  for (const t of triggers) await conn.query(`DROP TRIGGER IF EXISTS \`${t.n}\``);

  const [rutinas] = await conn.query(
    'SELECT ROUTINE_NAME n, ROUTINE_TYPE t FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = ?',
    [baseDatos],
  );
  for (const r of rutinas) await conn.query(`DROP ${r.t} IF EXISTS \`${r.n}\``);

  const [vistas] = await conn.query(
    "SELECT TABLE_NAME n FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'VIEW'",
    [baseDatos],
  );
  for (const v of vistas) await conn.query(`DROP VIEW IF EXISTS \`${v.n}\``);

  const [tablas] = await conn.query(
    "SELECT TABLE_NAME n FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE'",
    [baseDatos],
  );
  for (const t of tablas) await conn.query(`DROP TABLE IF EXISTS \`${t.n}\``);

  await conn.query('SET FOREIGN_KEY_CHECKS = 1');
  console.log(
    `${c.dim}  ${tablas.length} tablas, ${vistas.length} vistas, ${rutinas.length} rutinas, ${triggers.length} triggers${c.reset}`,
  );
}

async function main() {
  const cfg = {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    multipleStatements: false,
    connectTimeout: 20_000,
    timezone: 'Z',
  };

  for (const [k, v] of Object.entries({
    DB_HOST: cfg.host,
    DB_USER: cfg.user,
    DB_NAME: cfg.database,
  })) {
    if (!v) {
      console.error(`${c.red}Falta ${k} en backend/.env${c.reset}`);
      process.exit(1);
    }
  }

  const archivos = [join(DIR_DB, 'schema.sql')];
  const dirMigraciones = join(DIR_DB, 'migrations');
  if (existsSync(dirMigraciones)) {
    for (const f of readdirSync(dirMigraciones).filter((f) => f.endsWith('.sql')).sort()) {
      archivos.push(join(dirMigraciones, f));
    }
  }

  if (DRY) {
    for (const archivo of archivos) {
      const sentencias = partirSql(readFileSync(archivo, 'utf8'));
      console.log(`\n${c.cyan}${archivo}${c.reset} — ${sentencias.length} sentencias`);
      sentencias.forEach((s, i) => console.log(`  ${String(i + 1).padStart(3)}. ${etiqueta(s)}`));
    }
    return;
  }

  console.log(`${c.cyan}Conectando a ${cfg.host}/${cfg.database}...${c.reset}`);
  const conn = await mysql.createConnection(cfg);

  const [[info]] = await conn.query('SELECT VERSION() v');
  console.log(`${c.dim}  Motor: ${info.v}${c.reset}`);
  if (!/mariadb/i.test(info.v)) {
    console.log(
      `${c.yellow}  Aviso: el esquema está escrito para MariaDB; detecté "${info.v}".${c.reset}`,
    );
  }

  if (DROP) {
    if (!FORZAR) {
      const [[cnt]] = await conn.query(
        "SELECT COUNT(*) n FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE='BASE TABLE'",
        [cfg.database],
      );
      if (cnt.n > 0) {
        const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
        const r = await rl.question(
          `${c.red}--drop BORRARÁ ${cnt.n} tablas de "${cfg.database}" y todos sus datos.\nEscribe el nombre de la base para confirmar: ${c.reset}`,
        );
        rl.close();
        if (r.trim() !== cfg.database) {
          console.log('Cancelado.');
          await conn.end();
          process.exit(1);
        }
      }
    }
    await borrarTodo(conn, cfg.database);
  }

  let total = 0;
  for (const archivo of archivos) {
    const sentencias = partirSql(readFileSync(archivo, 'utf8'));
    console.log(`\n${c.cyan}${archivo.replace(RAIZ, '.')}${c.reset} (${sentencias.length})`);

    for (let i = 0; i < sentencias.length; i += 1) {
      const sentencia = sentencias[i];
      try {
        await conn.query(sentencia);
        console.log(`  ${c.green}✓${c.reset} ${etiqueta(sentencia)}`);
        total += 1;
      } catch (err) {
        console.error(`\n  ${c.red}✗ Sentencia ${i + 1}: ${etiqueta(sentencia)}${c.reset}`);
        console.error(`  ${c.red}${err.code || ''} ${err.message}${c.reset}\n`);
        console.error(`${c.dim}${sentencia.slice(0, 900)}${c.reset}\n`);
        await conn.end();
        process.exit(1);
      }
    }
  }

  const [tablas] = await conn.query(
    "SELECT TABLE_NAME n, TABLE_ROWS r FROM information_schema.TABLES WHERE TABLE_SCHEMA=? AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME",
    [cfg.database],
  );
  console.log(`\n${c.green}Listo: ${total} sentencias aplicadas.${c.reset}`);
  console.log(`${c.dim}Tablas: ${tablas.map((t) => t.n).join(', ')}${c.reset}`);

  await conn.end();
}

main().catch((err) => {
  console.error(`${c.red}Fallo la migración:${c.reset}`, err);
  process.exit(1);
});
