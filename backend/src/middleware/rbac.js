import { forbidden } from '../utils/ApiError.js';
import { ROLES } from '../config/constants.js';

/**
 * Restringe una ruta a ciertos roles.
 *
 *   router.post('/', autenticar, exigirRol(ROLES.ADMIN), handler)
 */
export const exigirRol =
  (...rolesPermitidos) =>
  (req, _res, next) => {
    if (!req.usuario) return next(forbidden('Requiere autenticación'));
    if (!rolesPermitidos.includes(req.usuario.rol)) {
      return next(
        forbidden(
          `Esta operación requiere rol ${rolesPermitidos.join(' o ')}; tu rol es ${req.usuario.rol}`,
        ),
      );
    }
    return next();
  };

export const soloAdmin = exigirRol(ROLES.ADMIN);

/**
 * El rol VENDEDOR no debe ver márgenes ni costos de compra: es información
 * sensible del negocio. Se filtra en la capa de respuesta en lugar de tener
 * consultas distintas por rol.
 */
const CAMPOS_SENSIBLES = ['precio_compra', 'costo_unitario', 'costo_total', 'costo', 'margen', 'margen_bruto', 'margen_potencial', 'valor_costo'];

export function ocultarCostos(datos, rol) {
  if (rol === ROLES.ADMIN) return datos;
  if (Array.isArray(datos)) return datos.map((d) => ocultarCostos(d, rol));
  if (datos && typeof datos === 'object' && !(datos instanceof Date)) {
    const copia = {};
    for (const [k, v] of Object.entries(datos)) {
      if (CAMPOS_SENSIBLES.includes(k)) continue;
      copia[k] = v && typeof v === 'object' ? ocultarCostos(v, rol) : v;
    }
    return copia;
  }
  return datos;
}
