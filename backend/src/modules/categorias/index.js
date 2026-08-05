import { Router } from 'express';
import { z } from 'zod';
import { crearRepositorioSimple } from '../../db/simpleCrud.js';
import { withTransaction } from '../../db/tx.js';
import { query } from '../../db/pool.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, creado, lista } from '../../utils/responder.js';

export const repoCategorias = crearRepositorioSimple({
  tabla: 'categorias',
  campos: ['nombre', 'descripcion', 'color', 'icono', 'orden'],
  camposBusqueda: ['nombre'],
  orden: 'orden ASC, nombre ASC',
});

const cuerpoCrear = z.object({
  uuid: z.string().uuid().optional(),
  nombre: z.string().min(1).max(100).trim(),
  descripcion: z.string().max(255).nullish(),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, 'Debe ser un color hexadecimal como #6750A4')
    .default('#6750A4'),
  icono: z.string().max(40).nullish(),
  orden: z.coerce.number().int().min(0).default(0),
});

const cuerpoActualizar = cuerpoCrear.partial().omit({ uuid: true });
const paramUuid = z.object({ uuid: z.string().uuid() });

const router = Router();
router.use(autenticar);

router.get(
  '/',
  validar({ query: z.object({ buscar: z.string().max(100).optional() }) }),
  asyncHandler(async (req, res) => {
    const items = await repoCategorias.listar({ buscar: req.validated.query.buscar });
    // Se acompaña de cuántos productos hay en cada categoría: la UI lo muestra
    // en la lista y pedirlo aparte serían N+1 peticiones.
    const conteos = await query(
      `SELECT c.uuid, COUNT(p.id) n
         FROM categorias c
         LEFT JOIN productos p ON p.categoria_id = c.id AND p.deleted_at IS NULL
        WHERE c.deleted_at IS NULL
        GROUP BY c.uuid`,
    );
    const mapa = new Map(conteos.map((c) => [c.uuid, Number(c.n)]));
    lista(
      res,
      items.map((i) => ({ ...i, productos: mapa.get(i.uuid) ?? 0 })),
      { total: items.length },
    );
  }),
);

router.get(
  '/:uuid',
  validar({ params: paramUuid }),
  asyncHandler(async (req, res) => ok(res, await repoCategorias.obtener(req.params.uuid))),
);

router.post(
  '/',
  soloAdmin,
  validar({ body: cuerpoCrear }),
  asyncHandler(async (req, res) =>
    creado(res, await withTransaction((c) => repoCategorias.crear(c, req.body))),
  ),
);

router.patch(
  '/:uuid',
  soloAdmin,
  validar({ params: paramUuid, body: cuerpoActualizar }),
  asyncHandler(async (req, res) =>
    ok(res, await withTransaction((c) => repoCategorias.actualizar(c, req.params.uuid, req.body))),
  ),
);

router.delete(
  '/:uuid',
  soloAdmin,
  validar({ params: paramUuid }),
  asyncHandler(async (req, res) =>
    ok(res, await withTransaction((c) => repoCategorias.eliminar(c, req.params.uuid))),
  ),
);

export default router;
