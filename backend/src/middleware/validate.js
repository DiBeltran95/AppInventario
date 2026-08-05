import { badRequest } from '../utils/ApiError.js';

/**
 * Valida `body`, `query` y/o `params` con esquemas Zod y REEMPLAZA el valor por
 * el resultado parseado (con coerciones y valores por defecto aplicados).
 *
 * En Express 5 `req.query` es un getter sin setter, así que el resultado se
 * deja en `req.validated.query` y también se intenta redefinir la propiedad.
 */
export const validar = (esquemas) => (req, _res, next) => {
  const errores = [];
  req.validated = req.validated || {};

  for (const clave of ['body', 'params', 'query']) {
    const esquema = esquemas[clave];
    if (!esquema) continue;

    const resultado = esquema.safeParse(req[clave]);
    if (!resultado.success) {
      for (const issue of resultado.error.issues) {
        errores.push({
          campo: [clave, ...issue.path].join('.'),
          mensaje: issue.message,
          codigo: issue.code,
        });
      }
      continue;
    }

    req.validated[clave] = resultado.data;
    if (clave === 'body') {
      req.body = resultado.data;
    } else {
      try {
        Object.defineProperty(req, clave, {
          value: resultado.data,
          writable: true,
          configurable: true,
        });
      } catch {
        /* si no se puede redefinir, queda en req.validated */
      }
    }
  }

  if (errores.length) {
    return next(badRequest('VALIDACION', 'Los datos enviados no son válidos', errores));
  }
  return next();
};

export default validar;
