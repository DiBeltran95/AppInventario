import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { env } from '../config/env.js';

const respuesta = (codigo, mensaje) => (req, res) => {
  res.status(429).json({ error: { codigo, mensaje, permanente: false } });
};

/** Límite general de la API. */
export const limitadorGeneral = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MIN * 60_000,
  limit: env.RATE_LIMIT_MAX,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  handler: respuesta('DEMASIADAS_PETICIONES', 'Demasiadas peticiones; espera un momento'),
});

/**
 * Límite estricto para login. Se agrupa por IP + correo para que un atacante no
 * pueda bloquear a un usuario legítimo simplemente fallando su login desde otra
 * IP, y para que probar 1.000 contraseñas de una cuenta no salga gratis.
 *
 * `ipKeyGenerator` normaliza IPv6 a /64 (una sola máquina puede tener billones
 * de direcciones IPv6; sin normalizar, el límite por IP no sirve de nada).
 */
export const limitadorLogin = rateLimit({
  windowMs: 15 * 60_000,
  limit: env.AUTH_RATE_LIMIT_MAX,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  keyGenerator: (req) => `${ipKeyGenerator(req.ip)}:${String(req.body?.email ?? '').toLowerCase()}`,
  handler: respuesta(
    'DEMASIADOS_INTENTOS',
    'Demasiados intentos fallidos. Espera 15 minutos e inténtalo de nuevo.',
  ),
});

/**
 * La sincronización es legítimamente intensiva: un dispositivo que estuvo una
 * semana sin red envía cientos de operaciones al reconectar. Se le da holgura,
 * pero acotada por dispositivo.
 */
export const limitadorSync = rateLimit({
  windowMs: 60_000,
  limit: 120,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  keyGenerator: (req) =>
    req.headers['x-dispositivo'] || req.usuario?.uuid || ipKeyGenerator(req.ip),
  handler: respuesta('SYNC_LIMITADA', 'Ritmo de sincronización excedido; reintenta en un minuto'),
});
