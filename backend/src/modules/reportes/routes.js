import { Router } from 'express';
import { z } from 'zod';
import * as servicio from './service.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { ocultarCostos, soloAdmin } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, lista } from '../../utils/responder.js';
import { rangoPeriodo } from '../../utils/dates.js';

const router = Router();
router.use(autenticar);

const fecha = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Formato AAAA-MM-DD');

/**
 * Acepta o bien un periodo con nombre (`hoy`, `semana`, `mes`...) o bien un
 * rango explícito. El periodo se resuelve en la zona del negocio.
 */
const rangoSchema = z
  .object({
    periodo: z.enum(['hoy', 'ayer', 'semana', 'mes', 'trimestre', 'anio']).optional(),
    desde: fecha.optional(),
    hasta: fecha.optional(),
  })
  .transform((v) => {
    if (v.desde && v.hasta) return { desde: v.desde, hasta: v.hasta };
    return rangoPeriodo(v.periodo ?? 'mes');
  })
  .refine((v) => v.desde <= v.hasta, { message: '`desde` no puede ser posterior a `hasta`' });

router.get(
  '/dashboard',
  asyncHandler(async (req, res) => {
    ok(res, ocultarCostos(await servicio.dashboard(), req.usuario.rol));
  }),
);

router.get(
  '/ventas',
  validar({
    query: z.object({
      periodo: z.enum(['hoy', 'ayer', 'semana', 'mes', 'trimestre', 'anio']).optional(),
      desde: fecha.optional(),
      hasta: fecha.optional(),
      agrupar: z.enum(['dia', 'semana', 'mes']).default('dia'),
    }),
  }),
  asyncHandler(async (req, res) => {
    const { agrupar, ...resto } = req.validated.query;
    const rango = rangoSchema.parse(resto);
    const items = await servicio.ventasPorPeriodo({ ...rango, agrupar });
    lista(res, ocultarCostos(items, req.usuario.rol), { ...rango, agrupar });
  }),
);

router.get(
  '/top-productos',
  validar({
    query: z.object({
      periodo: z.enum(['hoy', 'ayer', 'semana', 'mes', 'trimestre', 'anio']).optional(),
      desde: fecha.optional(),
      hasta: fecha.optional(),
      limite: z.coerce.number().int().min(1).max(100).default(10),
      por: z.enum(['unidades', 'ingreso', 'margen']).default('unidades'),
    }),
  }),
  asyncHandler(async (req, res) => {
    const { limite, por, ...resto } = req.validated.query;
    const rango = rangoSchema.parse(resto);
    const items = await servicio.topProductos({ ...rango, limite, por });
    lista(res, ocultarCostos(items, req.usuario.rol), { ...rango, por });
  }),
);

/**
 * GET /reportes/por-empleado — control de cajas. **Sólo ADMIN.**
 *
 * Un vendedor no debe poder comparar su rendimiento con el de sus compañeros ni
 * ver los márgenes del negocio, así que la ruta entera queda cerrada en lugar de
 * filtrar columnas.
 */
router.get(
  '/por-empleado',
  soloAdmin,
  validar({
    query: z.object({
      periodo: z.enum(['hoy', 'ayer', 'semana', 'mes', 'trimestre', 'anio']).optional(),
      desde: fecha.optional(),
      hasta: fecha.optional(),
    }),
  }),
  asyncHandler(async (req, res) => {
    const rango = rangoSchema.parse(req.validated.query);
    lista(res, await servicio.ventasPorEmpleado(rango), rango);
  }),
);

router.get(
  '/stock-bajo',
  validar({ query: z.object({ limite: z.coerce.number().int().min(1).max(500).default(50) }) }),
  asyncHandler(async (req, res) => {
    const items = await servicio.stockBajo(req.validated.query);
    lista(res, ocultarCostos(items, req.usuario.rol), { total: items.length });
  }),
);

router.get(
  '/valorizacion',
  asyncHandler(async (req, res) => {
    ok(res, ocultarCostos(await servicio.valorizacion(), req.usuario.rol));
  }),
);

router.get(
  '/movimientos',
  validar({
    query: z.object({
      periodo: z.enum(['hoy', 'ayer', 'semana', 'mes', 'trimestre', 'anio']).optional(),
      desde: fecha.optional(),
      hasta: fecha.optional(),
    }),
  }),
  asyncHandler(async (req, res) => {
    const rango = rangoSchema.parse(req.validated.query);
    const items = await servicio.movimientosResumen(rango);
    lista(res, ocultarCostos(items, req.usuario.rol), rango);
  }),
);

export default router;
