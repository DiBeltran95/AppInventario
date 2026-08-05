# Análisis del prompt original y versión mejorada

## Parte 1 — Qué falla en el prompt original

El prompt original está bien estructurado y es mejor que el 90 % de los briefs que se ven. Pero tiene
**22 vacíos** que, si no se cierran antes de escribir código, obligan a reescribir la arquitectura a medio
camino. Los agrupo por gravedad.

### A. Errores que rompen la arquitectura (hay que resolverlos antes de la primera línea de código)

| # | Problema | Por qué importa |
|---|---|---|
| 1 | **«Modo offline básico (opcional pero deseable)»** | Offline no es una *feature*, es un **modelo de datos**. Decidirlo después obliga a rehacer IDs, claves primarias, semántica de stock y todos los endpoints. En el mensaje ya se aclaró que es obligatorio → sube a requisito #1. |
| 2 | **`stock_actual` como columna mutable** | Con dos dispositivos vendiendo sin conexión, un `UPDATE stock = stock - 1` es irreproducible y se pierde. El stock debe ser **derivado de un libro de movimientos append-only**, no un contador que se pisa. |
| 3 | **No define política de conflictos** | ¿Qué pasa si el celular A y el celular B venden la última unidad, ambos sin internet? Sin respuesta explícita, cualquier implementación es una apuesta. |
| 4 | **No exige idempotencia** | El bug más caro de un POS: se envía la venta, se cae la red antes de recibir el 200, el cliente reintenta → **venta duplicada y stock descontado dos veces**. Requiere `client_op_id` + tabla de idempotencia en servidor. |
| 5 | **IDs autoincrementales implícitos** | Un dispositivo offline no puede pedir un `AUTO_INCREMENT`. Se necesitan **UUID generados en el cliente** como clave de negocio. |
| 6 | **«eliminar productos»** | El borrado físico rompe la sincronización (el otro dispositivo nunca se entera) y destruye el histórico de ventas. Debe ser **soft delete** (`deleted_at`) propagado. |
| 7 | **La base de datos no es MySQL, es MariaDB 11.4.12** | Verificado contra el host real. Cambia colación por defecto (`utf8mb4_general_ci`), el tipo `JSON` (alias de `LONGTEXT`), y el `sql_mode` llega **sin `STRICT_TRANS_TABLES` ni `ONLY_FULL_GROUP_BY`** → MariaDB truncaría datos en silencio si no se fuerza por sesión. |
| 8 | **Sin historia de autenticación offline** | El JWT caduca. Si el vendedor abre la app sin internet y el token expiró, ¿no puede vender? Hace falta desbloqueo local con hash + ventana de gracia. |

### B. Errores de corrección funcional (producen datos malos en producción)

| # | Problema | Corrección |
|---|---|---|
| 9 | **No especifica el tipo de dato del dinero** | `FLOAT`/`double` en dinero produce descuadres de centavos. → `DECIMAL(14,2)` en BD y **enteros en unidades mínimas** en Dart. |
| 10 | **Sin impuestos, descuentos ni redondeo** | En Colombia hay IVA (0 / 5 / 19 %) y el COP no usa decimales. Hay que definir si el precio es IVA incluido y cómo se redondea. |
| 11 | **Sin anulaciones ni devoluciones** | Una venta es inmutable. Corregir un error exige un **documento de reversa**, no un `DELETE`. |
| 12 | **Zona horaria** | El servidor está en **UTC**; la tienda opera en `America/Bogota`. «Ventas del día» debe calcularse por **día hábil local**, no por UTC, o el reporte se corta a las 7 p. m. |
| 13 | **No define qué contiene el QR** | ¿SKU crudo? ¿URI? ¿Y los EAN-13 impresos de fábrica que ya traen los productos? Sin esto, el escáner no sabe qué hacer con un código. |
| 14 | **Sin traza de auditoría** | En un negocio con empleados hay que saber quién movió stock y quién anuló una venta. |

### C. Requisitos no verificables (no se pueden dar por «terminados»)

| # | Problema | Corrección |
|---|---|---|
| 15 | **«Debe sentirse premium»** | Inmedible. → Presupuestos concretos: escaneo→confirmación < 400 ms, 60 fps en la lista, feedback háptico < 100 ms tras detectar. |
| 16 | **«Investiga apps reales (Square, Shopify, Vend…)»** | Un modelo no puede instalar ni operar esas apps; «investigar» derivaría en describir capturas de marketing. → Reformular como **patrones de UX documentados a aplicar**, con la decisión y el motivo explícitos. |
| 17 | **Sin presupuestos de rendimiento ni volumen** | ¿1.000 o 100.000 productos? Cambia si la lista es `ListView` o `ListView.builder` con índice FTS. |
| 18 | **«proponme la mejor opción entre Node.js + Express»** | Frase incompleta: ofrece «elegir» entre una sola alternativa. Además ya venía decidido Node.js. → Eliminar la falsa elección y justificar el runtime elegido. |

### D. Huecos de seguridad y operación

| # | Problema | Corrección |
|---|---|---|
| 19 | **No dice cómo se hashean contraseñas** | → Argon2id (no bcrypt, no SHA). |
| 20 | **Sin rate limiting ni política de transporte** | La API queda expuesta a fuerza bruta. HTTPS obligatorio; en Android, `usesCleartextTraffic=false` salvo en debug. |
| 21 | **Sin plan de robo/pérdida del dispositivo** | Hay ventas no sincronizadas dentro. → Cifrado del almacén de tokens, PIN, y revocación de refresh token en servidor. |
| 22 | **Sin migraciones ni respaldo** | `schema.sql` de una sola vez no sobrevive al segundo cambio de modelo. → Migraciones versionadas y numeradas. |

### Decisiones que tomo por ti (y que el prompt debía fijar)

| Punto abierto | Decisión | Motivo |
|---|---|---|
| Gestión de estado | **Riverpod 3** (no Bloc) | La UI se alimenta de *streams* de la base local; `StreamProvider`/`AsyncNotifier` encajan sin *boilerplate*. Bloc obligaría a un evento por cada cambio que ya emite Drift. |
| Persistencia local | **Drift** (sobre `sqflite`/Hive) | Se necesitan transacciones, joins y agregados **sin conexión** (reportes offline). Hive es clave-valor: no sirve. Drift da SQL tipado, migraciones y streams reactivos. |
| Conflicto de stock | **Aceptar ambas ventas y marcar discrepancia** | No se puede «des-vender» mercancía ya entregada. Rechazar la segunda venta corrompería la caja. Igual que hace Square. |
| Conflicto de catálogo | **LWW por `updated_at`, servidor desempata** | Editar un nombre de producto en dos sitios es raro y de bajo impacto. |
| Precio | **IVA incluido en el precio de venta** | Es lo habitual en retail colombiano; se desglosa en el ticket. |

---
---

## Parte 2 — Prompt mejorado (versión para usar)

> Copia desde aquí.

---

Actúa como **arquitecto de software senior** especializado en **sistemas distribuidos offline-first** y como
**desarrollador Flutter de nivel producción**. Vas a diseñar y construir una aplicación Android de
**gestión de inventario y punto de venta con escaneo de códigos**, que debe **operar al 100 % sin conexión**
y sincronizar cuando la recupere.

### 0. Restricción rectora (léela antes que todo lo demás)

**La app es offline-first, no «online con caché».** El dispositivo debe poder, sin una sola petición de red:
iniciar sesión, buscar en el catálogo completo, registrar entradas de inventario, vender, imprimir el ticket
y ver los reportes del día. La red es una **optimización**, nunca un requisito de funcionamiento.

Esto implica, y debes implementarlo explícitamente:

1. **La base de datos local (SQLite) es la fuente de verdad del dispositivo.** La UI **nunca** lee de la red;
   lee de SQLite. La red sólo alimenta SQLite.
2. **Toda entidad lleva un UUID v7 generado en el cliente** como clave de negocio. El `BIGINT AUTO_INCREMENT`
   del servidor es interno y jamás viaja como identificador.
3. **El stock es derivado, no almacenado como verdad.** Existe un libro de movimientos *append-only*
   (`movimientos_inventario`); `stock_actual` es una proyección materializada y recalculable.
   Debe existir un procedimiento de reconciliación que la reconstruya desde cero.
4. **Patrón outbox obligatorio.** Cada mutación local escribe, **en la misma transacción**, la fila de dominio
   y una fila en `sync_outbox`. Un *worker* drena la cola en orden FIFO con reintentos y backoff exponencial.
5. **Idempotencia extremo a extremo.** Cada operación de la outbox lleva un `client_op_id` (UUID). El servidor
   persiste el resultado por `client_op_id`; un reenvío devuelve el resultado guardado **sin volver a aplicar**
   el efecto. Un reintento tras timeout **jamás** puede duplicar una venta.
6. **Sincronización delta por cursor keyset.** `GET /sync/pull?cursors={...}` devuelve cambios por entidad
   ordenados por `(updated_at, id)`, con soft delete propagado (`deleted_at`). Nada de «bajar todo».

### 1. Política de conflictos (defínela así, no la improvises)

| Tipo de dato | Naturaleza | Política |
|---|---|---|
| Ventas y movimientos de inventario | Eventos inmutables *append-only* | **Sin conflicto posible.** El servidor los acepta todos y los aplica en orden de llegada. |
| Catálogo (producto, categoría, proveedor) | Estado mutable | **Last-Write-Wins** por `updated_at`; ante empate gana el servidor. |
| `stock_actual` | Derivado | **Nunca se sincroniza como valor absoluto.** El cliente envía *deltas* (movimientos); el servidor recalcula y devuelve el valor autoritativo en el pull. |
| Sobreventa offline (dos equipos venden la última unidad) | — | **Ambas ventas se aceptan.** El servidor registra una alerta `discrepancia_stock` y deja el stock en negativo hasta el ajuste manual. Rechazar la segunda venta descuadraría la caja frente a mercancía ya entregada. |
| Corrección de una venta | — | **Nunca se edita ni se borra.** Se emite un documento de reversa (`tipo='ANULACION'`) que referencia el original. |

### 2. Alcance funcional

- **Entradas de inventario**: escanear código → si existe, sumar stock (cantidad, costo unitario, proveedor,
  lote opcional, fecha); si no existe, ofrecer alta rápida del producto sin salir del flujo.
- **Venta**: escanear → agregar al carrito (si se repite el código, incrementa cantidad) → editar cantidades y
  descuento → cobrar (efectivo con cálculo de vueltas / transferencia / tarjeta) → ticket.
- **Catálogo**: alta, edición, **baja lógica**, búsqueda por nombre/SKU/código, filtros por categoría y estado de stock.
- **Reportes** (calculados **en local**, para que funcionen sin red): stock bajo, valorización del inventario a
  costo, movimientos por rango, ventas por día/semana/mes, top de productos, margen bruto.
- **Códigos**: generar QR para productos sin código de fábrica y exportarlo como PDF de etiquetas.
- **Roles**: `ADMIN` (todo) y `VENDEDOR` (vender y consultar; no edita precios ni ve costos).

### 3. Semántica de códigos escaneados (especifícalo, no lo dejes al azar)

El escáner debe aceptar **QR y códigos de barras 1D** (EAN-13, EAN-8, UPC-A, Code-128) y resolver en este orden:

1. Si el texto coincide con `inv://p/{uuid}` → es un QR generado por la app; resolver por UUID.
2. Si coincide con un `codigo_barras` registrado → resolver ese producto.
3. Si coincide con un `sku` → resolver ese producto.
4. Si no coincide con nada → ofrecer **«Crear producto con este código»** o **«Reintentar»**, sin sacar al
   usuario de la cámara.

Un producto puede tener **varios códigos** (`producto_codigos`): la caja de 12 y la unidad suelta traen EAN distintos.

### 4. Dinero y unidades (reglas duras)

- Servidor: `DECIMAL(14,2)`. Cliente: **enteros en unidades mínimas** (centavos). **Prohibido `double` para dinero.**
- Precio de venta con **IVA incluido**; el ticket desglosa base e impuesto. Tasas soportadas: 0 %, 5 %, 19 %.
- Redondeo `HALF_UP` a la unidad mínima de la moneda (COP: al peso).
- Cantidades en `DECIMAL(14,3)` para permitir venta por peso.

### 5. Arquitectura técnica

- **Frontend**: Flutter (Android primero, código listo para iOS). **Clean architecture por feature**
  (`domain` / `data` / `presentation`), con `domain` sin dependencias de Flutter ni de red.
- **Backend**: **Node.js 22 + Express 5**. Justifica la elección en dos líneas y no ofrezcas alternativas falsas.
- **BD servidor**: **MariaDB 11.4** (verifica la versión real antes de escribir DDL; no asumas MySQL 8).
  Fuerza `sql_mode = STRICT_TRANS_TABLES,ONLY_FULL_GROUP_BY,NO_ENGINE_SUBSTITUTION` por sesión.
- **BD local**: SQLite vía **Drift**, con migraciones versionadas.
- **Estado**: **Riverpod 3** en todo el proyecto (sin mezclar con Bloc/Provider).
- **Auth**: JWT de acceso (15 min) + refresh rotativo (30 días, revocable en servidor). **Argon2id** para
  contraseñas. Desbloqueo offline con hash local y ventana de gracia configurable (por defecto 7 días).
- Entrega el **ERD y el `schema.sql` antes** de cualquier código de aplicación.

### 6. Patrones de UX que debes aplicar (con justificación, sin fingir investigación de campo)

No afirmes haber «investigado» apps que no puedes ejecutar. En su lugar, **aplica y justifica** estos patrones
consolidados del sector POS:

- **Escáner de cámara siempre viva**: tras cada detección la cámara **no se cierra**; el resultado aparece en una
  hoja inferior sobre el visor. Vender 20 artículos no puede costar 20 aperturas de cámara.
- **Detección con confirmación implícita**: háptico + marco verde + inserción inmediata en el carrito, con
  «Deshacer» durante 4 s. Es más rápido que un diálogo «¿Confirmar?» por artículo.
- **Deduplicación de escaneo**: ignorar el mismo código durante 1,2 s para no leerlo 30 veces por segundo.
- **Dashboard de acciones, no de vanidad**: lo primero en pantalla son *Vender* y *Entrada*; después alertas de
  stock bajo; los gráficos van al final.
- **Indicador de sincronización permanente**: chip visible con estado (`Sin conexión` / `N pendientes` / `Al día`).
  El usuario debe saber siempre si su venta ya salió del dispositivo. **Este es el patrón más importante de toda la app.**

### 7. Criterios de aceptación (medibles; sin esto, nada está «terminado»)

1. Con el **modo avión activado** desde el arranque: se inicia sesión, se venden 3 productos y se imprime el
   ticket. Al reactivar la red, las ventas aparecen en MariaDB **sin duplicados**.
2. Enviar la misma venta **dos veces** con el mismo `client_op_id` deja **una sola** fila y **un solo** descuento de stock.
3. Matar la app a mitad del envío de la outbox no pierde ni duplica ventas al reabrir.
4. Búsqueda en catálogo de **10.000 productos** responde en **< 100 ms** en local.
5. Del escaneo detectado a la fila visible en el carrito: **< 400 ms**.
6. `flutter analyze` sin advertencias; pruebas unitarias del motor de sincronización y del cálculo monetario.
7. Rotar el dispositivo o cambiar a tema oscuro no rompe ningún layout.

### 8. Entregables

1. `docs/ARQUITECTURA.md` — ERD (mermaid), diagrama del flujo de sincronización y decisiones justificadas.
2. `database/schema.sql` + migraciones numeradas + `seeds.sql`.
3. `backend/` — API documentada endpoint por endpoint, con `.env.example`.
4. `mobile/` — app Flutter con la estructura por features.
5. `README.md` — puesta en marcha reproducible y **guía para probar el modo offline**.

Construye en este orden y no lo alteres: **esquema → backend → contrato de sincronización → núcleo Flutter →
features → pulido visual**. En cada paso explica brevemente qué archivos creaste y por qué.

### 9. Reglas de honestidad técnica

- Si algo no lo puedes verificar (compilar el APK, probar en un dispositivo físico), **dilo explícitamente**
  en lugar de afirmar que funciona.
- Si una librería sugerida está obsoleta o es incompatible con la versión estable actual, **corrígela y avisa**.
- Verifica las versiones reales de los paquetes contra pub.dev antes de escribir el `pubspec.yaml`.

---

> Fin del prompt mejorado.
