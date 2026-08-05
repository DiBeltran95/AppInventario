import { Router } from 'express';
import * as servicio from './service.js';
import * as esquemas from './schemas.js';
import { validar } from '../../middleware/validate.js';
import { autenticar } from '../../middleware/auth.js';
import { soloAdmin } from '../../middleware/rbac.js';
import { limitadorLogin } from '../../middleware/rateLimit.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { ok, creado } from '../../utils/responder.js';

const router = Router();

/**
 * POST /auth/login
 * Devuelve tokens, perfil, y —si se envía `dispositivo`— el prefijo de folio
 * que ese dispositivo usará para numerar ventas sin conexión.
 */
router.post(
  '/login',
  limitadorLogin,
  validar({ body: esquemas.loginSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.login(req.body, req.headers['user-agent']));
  }),
);

/** POST /auth/refresh — rotación con detección de reutilización. */
router.post(
  '/refresh',
  validar({ body: esquemas.refreshSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.refrescar(req.body, req.headers['user-agent']));
  }),
);

router.post(
  '/logout',
  autenticar,
  validar({ body: esquemas.logoutSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.logout(req.body, req.usuario.id));
  }),
);

/** GET /auth/me — el cliente lo usa para validar la sesión al volver a tener red. */
router.get(
  '/me',
  autenticar,
  asyncHandler(async (req, res) => {
    ok(res, {
      usuario: {
        uuid: req.usuario.uuid,
        nombre: req.usuario.nombre,
        email: req.usuario.email,
        rol: req.usuario.rol,
        activo: !!req.usuario.activo,
      },
      servidor_utc: new Date().toISOString(),
    });
  }),
);

router.post(
  '/password',
  autenticar,
  validar({ body: esquemas.cambiarPasswordSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.cambiarPassword(req.usuario.id, req.body));
  }),
);

// ── Usuarios (ADMIN) ────────────────────────────────────────────────────────

router.get(
  '/usuarios',
  autenticar,
  soloAdmin,
  asyncHandler(async (_req, res) => {
    ok(res, await servicio.listarUsuarios());
  }),
);

router.post(
  '/usuarios',
  autenticar,
  soloAdmin,
  validar({ body: esquemas.crearUsuarioSchema }),
  asyncHandler(async (req, res) => {
    creado(res, await servicio.crearUsuario(req.body));
  }),
);

router.patch(
  '/usuarios/:uuid',
  autenticar,
  soloAdmin,
  validar({ params: esquemas.uuidParamSchema, body: esquemas.actualizarUsuarioSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.actualizarUsuario(req.params.uuid, req.body, req.usuario.id));
  }),
);

router.delete(
  '/usuarios/:uuid',
  autenticar,
  soloAdmin,
  validar({ params: esquemas.uuidParamSchema }),
  asyncHandler(async (req, res) => {
    ok(res, await servicio.eliminarUsuario(req.params.uuid, req.usuario.id));
  }),
);

export default router;
