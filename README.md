# Inventario POS — inventario y punto de venta offline-first

App Android de gestión de inventario y punto de venta con escaneo de códigos, que **opera al 100 %
sin conexión** y sincroniza cuando la recupera.

> **La red es una optimización, nunca un requisito de funcionamiento.** El dispositivo puede iniciar
> sesión, buscar en el catálogo completo, registrar entradas, vender, imprimir el ticket y ver los
> reportes del día sin una sola petición HTTP. La interfaz lee SQLite; la red sólo alimenta SQLite.

| Capa | Tecnología | Verificado en este entorno |
|---|---|---|
| Móvil | Flutter 3.44.1 · Dart 3.12.1 · Riverpod 3 · Drift (SQLite) | ✅ `flutter analyze` sin avisos · 15 pruebas |
| Backend | Node.js 22.20 · Express 5 | ✅ 14 pruebas · lint de transacciones |
| Base de datos | **MariaDB 11.4.12** (no MySQL — ver `docs/ARQUITECTURA.md` §7) | ⚠️ requiere credenciales reales |

---

## Estructura

```
inventario/
├── .github/workflows/  build.yml — compila APK e IPA en la nube
├── docs/               ARQUITECTURA.md · API.md · DESPLIEGUE.md · PROMPT_MEJORADO.md
├── database/           schema.sql  (+ migrations/ opcional, numeradas)
├── backend/            API REST — Node 22 + Express 5 + MariaDB
└── mobile/             App Flutter (Android + iOS)
```

Documentación de referencia:

- **[docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)** — ERD, protocolo de sincronización, política de
  conflictos y decisiones justificadas.
- **[docs/API.md](docs/API.md)** — la API endpoint por endpoint.
- **[docs/DESPLIEGUE.md](docs/DESPLIEGUE.md)** — puesta en producción en alwaysdata y diagnóstico
  del error 502.
- **[docs/PROMPT_MEJORADO.md](docs/PROMPT_MEJORADO.md)** — análisis del encargo original y los
  22 huecos que hubo que cerrar antes de escribir código.

---

## 1. Puesta en marcha del backend

Requisitos: **Node.js ≥ 20.11** y una base **MariaDB 11.4** accesible.

```bash
cd backend
npm install
cp .env.example .env
```

Edita `.env` con los datos reales de tu base y genera los secretos JWT:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Crea el esquema y los datos de arranque:

```bash
npm run db:migrate
npm run db:seed -- --password "TuClaveSegura"
```

`db:seed` imprime al final las credenciales creadas (por defecto `admin@inventario.local`).

Comprueba que el motor cumple las invariantes del modelo —triggers de stock, libro append-only,
modo estricto, `DECIMAL` como string— antes de confiar en él:

```bash
npm run db:check
```

Arranca:

```bash
npm run dev
```

La API queda en `http://localhost:3100/api/v1` y responde a `GET /health`.

**Comprobaciones que no necesitan base de datos:**

```bash
npm run lint:tx   # ninguna consulta transaccional se escapa de su conexión
npm test          # aritmética monetaria del servidor
```

---

## 2. Puesta en marcha de la app

Requisitos: **Flutter 3.44+** y el SDK de Android con `cmdline-tools`.

```bash
cd mobile
flutter pub get
flutter run
```

La app apunta por defecto a **`https://inventarios.alwaysdata.net`**, así que un APK recién
instalado funciona sin tocar nada.

**La URL no está fijada en el binario**: se cambia desde la propia app (login → «Configurar
servidor», o Ajustes → «Dirección de la API») y queda guardada en el almacén seguro. Para
desarrollar contra un backend local:

| Dónde corre la app | URL del backend local |
|---|---|
| Emulador de Android | `http://10.0.2.2:3100` ← el emulador *es* `localhost` |
| Dispositivo físico por USB/wifi | `http://<IP-de-tu-PC>:3100` |

También se puede fijar al compilar:

```bash
flutter build apk --dart-define=API_URL=http://10.0.2.2:3100
```

El HTTP en claro sólo está habilitado en la compilación **debug**
(`android/app/src/debug/AndroidManifest.xml`). En release, Android bloquea el tráfico sin cifrar:
por eso el servidor de producción va por HTTPS.

Verificación de la app:

```bash
flutter analyze   # debe terminar sin avisos
flutter test      # aritmética monetaria del cliente
```

---

## 3. Compilar los binarios (GitHub Actions)

No hace falta tener el SDK de Android ni un Mac: el workflow
[`.github/workflows/build.yml`](.github/workflows/build.yml) lo hace en la nube.

**Actions → Build → Run workflow**, o automáticamente en cada push a `main`.

El entregable es el **IPA de iOS**. Todo ocurre en un único trabajo, en este orden:

```
análisis  →  pruebas  →  compilar  →  empaquetar .ipa
```

Si el análisis o las pruebas fallan, no se compila: un binario que no pasa sus propias pruebas no
vale la pena empaquetarlo.

Verificar y compilar van juntos —y no en dos trabajos encadenados— porque así se pide **un solo
runner**. Cada trabajo extra es otra oportunidad de quedarse esperando máquina cuando GitHub anda
mal, y con dos hacían falta dos aciertos seguidos para obtener el IPA.

| Artefacto | Cuándo | Se instala |
|---|---|---|
| `ios-ipa-sin-firmar` | en cada ejecución | ❌ requiere firmarlo antes |
| `android-apk` | sólo marcando la casilla en *Run workflow* | ✅ directo en el teléfono |

El APK sigue disponible a petición porque es la forma práctica de probar la app en un móvil: se
instala directo y no caduca, al revés que el IPA sin firmar.

### Alternativa cuando GitHub Actions no responde

El repositorio incluye [`codemagic.yaml`](codemagic.yaml), que compila lo mismo en
[Codemagic](https://codemagic.io) —un CI pensado para Flutter, con minutos de macOS en su plan
gratuito—. No hace falta tocar nada del proyecto:

1. Entra en codemagic.io con tu cuenta de GitHub.
2. *Add application* → **AppInventario** → Flutter App.
3. Detecta el archivo solo. Elige `android` o `ios` y pulsa *Start new build*.

Sirve para no quedarse bloqueado cuando Actions tiene una incidencia: **el IPA sólo puede salir de
un Mac**, así que sin un runner de macOS disponible no hay forma de generarlo.

### Cuando los trabajos salen «cancelled» sin ejecutar ningún paso

Si en la página del run los trabajos aparecen cancelados y **no tienen ni un paso** dentro, no es un
fallo de compilación: nunca consiguieron un runner. Se reconoce porque el trabajo no muestra
«Set up job» y la ejecución entera muere a los ~15 minutos.

Dos causas, en este orden:

1. **Una incidencia de GitHub.** Míralo en [githubstatus.com](https://www.githubstatus.com). Cuando
   Actions está caído, los trabajos quedan en cola y se cancelan solos. No hay nada que arreglar en
   el repositorio: se relanza cuando se restablezca.
2. **Cuota de Actions agotada** (*Settings → Billing*). En repositorios privados hay minutos
   mensuales, y macOS consume **10 por cada minuto real**; al agotarlos GitHub cancela todas las
   ejecuciones. En repositorios **públicos** los runners estándar son gratis e ilimitados.

En ninguno de los dos casos ayuda tocar el workflow.

### Sobre la firma

- **Android**: el APK se firma con la clave de **depuración**. Instala y funciona para probar, pero
  Play Store no lo acepta. Para publicar hay que generar un keystore propio y guardarlo en los
  secretos del repositorio.
- **iOS**: se compila con `--no-codesign` porque firmar exige una cuenta de desarrollador de Apple
  (de pago). El `.ipa` resultante **no se instala tal cual en un iPhone**: hay que firmarlo antes
  con Xcode, Sideloadly o AltStore. Sin cuenta de Apple no hay forma de evitar este paso.

### Instalar el `.ipa` en un iPhone con una cuenta gratuita

Sideloadly firma el `.ipa` con tu Apple ID. Con una cuenta **gratuita** (*personal team*), Apple
impone tres límites que no se pueden esquivar:

| Límite | Cuenta gratuita | Apple Developer Program (99 USD/año) |
|---|---|---|
| Apps instaladas a la vez | **3** | 100+ dispositivos |
| Duración de la firma | **7 días** | 1 año |
| App IDs nuevos | 10 cada 7 días | sin límite práctico |

**Error `ApplicationVerificationFailed` — «maximum number of installed apps»**

```
This device has reached the maximum number of installed apps
using a free developer profile
```

No es un problema del `.ipa`: de hecho significa que se firmó bien y falló en la verificación
final. Ya tienes 3 apps sideloadeadas ocupando los cupos —el propio error las lista—. **Borra una
del iPhone y pulsa Retry.**

**A los 7 días la app dejará de abrir.** Hay que volver a pasarla por Sideloadly. Para uso real en
un mostrador esto no sirve: hace falta la cuenta de pago, o distribuir por TestFlight.

Para probar la app sin estas fricciones, usa Android: el APK se instala directo y no caduca.

---

## 4. Cómo probar el modo offline

Es el criterio de aceptación central del proyecto. Requiere un dispositivo o emulador real.

### Prueba A — vender entero en modo avión

1. Con red, inicia sesión una primera vez y espera a que el chip de sincronización diga **«Al día»**.
   Esta primera vez es obligatoria: baja el catálogo y guarda el derivado local de la contraseña.
2. **Activa el modo avión.**
3. Cierra la app por completo y vuelve a abrirla. Debe entrar al dashboard sin pantallas de carga.
   Si pide credenciales, entra: el desbloqueo se valida contra el hash local.
4. Escanea y vende **3 productos**. Cobra en efectivo e imprime o comparte el ticket.
5. Observa el chip de sincronización: dirá **«Sin conexión»**, y las ventas aparecerán marcadas
   «sin enviar» en el historial. Los reportes del día ya reflejan las ventas.
6. **Desactiva el modo avión.** En segundos el chip pasa a «Sincronizando…» y luego a «Al día».
7. Comprueba en MariaDB que las tres ventas llegaron **sin duplicados**:

```sql
SELECT numero, total, creada_offline, fecha FROM ventas ORDER BY id DESC LIMIT 5;
```

### Prueba B — idempotencia (el reintento no cobra dos veces)

El escenario que arruina un POS: la venta llega al servidor, la respuesta se pierde por un corte de
señal, y el cliente reintenta.

```bash
# Reenvía la MISMA operación dos veces con el mismo client_op_id
curl -X POST http://localhost:3100/api/v1/sync/push \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"operations":[{"client_op_id":"<uuid-fijo>","tipo":"VENTA_CREAR","entidad_uuid":"<uuid>","payload":{…}}]}'
```

Resultado correcto: **una sola fila** en `ventas` y **un solo** descuento de stock. La segunda
respuesta es la guardada, no un efecto nuevo.

### Prueba C — la app muere a mitad del envío

Fuerza el cierre de la app mientras sincroniza (o mata el proceso). Al reabrir, las operaciones que
quedaron en `ENVIANDO` vuelven a `PENDIENTE` y se reenvían. Gracias al `client_op_id`, reenviarlas
es seguro: no se pierde ni se duplica ninguna venta.

### Prueba D — sobreventa entre dos dispositivos

Con dos equipos sin conexión, vende la última unidad de un producto en **ambos**. Al reconectar,
**las dos ventas se aceptan**, el stock queda en negativo y el servidor levanta una alerta de
sobreventa. Rechazar la segunda descuadraría la caja contra mercancía ya entregada; es la misma
conducta que Square o Shopify POS.

---

## 5. Roles

| | ADMIN | VENDEDOR |
|---|:---:|:---:|
| Vender y consultar el catálogo | ✅ | ✅ |
| Registrar entradas y ajustes | ✅ | ✅ |
| Crear, editar y dar de baja productos | ✅ | ❌ |
| Ver costos, márgenes y valorización | ✅ | ❌ |
| Anular ventas | ✅ | ❌ |

El vendedor no ve costos ni márgenes: es información sensible del negocio que no necesita para
despachar.

---

## 6. Qué está verificado y qué no

Este proyecto se construyó en un entorno sin dispositivo Android ni base de datos de producción
accesible. Para no vender humo:

**Verificado ejecutando:**

- `flutter analyze` sobre la app completa: **0 avisos**.
- `flutter test`: 15 pruebas de aritmética monetaria (redondeo HALF_UP, desglose de IVA con la
  invariante `base + impuesto == total`, venta por peso).
- `npm test` en el backend: 14 pruebas equivalentes, para que cliente y servidor calculen el mismo
  total al centavo.
- `npm run lint:tx`: ninguna consulta transaccional se ejecuta fuera de su conexión.
- Las APIs de `mobile_scanner`, `pdf`, `qr_flutter`, `fl_chart` y `riverpod` se contrastaron contra
  el código de los paquetes instalados, no de memoria.

**No verificado (requiere hardware o credenciales que no había):**

- **Compilación del APK.** El SDK de Android de esta máquina no tiene `cmdline-tools` y Gradle no
  logra abrir su conexión de loopback, así que `flutter build apk` no llega a ejecutarse. El código
  Dart analiza limpio, pero el ensamblado nativo está sin comprobar.
- **Escaneo real con cámara**, feedback háptico y los presupuestos de tiempo (escaneo → carrito
  < 400 ms).
- **Impresión física** del ticket en una térmica de 80 mm (el PDF se genera; no se ha impreso).
- **`npm run db:check` y `db:migrate` contra MariaDB**: no había credenciales válidas.
- Las **pruebas offline de la sección 3**: exigen un dispositivo real.

**Pendiente de implementar:**

- **Subida de las fotos de producto al servidor.** La foto se toma, se guarda en el dispositivo y se
  muestra en el catálogo, pero no viaja en la cola de sincronización: no existe una operación
  `IMAGEN_SUBIR` en la outbox. El backend ya expone el módulo de uploads; falta conectar los dos
  extremos.
- Gestión de categorías y proveedores desde la app (llegan por sincronización; se administran desde
  la API).
