import { Router } from 'express';
import { z } from 'zod';
import * as servicio from './service.js';
import { ENTIDADES } from './pullQueries.js';
import { OPERACIONES_PUSH } from '../../config/constants.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin } from '../../middleware/rbac.js';
import { limitadorSync } from '../../middleware/rateLimit.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok } from '../../utils/responder.js';
import { env } from '../../config/env.js';

const router = Router();
router.use(autenticar, limitadorSync);

const contexto = (req) => ({
  usuarioId: req.usuario.id,
  usuarioUuid: req.usuario.uuid,
  dispositivoUuid: req.dispositivoUuid,
  rol: req.usuario.rol,
});

const pushSchema = z.object({
  operaciones: z
    .array(
      z.object({
        client_op_id: z.string().uuid(),
        tipo: z.enum([...OPERACIONES_PUSH, 'CONTEO_AJUSTAR']),
        payload: z.record(z.any()),
        creado_en: z.string().datetime({ offset: true }).optional(),
      }),
    )
    .min(1)
    .max(env.SYNC_PUSH_MAX_OPS),
});

/**
 * Cursor por entidad: { productos: {t: ISO, i: id}, ... }
 * `t` es `updated_at` de la última fila recibida e `i` su id interno.
 */
const cursorSchema = z.object({
  t: z.string().datetime({ offset: true }),
  i: z.number().int().min(0),
});

const pullSchema = z.object({
  cursores: z.record(z.enum(ENTIDADES), cursorSchema).default({}),
  limite: z.coerce.number().int().min(1).max(env.SYNC_PULL_MAX_ROWS).optional(),
  dias_historial: z.coerce.number().int().min(1).max(3650).default(90),
  entidades: z.array(z.enum(ENTIDADES)).optional(),
});

/**
 * POST /sync/push — subida de la cola local.
 *
 * Devuelve SIEMPRE 200 aunque alguna operación falle: el resultado por
 * operación va en el cuerpo. Un 4xx global obligaría al cliente a adivinar
 * cuáles se aplicaron y cuáles no; con esto sabe exactamente qué borrar de su
 * outbox y qué reintentar.
 */
router.post(
  '/push',
  validar({ body: pushSchema }),
  asyncHandler(async (req, res) => {
    const resultados = await servicio.procesarPush(req.body.operaciones, contexto(req));
    ok(res, {
      resultados,
      aplicadas: resultados.filter((r) => r.estado === 'OK').length,
      rechazadas: resultados.filter((r) => r.estado === 'ERROR').length,
      servidor_utc: new Date().toISOString(),
    });
  }),
);

/**
 * POST /sync/pull — bajada delta.
 *
 * Es POST y no GET porque el cursor es un objeto por entidad: meterlo en la
 * query string obligaría a codificarlo en base64 y a lidiar con el límite de
 * longitud de URL. La operación no muta nada.
 */
router.post(
  '/pull',
  validar({ body: pullSchema }),
  asyncHandler(async (req, res) => {
    const { cursores, limite, dias_historial: dias, entidades } = req.body;
    ok(
      res,
      await servicio.pull(cursores, { limite, diasHistorial: dias, entidades }, contexto(req)),
    );
  }),
);

router.get(
  '/estado',
  asyncHandler(async (req, res) => ok(res, await servicio.estado(contexto(req)))),
);

/** Mantenimiento: purga registros de idempotencia y tokens caducados. */
router.post(
  '/mantenimiento',
  soloAdmin,
  validar({ body: z.object({ dias: z.coerce.number().int().min(7).max(365).default(30) }).default({}) }),
  asyncHandler(async (req, res) => {
    const [operaciones, tokens] = await Promise.all([
      servicio.purgarOperaciones(req.body?.dias ?? 30),
      servicio.purgarTokens(),
    ]);
    ok(res, { operaciones, tokens });
  }),
);

export default router;
