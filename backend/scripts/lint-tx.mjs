#!/usr/bin/env node
/**
 * Chequeo estático de un error fácil de cometer y difícil de ver:
 * llamar a `txQuery` / `txQueryOne` / `txExecute` SIN pasar la conexión.
 *
 *     await txExecute('UPDATE ...', [id])          // ← se ejecuta fuera de la
 *     await txExecute(conn, 'UPDATE ...', [id])    //   transacción, o revienta
 *
 * La primera forma parece correcta al leerla y rompe la atomicidad en silencio.
 * Ningún linter genérico lo detecta porque es una firma válida de JavaScript.
 *
 * Uso: node scripts/lint-tx.mjs
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, dirname, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SRC = join(RAIZ, 'src');
const HELPERS = ['txQuery', 'txQueryOne', 'txExecute'];

function archivosJs(dir) {
  const salida = [];
  for (const entrada of readdirSync(dir)) {
    const ruta = join(dir, entrada);
    if (statSync(ruta).isDirectory()) salida.push(...archivosJs(ruta));
    else if (entrada.endsWith('.js')) salida.push(ruta);
  }
  return salida;
}

const problemas = [];

for (const archivo of archivosJs(SRC)) {
  const contenido = readFileSync(archivo, 'utf8');
  const lineas = contenido.split(/\r?\n/);

  for (const helper of HELPERS) {
    // Se busca la llamada y se inspecciona su primer argumento, que puede estar
    // en la misma línea o en la siguiente.
    const re = new RegExp(`\\b${helper}\\s*\\(`, 'g');
    let m;
    while ((m = re.exec(contenido)) !== null) {
      // Ignora la definición de la propia función.
      const antes = contenido.slice(Math.max(0, m.index - 30), m.index);
      if (/function\s+$|export\s+async\s+$|async\s+$/.test(antes)) continue;

      const resto = contenido.slice(m.index + m[0].length, m.index + m[0].length + 120);
      const primerArg = resto.replace(/^\s+/, '').slice(0, 12);
      const ok = /^(conn|connection|cx|c)\b/.test(primerArg);

      if (!ok) {
        const numero = contenido.slice(0, m.index).split('\n').length;
        problemas.push({
          archivo: relative(RAIZ, archivo).replace(/\\/g, '/'),
          linea: numero,
          helper,
          fragmento: (lineas[numero - 1] ?? '').trim().slice(0, 100),
        });
      }
    }
  }
}

if (problemas.length === 0) {
  console.log('\x1b[32m✓ Todas las llamadas a helpers transaccionales reciben la conexión\x1b[0m');
  process.exit(0);
}

console.log(`\x1b[31m✗ ${problemas.length} llamada(s) sin conexión:\x1b[0m\n`);
for (const p of problemas) {
  console.log(`  ${p.archivo}:${p.linea}  ${p.helper}`);
  console.log(`    \x1b[2m${p.fragmento}\x1b[0m`);
}
console.log('\n  El primer argumento debe ser la conexión de la transacción (`conn`).\n');
process.exit(1);
