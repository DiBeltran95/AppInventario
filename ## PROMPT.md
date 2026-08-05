## PROMPT

Actúa como un arquitecto de software senior y desarrollador Flutter experto en apps móviles profesionales de nivel producción. Vas a diseñar y construir, paso a paso, una aplicación Android de **gestión de inventario con escaneo de códigos QR**, usando **Flutter** en el frontend y **MySQL** como base de datos.

### 1. Contexto y objetivo del negocio
Necesito una app para llevar el inventario de una tienda/negocio. Debe permitir:
- **Alimentar el inventario**: escanear el código QR de un producto (o crearlo si no existe) para registrar entradas de stock, con cantidad, costo, proveedor y fecha.
- **Vender productos**: escanear el QR de un producto para agregarlo a una venta/carrito, descontar del stock automáticamente y generar un comprobante/ticket.
- **Consultar y administrar el catálogo**: crear, editar, eliminar y buscar productos manualmente (nombre, SKU, categoría, precio de compra, precio de venta, stock actual, stock mínimo, imagen, código QR asociado).
- **Reportes básicos**: productos con bajo stock, historial de movimientos (entradas/salidas), ventas del día/semana/mes, producto más vendido.
- **Generar códigos QR**: si un producto no tiene QR físico, la app debe poder generar e imprimir/exportar uno (SKU o ID único codificado).

### 2. Arquitectura técnica (importante)
Flutter (móvil) **no puede conectarse directamente a MySQL** por seguridad y diseño. Por lo tanto, la arquitectura debe ser:

- **Frontend**: Flutter (Android, con posibilidad de extender a iOS a futuro).
- **Backend/API**: una API REST intermedia (proponme la mejor opción entre Node.js + Express, explicando ventajas de cada una para este caso) que exponga endpoints para productos, inventario, ventas, usuarios y reportes.
- **Base de datos**: MySQL, con un esquema relacional normalizado (tablas: productos, categorías, movimientos_inventario, ventas, detalle_ventas, usuarios, proveedores).
- **Autenticación**: JWT para proteger la API, con roles (admin / vendedor).
- Genera primero el **modelo entidad-relación (ERD)** y el script SQL de creación de tablas antes de escribir código de la app.

### 3. Stack y paquetes Flutter sugeridos (evalúa y confirma los mejores según la versión estable actual)
- Escaneo QR: `mobile_scanner` (preferido por rendimiento y mantenimiento activo) o `qr_code_scanner`.
- Generación de QR: `qr_flutter`.
- Gestión de estado: `Riverpod` o `Bloc` (elige uno y sé consistente en todo el proyecto).
- Peticiones HTTP: `dio`.
- Animaciones: `flutter_animate`, `Hero animations`, `Lottie` para microinteracciones (loading, éxito de escaneo, checkout).
- Navegación: `go_router`.
- Manejo de imágenes de producto: `image_picker` + almacenamiento en backend o servicio externo.
- Modo offline básico (opcional pero deseable): `sqflite` o `Hive` como caché local con sincronización posterior.

### 4. Referencias y benchmarking (hazlo antes de codear)
Antes de generar el código, investiga y toma como referencia patrones de UX de apps reales de inventario/POS reconocidas como **Square POS, Shopify POS, Vend, Zoho Inventory y Sortly**, específicamente en:
- Cómo diseñan la pantalla de escaneo (overlay, marco de enfoque, feedback visual/vibración al detectar el código).
- Cómo estructuran el flujo "escanear → confirmar → guardar" sin fricción.
- Cómo muestran el dashboard principal (resumen de stock, alertas, accesos rápidos).

Resume brevemente qué patrones vas a adoptar y por qué antes de empezar a construir las pantallas.

### 5. Requisitos de diseño UI/UX (moderno y profesional)
- Diseño **Material 3**, con tema claro/oscuro, tipografía consistente y una paleta de colores coherente con la identidad de un producto profesional (no colores default de Flutter).
- **Pantalla de escaneo QR**: debe sentirse premium — marco de escaneo animado, línea de escaneo en movimiento, vibración/sonido y animación de confirmación al detectar un código válido, manejo elegante de errores (QR no reconocido, producto no encontrado) con opción de "crear producto nuevo" o "reintentar".
- Transiciones de pantalla suaves (Hero animations entre lista de productos y detalle).
- Micro-animaciones en botones, tarjetas de producto y confirmaciones de venta (checkmarks animados, snackbars personalizados).
- Estados vacíos y de carga diseñados (skeleton loaders, no solo un spinner genérico).
- Diseño responsive para distintos tamaños de pantalla Android.

### 6. Estructura del proyecto que debes generar
1. Diagrama ERD + script SQL (`schema.sql`).
2. Estructura de carpetas del backend (con endpoints documentados).
3. Estructura de carpetas Flutter siguiendo **arquitectura limpia** (`presentation`, `domain`, `data`), separada por features (auth, productos, escaneo, inventario, ventas, reportes).
4. Pantallas principales: Login, Dashboard, Escaneo QR, Detalle/Alta de producto, Lista de inventario, Carrito de venta, Historial de movimientos, Reportes.
5. Manejo de errores y validaciones en formularios.
6. Instrucciones de cómo correr el backend y la app localmente.

### 7. Entregable esperado
Construye el proyecto de forma incremental: primero el backend y la base de datos, luego la app Flutter conectada a él, y al final las animaciones y el pulido visual. En cada paso, explícame brevemente qué archivos creaste y por qué, sin extenderte innecesariamente.

---

### Notas para ti (antes de usar el prompt)
- Si tu backend ya existe o tienes preferencia de lenguaje (Node.js, PHP, Python/FastAPI), acláralo al inicio del prompt para que no lo decida por ti.
- Si el negocio necesita multi-sucursal o multi-usuario simultáneo, agrégalo explícitamente en la sección 1.
- Si quieres soporte offline real (vender sin internet y sincronizar después), profundiza el punto de `sqflite`/`Hive`, porque cambia bastante la arquitectura.