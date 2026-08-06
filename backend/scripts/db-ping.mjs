#!/usr/bin/env node
/**
 * Diagnóstico de la conexión a MariaDB.
 *
 *   npm run db:ping
 *
 * Existe para responder una pregunta concreta: **¿qué credenciales está
 * recibiendo de verdad el proceso?** Cuando el `.env` local funciona y el
 * servidor no, casi siempre es que el panel del alojamiento entrega un valor
 * distinto del que se ve en pantalla (comillas, un espacio al final, un salto
 * de línea pegado al copiar).
 *
 * Nunca imprime la contraseña. Muestra su longitud y una huella de 8 caracteres
 * del SHA-256: suficiente para comparar dos entornos sin revelar el secreto.
 */
import 'dotenv/config';
import mysql from 'mysql2/promise';
import { createHash } from 'node:crypto';

const c = {
  reset: '\x1b[0m', dim: '\x1b[2m', red: '\x1b[31m',
  green: '\x1b[32m', yellow: '\x1b[33m', cyan: '\x1b[36m',
};

const bruto = {
  DB_HOST: process.env.DB_HOST,
  DB_PORT: process.env.DB_PORT,
  DB_USER: process.env.DB_USER,
  DB_PASSWORD: process.env.DB_PASSWORD,
  DB_NAME: process.env.DB_NAME,
};

console.log(`\n${c.cyan}Variables tal como las recibe el proceso${c.reset}`);

let sospecha = false;

for (const [clave, valor] of Object.entries(bruto)) {
  if (valor === undefined) {
    console.log(`  ${c.red}✗${c.reset} ${clave.padEnd(12)} ausente`);
    sospecha = true;
    continue;
  }

  const problemas = [];
  if (/^['"]/.test(valor) && valor[0] === valor[valor.length - 1]) {
    problemas.push('envuelta en comillas');
  }
  if (valor !== valor.trim()) problemas.push('espacios o saltos al principio o al final');
  if (/[\r\n]/.test(valor)) problemas.push('contiene un salto de línea');

  const detalle =
    clave === 'DB_PASSWORD'
      ? `${valor.length} caracteres · huella ${createHash('sha256').update(valor).digest('hex').slice(0, 8)}`
      : valor;

  if (problemas.length) {
    sospecha = true;
    console.log(`  ${c.yellow}!${c.reset} ${clave.padEnd(12)} ${detalle}`);
    console.log(`    ${c.yellow}→ ${problemas.join('; ')}${c.reset}`);
  } else {
    console.log(`  ${c.green}✓${c.reset} ${clave.padEnd(12)} ${c.dim}${detalle}${c.reset}`);
  }
}

if (sospecha) {
  console.log(
    `\n${c.yellow}Hay valores con formato sospechoso.${c.reset} En un archivo .env las comillas ` +
      'las quita dotenv,\npero el panel de variables de un alojamiento guarda el valor LITERAL: ' +
      "escribir\n'micontraseña' allí produce una contraseña con las comillas incluidas.",
  );
}

// Se conecta con los valores ya saneados, igual que hace la app.
const { env } = await import('../src/config/env.js');

console.log(`\n${c.cyan}Conectando a ${env.DB_HOST}:${env.DB_PORT}/${env.DB_NAME}${c.reset}`);

let conexion;
try {
  conexion = await mysql.createConnection({
    host: env.DB_HOST,
    port: env.DB_PORT,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    database: env.DB_NAME,
    connectTimeout: 10_000,
    ...(env.DB_SSL ? { ssl: { rejectUnauthorized: true } } : {}),
  });

  const [[fila]] = await conexion.query(
    'SELECT VERSION() AS version, CURRENT_USER() AS usuario, DATABASE() AS base, @@sql_mode AS modo',
  );

  console.log(`  ${c.green}✓ Conectado${c.reset}`);
  console.log(`    Motor:   ${fila.version}`);
  console.log(`    Usuario: ${fila.usuario}`);
  console.log(`    Base:    ${fila.base}`);

  const [tablas] = await conexion.query(
    'SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema = ?',
    [env.DB_NAME],
  );
  const n = tablas[0].n;
  if (n === 0) {
    console.log(
      `\n  ${c.yellow}La base está vacía.${c.reset} Falta crear el esquema:\n` +
        '    npm run db:migrate\n    npm run db:seed -- --password "TuClave"',
    );
  } else {
    console.log(`    Tablas:  ${n}`);
  }

  console.log(`\n${c.green}La base de datos responde. El backend puede arrancar.${c.reset}\n`);
} catch (err) {
  console.log(`  ${c.red}✗ ${err.code ?? 'ERROR'}${c.reset}: ${err.message}\n`);

  const ayuda = {
    ER_ACCESS_DENIED_ERROR: [
      'MariaDB rechazó usuario o contraseña.',
      '',
      'Comprueba la credencial a mano (te pedirá la contraseña al teclearla):',
      `  mysql -h ${env.DB_HOST} -u ${env.DB_USER} -p ${env.DB_NAME} -e "SELECT 1"`,
      '',
      'Si a mano funciona y aquí no, el valor de DB_PASSWORD del entorno no es el',
      'que crees: mira arriba la longitud y busca comillas o espacios sobrantes.',
    ],
    ER_BAD_DB_ERROR: [
      `El usuario es válido pero la base "${env.DB_NAME}" no existe.`,
      'Créala en el panel de tu alojamiento o corrige DB_NAME.',
    ],
    ENOTFOUND: [`El host "${env.DB_HOST}" no resuelve. Revisa DB_HOST.`],
    ETIMEDOUT: [
      `Sin respuesta de ${env.DB_HOST}:${env.DB_PORT}.`,
      'Puede ser un cortafuegos, o que la base sólo acepte conexiones internas.',
    ],
  }[err.code];

  if (ayuda) console.log(ayuda.map((l) => `  ${l}`).join('\n') + '\n');
  process.exitCode = 1;
} finally {
  await conexion?.end();
}
