import { Router } from 'express';
import * as servicio from './service.js';
import * as esquemas from './schemas.js';
import { withTransaction } from '../../db/tx.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin, ocultarCostos } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, creado, paginado } from '../../utils/responder.js';

const router = Router();
router.use(autenticar);

const contexto = (req) => ({
  usuarioId: req.usuario.id,
  usuarioUuid: req.usuario.uuid,
  dispositivoUuid: req.dispositivoUuid,
  rol: req.usuario.rol,
});

router.get(
  '/',
  validar({ query: esquemas.filtrosVentaSchema }),
  asyncHandler(async (req, res) => {
    const f = req.validated.query;
    const { items, total } = await servicio.listarVentas(f);
    paginado(res, ocultarCostos(items, req.usuario.rol), { total, pagina: f.pagina, limite: f.limite });
  }),
);

router.get(
  '/:uuid',
  validar({ params: esquemas.paramUuid }),
  asyncHandler(async (req, res) => {
    ok(res, ocultarCostos(await servicio.obtenerVenta(req.params.uuid), req.usuario.rol));
  }),
);

/**
 * POST /ventas — creación en línea.
 * La app móvil normalmente NO usa esta ruta: crea la venta en su SQLite y la
 * envía por /sync/push, que aplica idempotencia por client_op_id. Esta ruta
 * existe para el panel web y para pruebas.
 */
router.post(
  '/',
  validar({ body: esquemas.crearVentaSchema }),
  asyncHandler(async (req, res) => {
    const venta = await withTransaction((c) => servicio.crearVenta(c, req.body, contexto(req)));
    creado(res, ocultarCostos(venta, req.usuario.rol));
  }),
);

/** Anular emite un documento de reversa; la venta original nunca se borra. */
router.post(
  '/:uuid/anular',
  soloAdmin,
  validar({ params: esquemas.paramUuid, body: esquemas.anularVentaSchema }),
  asyncHandler(async (req, res) => {
    ok(
      res,
      await withTransaction((c) =>
        servicio.anularVenta(c, { ...req.body, venta_uuid: req.params.uuid }, contexto(req)),
      ),
    );
  }),
);

export default router;
