import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import pinoHttp from 'pino-http';
import { env } from './config/env.js';
import { logger } from './utils/logger.js';
import { pingDatabase } from './db/pool.js';
import { limitadorGeneral } from './middleware/rateLimit.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';

import rutasAuth from './modules/auth/routes.js';
import rutasCategorias from './modules/categorias/index.js';
import rutasProveedores from './modules/proveedores/index.js';
import rutasProductos from './modules/productos/routes.js';
import rutasInventario from './modules/inventario/routes.js';
import rutasVentas from './modules/ventas/routes.js';
import rutasReportes from './modules/reportes/routes.js';
import rutasSync from './modules/sync/routes.js';
import rutasConfiguracion from './modules/configuracion/index.js';
import rutasUploads, { directorioUploads } from './modules/uploads/index.js';

export function crearApp() {
  const app = express();

  // Detrás del proxy de alwaysdata/nginx: sin esto, req.ip sería siempre la del
  // proxy y el rate limiting se aplicaría a todos los usuarios como si fueran uno.
  app.set('trust proxy', 1);
  app.disable('x-powered-by');

  app.use(
    helmet({
      // Las imágenes de producto se sirven a la app móvil y a un eventual panel
      // en otro origen.
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      contentSecurityPolicy: false,
    }),
  );

  app.use(
    cors({
      origin: env.corsOrigins.length ? env.corsOrigins : true,
      credentials: false,
      // La app envía su identificador de dispositivo en cada petición: el
      // servidor lo usa para el folio, el rate limit de sync y la auditoría.
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Dispositivo'],
      exposedHeaders: ['RateLimit', 'RateLimit-Policy'],
    }),
  );

  app.use(compression());
  app.use(express.json({ limit: '4mb' }));
  app.use(express.urlencoded({ extended: false, limit: '1mb' }));

  app.use(
    pinoHttp({
      logger,
      autoLogging: { ignore: (req) => req.url === '/health' },
      customLogLevel: (_req, res, err) => {
        if (err || res.statusCode >= 500) return 'error';
        if (res.statusCode >= 400) return 'warn';
        return 'info';
      },
    }),
  );

  /**
   * GET /health — sondeo de conectividad REAL.
   *
   * La app lo usa para decidir si hay red utilizable. `connectivity_plus` sólo
   * sabe si hay una interfaz activa: estar conectado a un wifi de cafetería sin
   * salida a internet es el falso positivo clásico. Este endpoint confirma que
   * la API responde Y que la base contesta.
   */
  app.get('/health', async (_req, res) => {
    try {
      const bd = await pingDatabase();
      res.json({
        ok: true,
        servicio: 'inventario-api',
        version: '1.0.0',
        entorno: env.NODE_ENV,
        base_datos: { conectada: true, motor: bd.version },
        servidor_utc: new Date().toISOString(),
        zona_negocio: env.BUSINESS_TIMEZONE,
      });
    } catch (err) {
      res.status(503).json({
        ok: false,
        base_datos: { conectada: false, error: err.code ?? err.message },
        servidor_utc: new Date().toISOString(),
      });
    }
  });

  app.use('/uploads', express.static(directorioUploads, { maxAge: '7d', index: false }));

  const api = express.Router();
  api.use(limitadorGeneral);
  api.use('/auth', rutasAuth);
  api.use('/categorias', rutasCategorias);
  api.use('/proveedores', rutasProveedores);
  api.use('/productos', rutasProductos);
  api.use('/inventario', rutasInventario);
  api.use('/ventas', rutasVentas);
  api.use('/reportes', rutasReportes);
  api.use('/sync', rutasSync);
  api.use('/configuracion', rutasConfiguracion);
  api.use('/uploads', rutasUploads);

  app.use('/api/v1', api);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

export default crearApp;
