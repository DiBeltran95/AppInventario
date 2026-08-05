import { Router } from 'express';
import { z } from 'zod';
import * as servicio from './service.js';
import * as esquemas from './schemas.js';
import { withTransaction } from '../../db/tx.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin, ocultarCostos } from '../../middleware/rbac.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, creado, paginado } from '../../utils/responder.js';
import { notFound } from '../../utils/ApiError.js';
import { QR_PREFIX } from '../../config/constants.js';

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
  validar({ query: esquemas.filtrosProductoSchema }),
  asyncHandler(async (req, res) => {
    const f = req.validated.query;
    const { items, total } = await servicio.listarProductos(f);
    paginado(res, ocultarCostos(items, req.usuario.rol), {
      total,
      pagina: f.pagina,
      limite: f.limite,
    });
  }),
);

/**
 * GET /productos/codigo/:codigo — resolución de un escaneo.
 *
 * Va ANTES de /:uuid para que un código que casualmente tenga forma de UUID no
 * caiga en la ruta equivocada.
 *
 * Este endpoint existe sobre todo para el panel web y para la primera carga: la
 * app móvil resuelve los escaneos contra su SQLite local, sin red.
 */
router.get(
  '/codigo/:codigo',
  validar({ params: esquemas.paramCodigo }),
  asyncHandler(async (req, res) => {
    const producto = await servicio.buscarPorCodigo(req.params.codigo);
    if (!producto) {
      throw notFound(`Producto para el código "${req.params.codigo}"`);
    }
    ok(res, ocultarCostos(producto, req.usuario.rol));
  }),
);

router.get(
  '/:uuid',
  validar({ params: esquemas.paramUuid }),
  asyncHandler(async (req, res) => {
    const producto = await servicio.obtenerProducto(req.params.uuid);
    ok(res, {
      ...ocultarCostos(producto, req.usuario.rol),
      // Contenido exacto que debe codificar el QR de este producto.
      qr_payload: `${QR_PREFIX}${producto.uuid}`,
    });
  }),
);

router.post(
  '/',
  soloAdmin,
  validar({ body: esquemas.crearProductoSchema }),
  asyncHandler(async (req, res) => {
    const producto = await withTransaction((c) => servicio.crearProducto(c, req.body, contexto(req)));
    creado(res, producto);
  }),
);

router.patch(
  '/:uuid',
  soloAdmin,
  validar({ params: esquemas.paramUuid, body: esquemas.actualizarProductoSchema }),
  asyncHandler(async (req, res) => {
    ok(
      res,
      await withTransaction((c) =>
        servicio.actualizarProducto(c, req.params.uuid, req.body, contexto(req)),
      ),
    );
  }),
);

router.delete(
  '/:uuid',
  soloAdmin,
  validar({ params: esquemas.paramUuid }),
  asyncHandler(async (req, res) => {
    ok(res, await withTransaction((c) => servicio.eliminarProducto(c, req.params.uuid, contexto(req))));
  }),
);

router.post(
  '/:uuid/codigos',
  soloAdmin,
  validar({ params: esquemas.paramUuid, body: esquemas.codigoSchema }),
  asyncHandler(async (req, res) => {
    creado(
      res,
      await withTransaction((c) => servicio.agregarCodigo(c, req.params.uuid, req.body, contexto(req))),
    );
  }),
);

router.delete(
  '/codigos/:uuid',
  soloAdmin,
  validar({ params: z.object({ uuid: z.string().uuid() }) }),
  asyncHandler(async (req, res) => {
    ok(res, await withTransaction((c) => servicio.eliminarCodigo(c, req.params.uuid, contexto(req))));
  }),
);

export default router;
