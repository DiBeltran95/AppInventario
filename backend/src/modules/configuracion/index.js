import { Router } from 'express';
import { z } from 'zod';
import { query } from '../../db/pool.js';
import { withTransaction, txExecute } from '../../db/tx.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/responder.js';
import { CONFIG_DEFAULTS } from '../../config/constants.js';
import { env } from '../../config/env.js';

const router = Router();
router.use(autenticar);

/** Convierte los valores de texto a su tipo declarado. */
function tipar(filas) {
  const salida = {};
  for (const f of filas) {
    switch (f.tipo) {
      case 'INT':
        salida[f.clave] = Number.parseInt(f.valor, 10);
        break;
      case 'BOOL':
        salida[f.clave] = f.valor === 'true' || f.valor === '1';
        break;
      case 'JSON':
        try {
          salida[f.clave] = JSON.parse(f.valor);
        } catch {
          salida[f.clave] = null;
        }
        break;
      default:
        // DECIMAL se deja como string a propósito: es dinero o una tasa.
        salida[f.clave] = f.valor;
    }
  }
  return salida;
}

router.get(
  '/',
  asyncHandler(async (_req, res) => {
    const filas = await query('SELECT clave, valor, tipo, descripcion FROM configuracion');
    ok(res, {
      valores: { ...CONFIG_DEFAULTS, ...tipar(filas) },
      // La app necesita estos tres para operar sin conexión de forma coherente
      // con el servidor.
      servidor: {
        zona_negocio: env.BUSINESS_TIMEZONE,
        moneda: env.CURRENCY,
        permitir_stock_negativo: env.ALLOW_NEGATIVE_STOCK,
        offline_grace_days: env.OFFLINE_GRACE_DAYS,
        iva_por_defecto: env.DEFAULT_TAX_RATE.toFixed(2),
      },
      servidor_utc: new Date().toISOString(),
    });
  }),
);

router.put(
  '/',
  soloAdmin,
  validar({
    body: z.object({
      valores: z.record(z.string().max(64), z.union([z.string().max(5000), z.number(), z.boolean()])),
    }),
  }),
  asyncHandler(async (req, res) => {
    const entradas = Object.entries(req.body.valores);
    await withTransaction(async (conn) => {
      for (const [clave, valor] of entradas) {
        const tipo =
          typeof valor === 'boolean' ? 'BOOL' : typeof valor === 'number' ? 'INT' : 'STRING';
        await txExecute(
          conn,
          `INSERT INTO configuracion (clave, valor, tipo) VALUES (?,?,?)
           ON DUPLICATE KEY UPDATE valor = VALUES(valor), tipo = VALUES(tipo)`,
          [clave, String(valor), tipo],
        );
      }
    });
    const filas = await query('SELECT clave, valor, tipo FROM configuracion');
    ok(res, { valores: tipar(filas), actualizadas: entradas.length });
  }),
);

export default router;
