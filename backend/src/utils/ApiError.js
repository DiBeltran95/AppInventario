/**
 * Error de aplicación con código HTTP y un `codigo` estable que el cliente
 * puede interpretar sin leer el texto (el texto es para humanos y puede
 * cambiar; el código no).
 *
 * `permanente` distingue los errores que el cliente NO debe reintentar: una
 * validación fallida no se arregla reenviándola, y reintentarla eternamente
 * bloquearía la cola de sincronización.
 */
export class ApiError extends Error {
  constructor(status, codigo, mensaje, detalles = null, { permanente = null } = {}) {
    super(mensaje);
    this.name = 'ApiError';
    this.status = status;
    this.codigo = codigo;
    this.detalles = detalles;
    // 4xx (salvo 408/429) no se arregla reintentando.
    this.permanente =
      permanente ?? (status >= 400 && status < 500 && status !== 408 && status !== 429);
    Error.captureStackTrace?.(this, ApiError);
  }

  toJSON() {
    return {
      error: {
        codigo: this.codigo,
        mensaje: this.message,
        detalles: this.detalles ?? undefined,
        permanente: this.permanente,
      },
    };
  }
}

export const badRequest = (codigo, mensaje, detalles) =>
  new ApiError(400, codigo, mensaje, detalles);
export const unauthorized = (mensaje = 'No autenticado', codigo = 'NO_AUTENTICADO') =>
  new ApiError(401, codigo, mensaje);
export const forbidden = (mensaje = 'No autorizado', codigo = 'SIN_PERMISO') =>
  new ApiError(403, codigo, mensaje);
export const notFound = (recurso = 'Recurso') =>
  new ApiError(404, 'NO_ENCONTRADO', `${recurso} no encontrado`);
export const conflict = (codigo, mensaje, detalles) => new ApiError(409, codigo, mensaje, detalles);
export const unprocessable = (codigo, mensaje, detalles) =>
  new ApiError(422, codigo, mensaje, detalles);
export const serverError = (mensaje = 'Error interno') =>
  new ApiError(500, 'ERROR_INTERNO', mensaje, null, { permanente: false });

export default ApiError;
