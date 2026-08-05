import { z } from 'zod';
import { TIPOS_CODIGO, UNIDADES_MEDIDA } from '../../config/constants.js';

/**
 * El dinero se acepta como STRING decimal, no como número.
 * Un `number` en JSON es IEEE-754: 12345678901.23 ya no cabe exacto. Aceptar
 * sólo strings obliga al cliente a mantener la exactitud extremo a extremo.
 */
export const decimalStr = (maxEnteros, decimales) =>
  z
    .union([z.string(), z.number()])
    .transform((v) => (typeof v === 'number' ? v.toFixed(decimales) : v.trim()))
    .refine((v) => new RegExp(`^-?\\d{1,${maxEnteros}}(\\.\\d{1,${decimales}})?$`).test(v), {
      message: `Debe ser un decimal con hasta ${decimales} decimales`,
    });

export const dinero = decimalStr(12, 2);
export const cantidad = decimalStr(11, 3);

export const codigoSchema = z.object({
  uuid: z.string().uuid().optional(),
  codigo: z.string().min(1).max(191).trim(),
  tipo: z.enum(TIPOS_CODIGO).default('INTERNO'),
  es_principal: z.boolean().default(false),
  factor: cantidad.default('1.000'),
});

export const crearProductoSchema = z.object({
  uuid: z.string().uuid().optional(),
  sku: z.string().min(1).max(64).trim(),
  nombre: z.string().min(1).max(180).trim(),
  descripcion: z.string().max(5000).nullish(),
  categoria_uuid: z.string().uuid().nullish(),
  unidad_medida: z.enum(UNIDADES_MEDIDA).default('UND'),
  precio_compra: dinero.default('0.00'),
  precio_venta: dinero.default('0.00'),
  tasa_iva: decimalStr(3, 2).default('19.00'),
  stock_minimo: cantidad.default('0.000'),
  stock_maximo: cantidad.nullish(),
  imagen_url: z.string().max(500).nullish(),
  ubicacion: z.string().max(80).nullish(),
  activo: z.boolean().default(true),
  codigos: z.array(codigoSchema).max(20).default([]),
  /** Alta con existencias: genera un movimiento INICIAL, no un UPDATE de stock. */
  stock_inicial: cantidad.optional(),
});

/**
 * `.strict()` para que un campo mal escrito (`precio_vent`) devuelva 400 en vez
 * de aplicarse a medias en silencio.
 *
 * `stock_actual` se acepta EXPLÍCITAMENTE en el esquema aunque esté prohibido:
 * si lo dejara fuera, Zod lo descartaría sin decir nada y el cliente creería
 * que su ajuste se guardó. Al dejarlo pasar, el servicio devuelve
 * STOCK_NO_EDITABLE explicando que debe registrar un movimiento de AJUSTE.
 */
export const actualizarProductoSchema = crearProductoSchema
  .omit({ uuid: true, stock_inicial: true, codigos: true })
  .partial()
  .extend({ stock_actual: z.any().optional() })
  .strict();

export const filtrosProductoSchema = z.object({
  buscar: z.string().max(120).optional(),
  categoria: z.string().uuid().optional(),
  estado_stock: z.enum(['todos', 'bajo', 'agotado', 'disponible']).default('todos'),
  activo: z
    .enum(['true', 'false', 'todos'])
    .default('true')
    .transform((v) => (v === 'todos' ? null : v === 'true')),
  orden: z.enum(['nombre', 'stock', 'precio', 'reciente']).default('nombre'),
  pagina: z.coerce.number().int().min(1).default(1),
  limite: z.coerce.number().int().min(1).max(200).default(50),
});

export const paramUuid = z.object({ uuid: z.string().uuid() });
export const paramCodigo = z.object({ codigo: z.string().min(1).max(300) });
