/** Constantes de dominio compartidas por todos los módulos. */

export const ROLES = Object.freeze({
  ADMIN: 'ADMIN',
  VENDEDOR: 'VENDEDOR',
});

/** Tipos de movimiento y el signo que la aplicación debe imponer a `cantidad`. */
export const TIPOS_MOVIMIENTO = Object.freeze({
  INICIAL: 1,
  ENTRADA: 1,
  DEVOLUCION: 1,
  ANULACION_VENTA: 1,
  SALIDA: -1,
  VENTA: -1,
  MERMA: -1,
  TRASLADO: -1,
  AJUSTE: 0, // el signo lo decide el usuario
});

export const METODOS_PAGO = Object.freeze([
  'EFECTIVO',
  'TARJETA',
  'TRANSFERENCIA',
  'MIXTO',
  'CREDITO',
]);

export const TIPOS_CODIGO = Object.freeze([
  'QR',
  'EAN13',
  'EAN8',
  'UPCA',
  'UPCE',
  'CODE128',
  'CODE39',
  'ITF',
  'INTERNO',
]);

export const UNIDADES_MEDIDA = Object.freeze([
  'UND',
  'KG',
  'G',
  'L',
  'ML',
  'M',
  'CAJA',
  'PAQ',
  'DOC',
]);

/**
 * Entidades que participan en la sincronización delta, en el ORDEN en que deben
 * aplicarse en el cliente para no violar claves foráneas.
 */
export const ENTIDADES_SYNC = Object.freeze([
  'configuracion',
  'usuarios',
  'categorias',
  'proveedores',
  'productos',
  'producto_codigos',
  'ventas',
  'venta_detalles',
  'movimientos_inventario',
  'alertas',
]);

/** Operaciones que el cliente puede empujar por `/sync/push`. */
export const OPERACIONES_PUSH = Object.freeze([
  'PRODUCTO_CREAR',
  'PRODUCTO_ACTUALIZAR',
  'PRODUCTO_ELIMINAR',
  'CODIGO_CREAR',
  'CODIGO_ELIMINAR',
  'CATEGORIA_CREAR',
  'CATEGORIA_ACTUALIZAR',
  'CATEGORIA_ELIMINAR',
  'PROVEEDOR_CREAR',
  'PROVEEDOR_ACTUALIZAR',
  'PROVEEDOR_ELIMINAR',
  'MOVIMIENTO_CREAR',
  'VENTA_CREAR',
  'VENTA_ANULAR',
]);

/** El prefijo `inv://p/{uuid}` identifica un QR emitido por esta app. */
export const QR_PREFIX = 'inv://p/';

export const CONFIG_DEFAULTS = Object.freeze({
  nombre_negocio: 'Mi Negocio',
  nit: '',
  direccion: '',
  telefono: '',
  moneda: 'COP',
  zona_horaria: 'America/Bogota',
  iva_por_defecto: '19.00',
  permitir_stock_negativo: 'true',
  ticket_pie: 'Gracias por su compra',
  offline_grace_days: '7',
});
