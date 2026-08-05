import { z } from 'zod';
import { ROLES } from '../../config/constants.js';

export const dispositivoSchema = z.object({
  uuid: z.string().uuid(),
  nombre: z.string().min(1).max(120).default('Dispositivo'),
  plataforma: z.string().max(40).optional(),
  app_version: z.string().max(20).optional(),
});

export const loginSchema = z.object({
  email: z.string().email().max(191).toLowerCase().trim(),
  password: z.string().min(1).max(200),
  dispositivo: dispositivoSchema.optional(),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(20).max(500),
  dispositivo: dispositivoSchema.optional(),
});

export const logoutSchema = z.object({
  refresh_token: z.string().min(20).max(500).optional(),
  todos_los_dispositivos: z.boolean().default(false),
});

/**
 * Requisitos de contraseña: 8 caracteres es el mínimo del NIST cuando hay
 * limitación de intentos (que la hay: limitadorLogin). No se exigen símbolos
 * obligatorios porque empujan a los usuarios a patrones predecibles.
 */
export const passwordSchema = z
  .string()
  .min(8, 'Mínimo 8 caracteres')
  .max(200, 'Máximo 200 caracteres');

export const cambiarPasswordSchema = z.object({
  password_actual: z.string().min(1).max(200),
  password_nueva: passwordSchema,
});

export const crearUsuarioSchema = z.object({
  uuid: z.string().uuid().optional(),
  nombre: z.string().min(2).max(120).trim(),
  email: z.string().email().max(191).toLowerCase().trim(),
  password: passwordSchema,
  rol: z.enum([ROLES.ADMIN, ROLES.VENDEDOR]).default(ROLES.VENDEDOR),
  telefono: z.string().max(30).optional().nullable(),
});

export const actualizarUsuarioSchema = z.object({
  nombre: z.string().min(2).max(120).trim().optional(),
  email: z.string().email().max(191).toLowerCase().trim().optional(),
  rol: z.enum([ROLES.ADMIN, ROLES.VENDEDOR]).optional(),
  telefono: z.string().max(30).optional().nullable(),
  activo: z.boolean().optional(),
  password: passwordSchema.optional(),
});

export const uuidParamSchema = z.object({ uuid: z.string().uuid() });
