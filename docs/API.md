# API REST — referencia

Base: `http://<host>:3100/api/v1` · Autenticación: `Authorization: Bearer <access_token>`
Cabecera recomendada en toda petición desde la app: `X-Dispositivo: <uuid del dispositivo>`

**Formato de respuesta.** Todo éxito devuelve `{ "data": ... }`; las listas añaden `{ "meta": ... }`.
Todo error devuelve:

```json
{ "error": { "codigo": "STOCK_INSUFICIENTE", "mensaje": "…", "detalles": …, "permanente": false } }
```

`permanente` es el campo que gobierna la cola de sincronización del cliente: `true` → sacar de la
cola y avisar al usuario; `false` → reintentar con backoff.

**El dinero viaja como STRING** (`"12500.00"`), nunca como número JSON. Un `number` en JSON es
IEEE-754 y reintroduciría el error de coma flotante. Las cantidades igual, con 3 decimales.

---

## Autenticación

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| POST | `/auth/login` | — | Inicia sesión. Registra el dispositivo y devuelve su `prefijo_folio`. |
| POST | `/auth/refresh` | — | Rota el refresh token. Reutilizar uno revocado revoca la familia entera. |
| POST | `/auth/logout` | cualquiera | Revoca un token o todas las sesiones. |
| GET | `/auth/me` | cualquiera | Perfil y hora del servidor. |
| POST | `/auth/password` | cualquiera | Cambia la contraseña y cierra todas las sesiones. |
| GET | `/auth/usuarios` | ADMIN | Lista usuarios. |
| POST | `/auth/usuarios` | ADMIN | Crea usuario. |
| PATCH | `/auth/usuarios/:uuid` | ADMIN | Modifica usuario. |
| DELETE | `/auth/usuarios/:uuid` | ADMIN | Baja lógica. Protege al último administrador. |

**POST /auth/login**

```jsonc
// petición
{
  "email": "admin@inventario.local",
  "password": "Admin1234",
  "dispositivo": {
    "uuid": "0198b2c1-...",       // UUID v7 estable, generado por el cliente
    "nombre": "Samsung SM-A155M",
    "plataforma": "Android 14",
    "app_version": "1.0.0"
  }
}

// respuesta
{
  "data": {
    "access_token": "eyJ…",       // 15 min
    "refresh_token": "R0s…",      // 30 días, rotativo
    "refresh_expira": "2026-09-04T20:00:00.000Z",
    "usuario": { "uuid": "…", "nombre": "Administrador", "email": "…", "rol": "ADMIN", "activo": true },
    "dispositivo": { "uuid": "…", "prefijo_folio": "G0" },
    "offline_grace_days": 7,
    "servidor_utc": "2026-08-05T20:58:00.000Z"
  }
}
```

`prefijo_folio` es lo que permite que dos cajas sin conexión numeren ventas (`G0-000001`,
`A7-000001`) sin colisionar al sincronizar.

---

## Catálogo

| Método | Ruta | Rol | Notas |
|---|---|---|---|
| GET | `/productos` | cualquiera | `?buscar&categoria&estado_stock=todos\|bajo\|agotado\|disponible&activo&orden&pagina&limite` |
| GET | `/productos/codigo/:codigo` | cualquiera | Resuelve un escaneo. Devuelve `origen: QR_APP\|CODIGO\|SKU`. |
| GET | `/productos/:uuid` | cualquiera | Incluye `codigos[]` y `qr_payload`. |
| POST | `/productos` | ADMIN | Acepta `uuid` del cliente y `codigos[]`. Idempotente por `uuid`. |
| PATCH | `/productos/:uuid` | ADMIN | Esquema **estricto**: un campo desconocido devuelve 400. |
| DELETE | `/productos/:uuid` | ADMIN | Borrado lógico. |
| POST | `/productos/:uuid/codigos` | ADMIN | Añade un código. |
| DELETE | `/productos/codigos/:uuid` | ADMIN | Baja lógica del código. |
| GET/POST/PATCH/DELETE | `/categorias`, `/proveedores` | GET todos, resto ADMIN | CRUD estándar. |

**`stock_actual` no es editable.** `PATCH /productos/:uuid` con ese campo devuelve
`400 STOCK_NO_EDITABLE`: el stock se deriva del libro de movimientos y se corrige registrando un
`AJUSTE`. El esquema lo acepta explícitamente sólo para poder devolver ese error en lugar de
descartarlo en silencio.

---

## Inventario

| Método | Ruta | Rol | Notas |
|---|---|---|---|
| GET | `/inventario/movimientos` | cualquiera | `?producto&tipo&proveedor&desde&hasta&pagina&limite` |
| POST | `/inventario/movimientos` | cualquiera | Entrada, salida, merma, devolución, ajuste. |
| POST | `/inventario/conteo` | cualquiera | Ajuste por conteo físico: se envía lo contado, no la diferencia. |
| GET | `/inventario/alertas` | cualquiera | Discrepancias abiertas. |
| POST | `/inventario/alertas/:uuid/resolver` | cualquiera | Marca resuelta. |
| POST | `/inventario/recalcular` | ADMIN | Reconstruye `stock_actual` desde el libro. |

El **signo lo impone el tipo**: una `ENTRADA` con `cantidad: "-5.000"` suma 5. Sólo `AJUSTE`
respeta el signo enviado. Así un cliente no puede convertir una venta en entrada.

---

## Ventas

| Método | Ruta | Rol | Notas |
|---|---|---|---|
| GET | `/ventas` | cualquiera | `?estado&desde&hasta&usuario&buscar&incluir_reversas` |
| GET | `/ventas/:uuid` | cualquiera | Con detalle de líneas. |
| POST | `/ventas` | cualquiera | Creación en línea. La app móvil usa `/sync/push`. |
| POST | `/ventas/:uuid/anular` | ADMIN | Emite documento de reversa. Idempotente. |

Anular **no borra ni edita** la venta: la marca `ANULADA`, crea una segunda venta con importes y
cantidades negativas que la referencia (`anula_a_venta_id`), y registra movimientos
`ANULACION_VENTA` que devuelven el stock. Los reportes filtran `estado='COMPLETADA'`, así que
ambas quedan fuera.

---

## Sincronización

### POST /sync/push

Devuelve **siempre 200**, incluso si alguna operación falla: el resultado va por operación. Un 4xx
global obligaría al cliente a adivinar qué se aplicó.

```jsonc
// petición
{
  "operaciones": [
    {
      "client_op_id": "0198b2c1-...",   // UUID v7 — CLAVE DE IDEMPOTENCIA
      "tipo": "VENTA_CREAR",
      "payload": { "uuid": "...", "numero": "G0-000001", "lineas": [ … ] },
      "creado_en": "2026-08-05T20:00:00.000Z"
    }
  ]
}

// respuesta
{
  "data": {
    "resultados": [
      { "client_op_id": "…", "estado": "OK", "http_status": 200,
        "resultado": { … }, "reprocesada": true, "idempotente": false }
    ],
    "aplicadas": 1,
    "rechazadas": 0,
    "servidor_utc": "…"
  }
}
```

- `idempotente: true` → ya se había procesado; se devuelve la respuesta guardada **sin volver a
  aplicar el efecto**. Es lo que impide cobrar dos veces cuando se pierde la respuesta del primer
  intento.
- `estado: "ERROR"` con `error.permanente: true` → el cliente saca la operación de la cola.
- El efecto y el registro de idempotencia se escriben **en la misma transacción**. Si sólo se
  confirmara el efecto, un reintento lo aplicaría de nuevo.

Tipos aceptados: `PRODUCTO_CREAR`, `PRODUCTO_ACTUALIZAR`, `PRODUCTO_ELIMINAR`, `CODIGO_CREAR`,
`CODIGO_ELIMINAR`, `CATEGORIA_*`, `PROVEEDOR_*`, `MOVIMIENTO_CREAR`, `CONTEO_AJUSTAR`,
`VENTA_CREAR`, `VENTA_ANULAR`.

### POST /sync/pull

```jsonc
// petición
{
  "cursores": { "productos": { "t": "2026-08-05T10:00:00.000Z", "i": 842 } },
  "limite": 500,
  "dias_historial": 90
}

// respuesta
{
  "data": {
    "entidades": {
      "productos": { "items": [ … ], "cursor": { "t": "…", "i": 901 }, "hay_mas": false },
      "ventas":    { "items": [ … ], "cursor": { … }, "hay_mas": false },
      "configuracion": { "items": [ … ], "cursor": null, "hay_mas": false }
    },
    "hay_mas": false,
    "horizonte": "2026-05-07",
    "servidor_utc": "…",
    "zona_negocio": "America/Bogota"
  }
}
```

Es POST y no GET porque el cursor es un objeto por entidad; meterlo en la query string obligaría a
codificarlo en base64 y a pelear con el límite de longitud de URL. La operación no muta nada.

El cursor es **keyset sobre `(updated_at, id)`**, no un simple `updated_at`: varias filas pueden
compartir el mismo milisegundo y un cursor de sólo tiempo saltaría filas o las repetiría al paginar.

Los borrados llegan como filas con `deleted_at != null`. Por eso el borrado lógico es obligatorio:
un `DELETE` físico no dejaría nada que sincronizar.

Entidades: `usuarios`, `categorias`, `proveedores`, `productos`, `producto_codigos`, `ventas`,
`venta_detalles`, `movimientos_inventario`, `alertas`, `configuracion`.
Las tres de operación (`ventas`, `venta_detalles`, `movimientos_inventario`) se acotan a
`dias_historial` para no llenar el dispositivo con años de histórico.

### Otras

| Método | Ruta | Rol | Notas |
|---|---|---|---|
| GET | `/sync/estado` | cualquiera | Diagnóstico: dispositivo, conteos, últimas 20 operaciones. |
| POST | `/sync/mantenimiento` | ADMIN | Purga registros de idempotencia y tokens caducados. |

---

## Reportes

Todos agrupan por `fecha_local` (día hábil de la tienda), nunca por UTC.
Aceptan `?periodo=hoy|ayer|semana|mes|trimestre|anio` o `?desde=&hasta=`.

| Método | Ruta | Notas |
|---|---|---|
| GET | `/reportes/dashboard` | Resumen + serie de 14 días + top + stock bajo, en una sola consulta. |
| GET | `/reportes/ventas` | `&agrupar=dia\|semana\|mes` |
| GET | `/reportes/top-productos` | `&por=unidades\|ingreso\|margen&limite=` |
| GET | `/reportes/stock-bajo` | |
| GET | `/reportes/valorizacion` | Total y desglose por categoría. |
| GET | `/reportes/movimientos` | Resumen por tipo. |

El rol `VENDEDOR` no recibe los campos de costo ni de margen: se filtran en la capa de respuesta
(`ocultarCostos`), no con consultas distintas por rol.

---

## Otros

| Método | Ruta | Rol | Notas |
|---|---|---|---|
| GET | `/health` | — | **Sin `/api/v1`.** Sondeo de conectividad real que usa la app. |
| GET | `/configuracion` | cualquiera | Datos del negocio + parámetros del servidor. |
| PUT | `/configuracion` | ADMIN | Actualiza claves. |
| POST | `/uploads/imagen` | cualquiera | `multipart/form-data`, campo `imagen`. JPEG/PNG/WebP, ≤ 5 MB. |

---

## Códigos de error

| Código | HTTP | Permanente | Significado |
|---|---|---|---|
| `VALIDACION` | 400 | sí | Datos inválidos; `detalles` lista campo por campo. |
| `STOCK_NO_EDITABLE` | 400 | sí | Intento de escribir `stock_actual` directamente. |
| `PAGO_INSUFICIENTE` | 400 | sí | Efectivo recibido menor que el total. |
| `CREDENCIALES_INVALIDAS` | 401 | sí | Correo o contraseña incorrectos. |
| `TOKEN_EXPIRADO` | 401 | sí | Hay que refrescar. |
| `REFRESH_REUTILIZADO` | 401 | sí | Token robado detectado; familia revocada. |
| `SIN_PERMISO` | 403 | sí | El rol no alcanza. |
| `NO_ENCONTRADO` | 404 | sí | |
| `DUPLICADO` | 409 | sí | SKU, código o folio ya existente. |
| `STOCK_INSUFICIENTE` | 409 | sí | Sólo si `ALLOW_NEGATIVE_STOCK=false`. |
| `REFERENCIA_INVALIDA` | 422 | sí | Se referencia algo que no existe. |
| `DEMASIADOS_INTENTOS` | 429 | **no** | Límite de login. |
| `CONCURRENCIA` | 503 | **no** | Deadlock; reintentar. |
| `BD_NO_DISPONIBLE` | 503 | **no** | Base caída; reintentar. |
