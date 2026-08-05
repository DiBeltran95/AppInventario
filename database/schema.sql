-- ============================================================================
--  INVENTARIO POS — Esquema de base de datos
--  Motor objetivo: MariaDB 11.4.12  (VERIFICADO contra el servidor real).
--
--  NO es MySQL 8. Diferencias que condicionan este archivo:
--    · No existe la colación utf8mb4_0900_ai_ci  -> se usa utf8mb4_unicode_ci
--    · El tipo JSON es alias de LONGTEXT         -> se declara LONGTEXT
--    · sql_mode del servidor viene SIN STRICT_TRANS_TABLES -> se fuerza por
--      sesión desde el pool de Node (src/db/pool.js). Sin eso MariaDB trunca
--      datos en silencio.
--
--  Convenciones:
--    · id     BIGINT UNSIGNED  -> clave interna, nunca sale de la API
--    · uuid   CHAR(36) ascii   -> clave de negocio generada en el CLIENTE (v7)
--    · dinero DECIMAL(14,2)    -> jamás FLOAT/DOUBLE
--    · cant.  DECIMAL(14,3)    -> permite venta por peso
--    · fechas DATETIME(3) UTC  -> el servidor corre en UTC
--    · borrado lógico (deleted_at) en toda tabla sincronizable
--    · índice (updated_at, id) en toda tabla sincronizable -> cursor keyset
-- ============================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- 1. CONFIGURACIÓN DEL NEGOCIO (clave-valor)
-- ============================================================================
CREATE TABLE IF NOT EXISTS configuracion (
  clave        VARCHAR(64)  NOT NULL,
  valor        TEXT         NOT NULL,
  tipo         ENUM('STRING','INT','DECIMAL','BOOL','JSON') NOT NULL DEFAULT 'STRING',
  descripcion  VARCHAR(255) NULL,
  updated_at   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. USUARIOS
-- ============================================================================
CREATE TABLE IF NOT EXISTS usuarios (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid           CHAR(36)     CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  nombre         VARCHAR(120) NOT NULL,
  email          VARCHAR(191) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL COMMENT 'argon2id',
  rol            ENUM('ADMIN','VENDEDOR') NOT NULL DEFAULT 'VENDEDOR',
  activo         TINYINT(1)   NOT NULL DEFAULT 1,
  telefono       VARCHAR(30)  NULL,
  ultimo_acceso  DATETIME(3)  NULL,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at     DATETIME(3)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_usuarios_uuid  (uuid),
  UNIQUE KEY uk_usuarios_email (email),
  KEY idx_usuarios_sync (updated_at, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. DISPOSITIVOS
--    prefijo_folio: evita que dos cajas offline generen el mismo número de
--    venta. Se asigna al registrar el dispositivo (A1, A2, B3...).
-- ============================================================================
CREATE TABLE IF NOT EXISTS dispositivos (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  usuario_id      BIGINT UNSIGNED NULL,
  nombre          VARCHAR(120) NOT NULL,
  plataforma      VARCHAR(40)  NULL,
  app_version     VARCHAR(20)  NULL,
  prefijo_folio   VARCHAR(6)   CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  ultimo_sync_at  DATETIME(3)  NULL,
  activo          TINYINT(1)   NOT NULL DEFAULT 1,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at      DATETIME(3)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_dispositivos_uuid    (uuid),
  UNIQUE KEY uk_dispositivos_prefijo (prefijo_folio),
  KEY idx_dispositivos_usuario (usuario_id),
  KEY idx_dispositivos_sync (updated_at, id),
  CONSTRAINT fk_dispositivos_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. REFRESH TOKENS (rotativos, revocables)
--    Se guarda SHA-256 del token, nunca el token en claro.
-- ============================================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id    BIGINT UNSIGNED NOT NULL,
  token_hash    CHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  familia       CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
                COMMENT 'Cadena de rotación: reutilizar un token revocado mata la familia entera',
  dispositivo_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
  user_agent    VARCHAR(255) NULL,
  expires_at    DATETIME(3)  NOT NULL,
  revoked_at    DATETIME(3)  NULL,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_refresh_hash (token_hash),
  KEY idx_refresh_usuario (usuario_id),
  KEY idx_refresh_familia (familia),
  KEY idx_refresh_expira  (expires_at),
  CONSTRAINT fk_refresh_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. CATEGORÍAS
-- ============================================================================
CREATE TABLE IF NOT EXISTS categorias (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid        CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  nombre      VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255) NULL,
  color       CHAR(7) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '#6750A4'
              COMMENT 'Hex para la UI',
  icono       VARCHAR(40) NULL,
  orden       INT NOT NULL DEFAULT 0,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at  DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_categorias_uuid (uuid),
  KEY idx_categorias_nombre (nombre),
  KEY idx_categorias_sync (updated_at, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. PROVEEDORES
-- ============================================================================
CREATE TABLE IF NOT EXISTS proveedores (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid       CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  nombre     VARCHAR(150) NOT NULL,
  nit        VARCHAR(30)  NULL,
  contacto   VARCHAR(120) NULL,
  telefono   VARCHAR(30)  NULL,
  email      VARCHAR(191) NULL,
  direccion  VARCHAR(255) NULL,
  notas      TEXT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_proveedores_uuid (uuid),
  KEY idx_proveedores_nombre (nombre),
  KEY idx_proveedores_sync (updated_at, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 7. PRODUCTOS
--    stock_actual es una PROYECCIÓN mantenida por triggers a partir de
--    movimientos_inventario. La verdad vive en el libro de movimientos.
--    Ningún código de aplicación debe escribir stock_actual directamente.
-- ============================================================================
CREATE TABLE IF NOT EXISTS productos (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid           CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  sku            VARCHAR(64) NOT NULL,
  nombre         VARCHAR(180) NOT NULL,
  descripcion    TEXT NULL,
  categoria_id   BIGINT UNSIGNED NULL,
  unidad_medida  ENUM('UND','KG','G','L','ML','M','CAJA','PAQ','DOC') NOT NULL DEFAULT 'UND',
  precio_compra  DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  precio_venta   DECIMAL(14,2) NOT NULL DEFAULT 0.00 COMMENT 'IVA INCLUIDO',
  tasa_iva       DECIMAL(5,2)  NOT NULL DEFAULT 19.00,
  stock_actual   DECIMAL(14,3) NOT NULL DEFAULT 0.000 COMMENT 'DERIVADO — lo mantienen los triggers',
  stock_minimo   DECIMAL(14,3) NOT NULL DEFAULT 0.000,
  stock_maximo   DECIMAL(14,3) NULL,
  imagen_url     VARCHAR(500) NULL,
  ubicacion      VARCHAR(80)  NULL COMMENT 'Pasillo/estante',
  activo         TINYINT(1)   NOT NULL DEFAULT 1,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at     DATETIME(3)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_productos_uuid (uuid),
  UNIQUE KEY uk_productos_sku  (sku),
  KEY idx_productos_categoria (categoria_id),
  KEY idx_productos_nombre    (nombre),
  KEY idx_productos_activo    (activo, deleted_at),
  KEY idx_productos_sync      (updated_at, id),
  KEY idx_productos_bajo_stock (stock_actual, stock_minimo),
  FULLTEXT KEY ft_productos (nombre, descripcion),
  CONSTRAINT fk_productos_categoria FOREIGN KEY (categoria_id)
    REFERENCES categorias (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_productos_precios CHECK (precio_compra >= 0 AND precio_venta >= 0),
  CONSTRAINT ck_productos_iva     CHECK (tasa_iva >= 0 AND tasa_iva <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 8. CÓDIGOS DE PRODUCTO (QR / EAN / UPC / Code128)
--    Un producto puede tener varios: la caja de 12 y la unidad suelta traen
--    códigos de fábrica distintos.
-- ============================================================================
CREATE TABLE IF NOT EXISTS producto_codigos (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid         CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  producto_id  BIGINT UNSIGNED NOT NULL,
  codigo       VARCHAR(191) NOT NULL,
  tipo         ENUM('QR','EAN13','EAN8','UPCA','UPCE','CODE128','CODE39','ITF','INTERNO')
               NOT NULL DEFAULT 'INTERNO',
  es_principal TINYINT(1) NOT NULL DEFAULT 0,
  factor       DECIMAL(14,3) NOT NULL DEFAULT 1.000
               COMMENT 'Unidades que representa este código (caja de 12 -> 12)',
  created_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at   DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_prodcod_uuid   (uuid),
  UNIQUE KEY uk_prodcod_codigo (codigo),
  KEY idx_prodcod_producto (producto_id),
  KEY idx_prodcod_sync (updated_at, id),
  CONSTRAINT fk_prodcod_producto FOREIGN KEY (producto_id)
    REFERENCES productos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_prodcod_factor CHECK (factor > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 9. VENTAS (documento inmutable)
--    numero: '<prefijo_dispositivo>-<consecutivo>' -> único entre cajas offline.
--    fecha_local: día hábil en la zona de la tienda; los reportes agrupan por
--    esta columna, no por UTC.
-- ============================================================================
CREATE TABLE IF NOT EXISTS ventas (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid              CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  numero            VARCHAR(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  usuario_id        BIGINT UNSIGNED NULL,
  dispositivo_uuid  CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
  cliente_nombre    VARCHAR(150) NULL,
  cliente_documento VARCHAR(40)  NULL,
  subtotal          DECIMAL(14,2) NOT NULL DEFAULT 0.00 COMMENT 'Base gravable, sin IVA',
  descuento_total   DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  impuesto_total    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total             DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  costo_total       DECIMAL(14,2) NOT NULL DEFAULT 0.00 COMMENT 'Snapshot para margen',
  metodo_pago       ENUM('EFECTIVO','TARJETA','TRANSFERENCIA','MIXTO','CREDITO')
                    NOT NULL DEFAULT 'EFECTIVO',
  monto_recibido    DECIMAL(14,2) NULL,
  cambio            DECIMAL(14,2) NULL,
  estado            ENUM('COMPLETADA','ANULADA') NOT NULL DEFAULT 'COMPLETADA',
  anula_a_venta_id  BIGINT UNSIGNED NULL COMMENT 'Si es documento de reversa',
  motivo_anulacion  VARCHAR(255) NULL,
  notas             VARCHAR(500) NULL,
  fecha             DATETIME(3) NOT NULL COMMENT 'Hora de negocio del dispositivo (UTC)',
  fecha_local       DATE        NOT NULL COMMENT 'Día hábil en zona de la tienda',
  creada_offline    TINYINT(1)  NOT NULL DEFAULT 0,
  sincronizada_en   DATETIME(3) NULL,
  created_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at        DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_ventas_uuid   (uuid),
  UNIQUE KEY uk_ventas_numero (numero),
  KEY idx_ventas_fecha_local (fecha_local),
  KEY idx_ventas_usuario     (usuario_id),
  KEY idx_ventas_estado      (estado, fecha_local),
  KEY idx_ventas_sync        (updated_at, id),
  KEY idx_ventas_anula       (anula_a_venta_id),
  CONSTRAINT fk_ventas_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_ventas_anula FOREIGN KEY (anula_a_venta_id)
    REFERENCES ventas (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_ventas_total CHECK (total >= 0 OR estado = 'ANULADA')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 10. DETALLE DE VENTA
--     descripcion / sku_snapshot / costo_unitario son COPIAS al momento de la
--     venta: si mañana cambia el producto, el ticket histórico no debe mutar.
-- ============================================================================
CREATE TABLE IF NOT EXISTS venta_detalles (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  venta_id        BIGINT UNSIGNED NOT NULL,
  producto_id     BIGINT UNSIGNED NULL,
  linea           INT NOT NULL DEFAULT 1,
  descripcion     VARCHAR(200) NOT NULL COMMENT 'Snapshot del nombre',
  sku_snapshot    VARCHAR(64)  NULL,
  cantidad        DECIMAL(14,3) NOT NULL,
  precio_unitario DECIMAL(14,2) NOT NULL COMMENT 'IVA incluido',
  costo_unitario  DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  descuento       DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tasa_iva        DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  base_gravable   DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  impuesto        DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total           DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_vdet_uuid (uuid),
  KEY idx_vdet_venta    (venta_id),
  KEY idx_vdet_producto (producto_id),
  KEY idx_vdet_sync     (updated_at, id),
  CONSTRAINT fk_vdet_venta FOREIGN KEY (venta_id)
    REFERENCES ventas (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_vdet_producto FOREIGN KEY (producto_id)
    REFERENCES productos (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_vdet_cantidad CHECK (cantidad <> 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 11. MOVIMIENTOS DE INVENTARIO  (libro append-only — FUENTE DE VERDAD)
--     cantidad CON SIGNO: positiva suma stock, negativa lo resta.
--     Así stock = SUM(cantidad) sin CASE, y AJUSTE funciona en ambos sentidos.
-- ============================================================================
CREATE TABLE IF NOT EXISTS movimientos_inventario (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid             CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  producto_id      BIGINT UNSIGNED NOT NULL,
  tipo             ENUM('INICIAL','ENTRADA','SALIDA','VENTA','ANULACION_VENTA',
                        'DEVOLUCION','AJUSTE','MERMA','TRASLADO') NOT NULL,
  cantidad         DECIMAL(14,3) NOT NULL COMMENT 'CON SIGNO',
  costo_unitario   DECIMAL(14,2) NULL,
  precio_unitario  DECIMAL(14,2) NULL,
  stock_anterior   DECIMAL(14,3) NULL COMMENT 'Auditoría — lo llena el trigger',
  stock_resultante DECIMAL(14,3) NULL COMMENT 'Auditoría — lo llena el trigger',
  venta_id         BIGINT UNSIGNED NULL,
  proveedor_id     BIGINT UNSIGNED NULL,
  usuario_id       BIGINT UNSIGNED NULL,
  dispositivo_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
  lote             VARCHAR(60) NULL,
  vence_el         DATE NULL,
  documento_ref    VARCHAR(60) NULL COMMENT 'Factura del proveedor, remisión...',
  motivo           VARCHAR(255) NULL,
  fecha            DATETIME(3) NOT NULL COMMENT 'Hora de negocio del dispositivo (UTC)',
  fecha_local      DATE NOT NULL,
  creado_offline   TINYINT(1) NOT NULL DEFAULT 0,
  created_at       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_mov_uuid (uuid),
  KEY idx_mov_producto  (producto_id, fecha),
  KEY idx_mov_tipo      (tipo, fecha_local),
  KEY idx_mov_venta     (venta_id),
  KEY idx_mov_proveedor (proveedor_id),
  KEY idx_mov_usuario   (usuario_id),
  KEY idx_mov_sync      (updated_at, id),
  CONSTRAINT fk_mov_producto FOREIGN KEY (producto_id)
    REFERENCES productos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_mov_venta FOREIGN KEY (venta_id)
    REFERENCES ventas (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_mov_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedores (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_mov_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_mov_cantidad CHECK (cantidad <> 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 12. IDEMPOTENCIA DE SINCRONIZACIÓN
--     La clave primaria ES la garantía: un reenvío devuelve la respuesta
--     guardada en lugar de volver a aplicar el efecto.
-- ============================================================================
CREATE TABLE IF NOT EXISTS sync_operaciones (
  client_op_id     CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  tipo             VARCHAR(50) NOT NULL,
  entidad          VARCHAR(40) NOT NULL,
  entidad_uuid     CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
  usuario_id       BIGINT UNSIGNED NULL,
  dispositivo_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
  estado           ENUM('OK','ERROR') NOT NULL,
  http_status      SMALLINT UNSIGNED NOT NULL DEFAULT 200,
  respuesta        LONGTEXT NULL COMMENT 'JSON (MariaDB: JSON es alias de LONGTEXT)',
  created_at       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (client_op_id),
  KEY idx_syncop_entidad (entidad, entidad_uuid),
  KEY idx_syncop_fecha   (created_at),
  KEY idx_syncop_disp    (dispositivo_uuid, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 13. ALERTAS (discrepancias detectadas por el servidor)
-- ============================================================================
CREATE TABLE IF NOT EXISTS alertas (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid         CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  tipo         ENUM('STOCK_NEGATIVO','SOBREVENTA','STOCK_BAJO','COSTO_ANOMALO',
                    'PRODUCTO_DUPLICADO','SYNC_RECHAZADA') NOT NULL,
  severidad    ENUM('INFO','ADVERTENCIA','CRITICA') NOT NULL DEFAULT 'ADVERTENCIA',
  producto_id  BIGINT UNSIGNED NULL,
  venta_id     BIGINT UNSIGNED NULL,
  mensaje      VARCHAR(500) NOT NULL,
  detalle      LONGTEXT NULL,
  resuelta_en  DATETIME(3) NULL,
  resuelta_por BIGINT UNSIGNED NULL,
  created_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_alertas_uuid (uuid),
  KEY idx_alertas_tipo (tipo, resuelta_en),
  KEY idx_alertas_producto (producto_id),
  KEY idx_alertas_sync (updated_at, id),
  CONSTRAINT fk_alertas_producto FOREIGN KEY (producto_id)
    REFERENCES productos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_alertas_venta FOREIGN KEY (venta_id)
    REFERENCES ventas (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 14. AUDITORÍA
-- ============================================================================
CREATE TABLE IF NOT EXISTS auditoria (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id    BIGINT UNSIGNED NULL,
  accion        VARCHAR(60) NOT NULL,
  entidad       VARCHAR(40) NOT NULL,
  entidad_uuid  CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
  datos_antes   LONGTEXT NULL,
  datos_despues LONGTEXT NULL,
  ip            VARCHAR(45) NULL,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_audit_usuario (usuario_id, created_at),
  KEY idx_audit_entidad (entidad, entidad_uuid),
  KEY idx_audit_fecha   (created_at),
  CONSTRAINT fk_audit_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 15. TRIGGERS — únicos dueños de la proyección `productos.stock_actual`
--     Regla: ningún UPDATE de aplicación toca stock_actual. Se inserta el
--     movimiento y el trigger mantiene la proyección. Así es imposible que
--     el libro y la proyección se desincronicen por un olvido en el código.
--     El servicio de ventas hace SELECT ... FOR UPDATE sobre el producto antes
--     de insertar, lo que serializa los movimientos concurrentes del mismo SKU.
-- ============================================================================

DROP TRIGGER IF EXISTS trg_mov_before_insert;
DELIMITER $$
CREATE TRIGGER trg_mov_before_insert
BEFORE INSERT ON movimientos_inventario
FOR EACH ROW
BEGIN
  DECLARE v_stock DECIMAL(14,3);
  SELECT stock_actual INTO v_stock FROM productos WHERE id = NEW.producto_id;
  SET NEW.stock_anterior   = IFNULL(v_stock, 0);
  SET NEW.stock_resultante = IFNULL(v_stock, 0) + NEW.cantidad;
  IF NEW.fecha_local IS NULL THEN
    SET NEW.fecha_local = DATE(NEW.fecha);
  END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_mov_after_insert;
DELIMITER $$
CREATE TRIGGER trg_mov_after_insert
AFTER INSERT ON movimientos_inventario
FOR EACH ROW
BEGIN
  UPDATE productos
     SET stock_actual = stock_actual + NEW.cantidad
   WHERE id = NEW.producto_id;
END$$
DELIMITER ;

-- Inmutabilidad del libro: prohíbe alterar el efecto de un movimiento ya
-- registrado. Corregir se hace insertando un movimiento compensatorio.
DROP TRIGGER IF EXISTS trg_mov_before_update;
DELIMITER $$
CREATE TRIGGER trg_mov_before_update
BEFORE UPDATE ON movimientos_inventario
FOR EACH ROW
BEGIN
  IF NEW.cantidad <> OLD.cantidad OR NEW.producto_id <> OLD.producto_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'movimientos_inventario es append-only: use un movimiento compensatorio';
  END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_mov_before_delete;
DELIMITER $$
CREATE TRIGGER trg_mov_before_delete
BEFORE DELETE ON movimientos_inventario
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'movimientos_inventario es append-only: no se permite DELETE';
END$$
DELIMITER ;

-- ============================================================================
-- 16. PROCEDIMIENTOS
-- ============================================================================

-- Reconstruye stock_actual desde el libro de movimientos. Es la red de
-- seguridad que permite afirmar que la proyección es recalculable.
DROP PROCEDURE IF EXISTS sp_recalcular_stock;
DELIMITER $$
CREATE PROCEDURE sp_recalcular_stock(IN p_producto_uuid CHAR(36))
BEGIN
  IF p_producto_uuid IS NULL OR p_producto_uuid = '' THEN
    UPDATE productos p
       SET p.stock_actual = IFNULL(
             (SELECT SUM(m.cantidad) FROM movimientos_inventario m
               WHERE m.producto_id = p.id), 0);
  ELSE
    UPDATE productos p
       SET p.stock_actual = IFNULL(
             (SELECT SUM(m.cantidad) FROM movimientos_inventario m
               WHERE m.producto_id = p.id), 0)
     WHERE p.uuid = p_producto_uuid;
  END IF;
END$$
DELIMITER ;

-- Consecutivo de folio por dispositivo. Se usa sólo cuando la venta se crea
-- en línea; una venta creada offline trae su propio número ya asignado.
DROP FUNCTION IF EXISTS fn_siguiente_folio;
DELIMITER $$
CREATE FUNCTION fn_siguiente_folio(p_prefijo VARCHAR(6))
RETURNS VARCHAR(30)
NOT DETERMINISTIC
MODIFIES SQL DATA
BEGIN
  DECLARE v_max INT;
  SELECT IFNULL(MAX(CAST(SUBSTRING_INDEX(numero, '-', -1) AS UNSIGNED)), 0)
    INTO v_max
    FROM ventas
   WHERE numero LIKE CONCAT(p_prefijo, '-%');
  RETURN CONCAT(p_prefijo, '-', LPAD(v_max + 1, 6, '0'));
END$$
DELIMITER ;

-- ============================================================================
-- 17. VISTAS DE REPORTE
--     Agrupan por fecha_local (día hábil de la tienda), nunca por UTC.
-- ============================================================================

CREATE OR REPLACE VIEW v_productos_stock_bajo AS
SELECT p.id, p.uuid, p.sku, p.nombre, p.stock_actual, p.stock_minimo,
       (p.stock_minimo - p.stock_actual) AS faltante,
       c.nombre AS categoria, p.precio_compra, p.precio_venta
  FROM productos p
  LEFT JOIN categorias c ON c.id = p.categoria_id
 WHERE p.deleted_at IS NULL
   AND p.activo = 1
   AND p.stock_actual <= p.stock_minimo
 ORDER BY (p.stock_actual - p.stock_minimo) ASC;

CREATE OR REPLACE VIEW v_valorizacion_inventario AS
SELECT p.id, p.uuid, p.sku, p.nombre, p.stock_actual,
       p.precio_compra,
       ROUND(p.stock_actual * p.precio_compra, 2) AS valor_costo,
       p.precio_venta,
       ROUND(p.stock_actual * p.precio_venta, 2)  AS valor_venta,
       ROUND(p.stock_actual * (p.precio_venta - p.precio_compra), 2) AS margen_potencial
  FROM productos p
 WHERE p.deleted_at IS NULL AND p.activo = 1;

CREATE OR REPLACE VIEW v_ventas_diarias AS
SELECT v.fecha_local,
       COUNT(*)                                   AS num_ventas,
       SUM(v.total)                               AS total_vendido,
       SUM(v.subtotal)                            AS total_base,
       SUM(v.impuesto_total)                      AS total_impuesto,
       SUM(v.descuento_total)                     AS total_descuento,
       SUM(v.costo_total)                         AS total_costo,
       SUM(v.total - v.costo_total)               AS margen_bruto,
       ROUND(AVG(v.total), 2)                     AS ticket_promedio
  FROM ventas v
 WHERE v.estado = 'COMPLETADA' AND v.deleted_at IS NULL
 GROUP BY v.fecha_local;

CREATE OR REPLACE VIEW v_top_productos AS
SELECT d.producto_id,
       p.uuid, p.sku,
       MAX(d.descripcion)             AS nombre,
       SUM(d.cantidad)                AS unidades_vendidas,
       SUM(d.total)                   AS ingreso,
       SUM(d.costo_unitario * d.cantidad) AS costo,
       SUM(d.total - (d.costo_unitario * d.cantidad)) AS margen,
       COUNT(DISTINCT d.venta_id)     AS num_ventas
  FROM venta_detalles d
  JOIN ventas v   ON v.id = d.venta_id AND v.estado = 'COMPLETADA' AND v.deleted_at IS NULL
  LEFT JOIN productos p ON p.id = d.producto_id
 GROUP BY d.producto_id, p.uuid, p.sku;
