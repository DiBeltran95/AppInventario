import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { queryOne } from '../db/pool.js';
import { unauthorized, forbidden } from '../utils/ApiError.js';
import { asyncHandler } from '../utils/asyncHandler.js';

/**
 * Verifica el access token y adjunta `req.usuario`.
 *
 * Se consulta el usuario en cada petición en lugar de confiar sólo en el
 * payload del JWT: un usuario desactivado o eliminado debe perder el acceso de
 * inmediato, no cuando caduque su token 15 minutos después.
 */
export const autenticar = asyncHandler(async (req, _res, next) => {
  const cabecera = req.headers.authorization || '';
  const [esquema, token] = cabecera.split(' ');

  if (esquema !== 'Bearer' || !token) {
    throw unauthorized('Falta el encabezado Authorization: Bearer <token>');
  }

  let payload;
  try {
    payload = jwt.verify(token, env.JWT_ACCESS_SECRET, { algorithms: ['HS256'] });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      throw unauthorized('El token expiró', 'TOKEN_EXPIRADO');
    }
    throw unauthorized('Token inválido', 'TOKEN_INVALIDO');
  }

  const usuario = await queryOne(
    'SELECT id, uuid, nombre, email, rol, activo FROM usuarios WHERE uuid = ? AND deleted_at IS NULL',
    [payload.sub],
  );

  if (!usuario) throw unauthorized('El usuario ya no existe', 'USUARIO_INEXISTENTE');
  if (!usuario.activo) throw forbidden('La cuenta está desactivada', 'CUENTA_DESACTIVADA');

  req.usuario = usuario;
  req.dispositivoUuid = req.headers['x-dispositivo'] || payload.dispositivo || null;
  next();
});

/** Igual que `autenticar`, pero no falla si no hay token (rutas mixtas). */
export const autenticarOpcional = asyncHandler(async (req, _res, next) => {
  if (!req.headers.authorization) return next();
  return autenticar(req, _res, next);
});
