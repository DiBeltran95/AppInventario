import { Router } from 'express';
import { z } from 'zod';
import * as servicio from './service.js';
import { withTransaction } from '../../db/tx.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin, ocultarCostos } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, creado, paginado, lista } from '../../utils/responder.js';
import { dinero, cantidad } from '../productos/schemas.js';

const router = Router();
router.use(autenticar);

const contexto = (req) => ({
  usuarioId: req.usuario.id,
  usuarioUuid: req.usuario.uuid,
  dispositivoUuid: req.dispositivoUuid,
  rol: req.usuario.rol,
});

/** Sólo tipos manuales: VENTA y ANULACION_VENTA los genera el módulo de ventas. */
export const movimientoSchema = z.object({
  uuid: z.string().uuid().optional(),
  producto_uuid: z.string().uuid(),
  tipo: z.enum(['ENTRADA', 'SALIDA', 'DEVOLUCION', 'MERMA', 'AJUSTE', 'TRASLADO', 'INICIAL']),
  cantidad,
  costo_unitario: dinero.nullish(),
  precio_unitario: dinero.nullish(),
  proveedor_uuid: z.string().uuid().nullish(),
  lote: z.string().max(60).nullish(),
  vence_el: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato AAAA-MM-DD')
    .nullish(),
  documento_ref: z.string().max(60).nullish(),
  motivo: z.string().max(255).nullish(),
  fecha: z.string().datetime({ offset: true }).optional(),
  fecha_local: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  creado_offline: z.boolean().default(false),
});

export const conteoSchema = z.object({
  uuid: z.string().uuid().optional(),
  producto_uuid: z.string().uuid(),
  stock_contado: cantidad,
  motivo: z.string().max(255).nullish(),
  fecha: z.string().datetime({ offset: true }).optional(),
  creado_offline: z.boolean().default(false),
});

const filtrosSchema = z.object({
  producto: z.string().uuid().optional(),
  tipo: z
    .enum(['INICIAL', 'ENTRADA', 'SALIDA', 'VENTA', 'ANULACION_VENTA', 'DEVOLUCION', 'AJUSTE', 'MERMA', 'TRASLADO'])
    .optional(),
  proveedor: z.string().uuid().optional(),
  desde: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  hasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  pagina: z.coerce.number().int().min(1).default(1),
  limite: z.coerce.number().int().min(1).max(200).default(50),
});

router.get(
  '/movimientos',
  validar({ query: filtrosSchema }),
  asyncHandler(async (req, res) => {
    const f = req.validated.query;
    const { items, total } = await servicio.listarMovimientos(f);
    paginado(res, ocultarCostos(items, req.usuario.rol), { total, pagina: f.pagina, limite: f.limite });
  }),
);

/**
 * Entrada de mercancía y demás movimientos manuales. **Sólo ADMIN.**
 *
 * Un vendedor no puede tocar el inventario. No es una restricción de comodidad:
 * cargar existencias o registrar una MERMA es exactamente lo que se hace para
 * cuadrar un stock del que falta mercancía, así que dárselo a quien despacha
 * anula el control de inventario.
 */
router.post(
  '/movimientos',
  soloAdmin,
  validar({ body: movimientoSchema }),
  asyncHandler(async (req, res) => {
    creado(res, await withTransaction((c) => servicio.crearMovimiento(c, req.body, contexto(req))));
  }),
);

/**
 * Ajuste por conteo físico: se envía lo contado, no la diferencia. **Sólo ADMIN.**
 *
 * Es la operación más sensible del sistema: reescribe el stock a lo que diga el
 * usuario, sin dejar rastro de qué se perdió.
 */
router.post(
  '/conteo',
  soloAdmin,
  validar({ body: conteoSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await withTransaction((c) => servicio.ajustarPorConteo(c, req.body, contexto(req))));
  }),
);

router.get(
  '/alertas',
  validar({
    query: z.object({
      resueltas: z.enum(['true', 'false']).default('false').transform((v) => v === 'true'),
      limite: z.coerce.number().int().min(1).max(500).default(100),
    }),
  }),
  asyncHandler(async (req, res) => {
    const items = await servicio.listarAlertas(req.validated.query);
    lista(res, items, { total: items.length });
  }),
);

router.post(
  '/alertas/:uuid/resolver',
  validar({ params: z.object({ uuid: z.string().uuid() }) }),
  asyncHandler(async (req, res) => {
    ok(res, await withTransaction((c) => servicio.resolverAlerta(c, req.params.uuid, req.usuario.id)));
  }),
);

/**
 * Recalcula stock_actual desde el libro de movimientos.
 * Operación de mantenimiento; sólo ADMIN.
 */
router.post(
  '/recalcular',
  soloAdmin,
  validar({ body: z.object({ producto_uuid: z.string().uuid().nullish() }).default({}) }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.recalcularStock(req.body?.producto_uuid ?? null));
  }),
);

export default router;
