import { Router } from 'express';
import { z } from 'zod';
import { crearRepositorioSimple } from '../../db/simpleCrud.js';
import { withTransaction } from '../../db/tx.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, creado, lista } from '../../utils/responder.js';

export const repoProveedores = crearRepositorioSimple({
  tabla: 'proveedores',
  campos: ['nombre', 'nit', 'contacto', 'telefono', 'email', 'direccion', 'notas'],
  camposBusqueda: ['nombre', 'nit', 'contacto'],
  orden: 'nombre ASC',
});

const cuerpoCrear = z.object({
  uuid: z.string().uuid().optional(),
  nombre: z.string().min(1).max(150).trim(),
  nit: z.string().max(30).nullish(),
  contacto: z.string().max(120).nullish(),
  telefono: z.string().max(30).nullish(),
  email: z.string().email().max(191).nullish().or(z.literal('')),
  direccion: z.string().max(255).nullish(),
  notas: z.string().max(2000).nullish(),
});

const cuerpoActualizar = cuerpoCrear.partial().omit({ uuid: true });
const paramUuid = z.object({ uuid: z.string().uuid() });

const router = Router();
router.use(autenticar);

router.get(
  '/',
  validar({ query: z.object({ buscar: z.string().max(100).optional() }) }),
  asyncHandler(async (req, res) => {
    const items = await repoProveedores.listar({ buscar: req.validated.query.buscar });
    lista(res, items, { total: items.length });
  }),
);

router.get(
  '/:uuid',
  validar({ params: paramUuid }),
  asyncHandler(async (req, res) => ok(res, await repoProveedores.obtener(req.params.uuid))),
);

router.post(
  '/',
  soloAdmin,
  validar({ body: cuerpoCrear }),
  asyncHandler(async (req, res) =>
    creado(res, await withTransaction((c) => repoProveedores.crear(c, req.body))),
  ),
);

router.patch(
  '/:uuid',
  soloAdmin,
  validar({ params: paramUuid, body: cuerpoActualizar }),
  asyncHandler(async (req, res) =>
    ok(res, await withTransaction((c) => repoProveedores.actualizar(c, req.params.uuid, req.body))),
  ),
);

router.delete(
  '/:uuid',
  soloAdmin,
  validar({ params: paramUuid }),
  asyncHandler(async (req, res) =>
    ok(res, await withTransaction((c) => repoProveedores.eliminar(c, req.params.uuid))),
  ),
);

export default router;
