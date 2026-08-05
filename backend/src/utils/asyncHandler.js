/**
 * Envuelve un handler async para que sus rechazos lleguen al middleware de
 * errores.
 *
 * Express 5 ya propaga promesas rechazadas, pero mantener el wrapper explícito
 * hace evidente en cada ruta que el error está encauzado y evita depender de un
 * detalle de versión.
 */
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

export default asyncHandler;
