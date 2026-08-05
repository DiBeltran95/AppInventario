# Despliegue del backend en alwaysdata

Guía específica del alojamiento actual: `https://inventarios.alwaysdata.net`.

---

## 1. El error 502 «Connection to upstream failed»

Es el fallo más frecuente y **casi nunca es del código**. Significa que el proxy de alwaysdata
(`alproxy`) está vivo y recibió tu petición, pero no encontró a nadie escuchando al otro lado.

Sólo hay tres causas posibles:

| Causa | Cómo se reconoce | Solución |
|---|---|---|
| **El proceso no está corriendo** | Arrancaste `npm start` a mano por SSH y cerraste la sesión. El log muestra el arranque pero nada después. | Configúralo como *sitio* en el panel para que alwaysdata lo mantenga vivo y lo reinicie solo (§2). |
| **Puerto distinto** | El log dice `escuchando en …:8100` pero el sitio del panel apunta a otro puerto. | Que coincidan el campo «Puerto» del panel y `PORT` del `.env` del servidor. |
| **El proceso murió al arrancar** | El log termina en un error de Node en vez de en «API escuchando». | Mira los logs y §4. |

Comprobación desde tu máquina:

```bash
curl -i https://inventarios.alwaysdata.net/health
```

- `200` con `{"data":{"ok":true,…}}` → funcionando.
- `502` → ninguna de las tres cosas de arriba está en orden.

---

## 2. Configuración del sitio en el panel

**Web → Sitios → Añadir un sitio**

| Campo | Valor |
|---|---|
| Direcciones | `inventarios.alwaysdata.net` |
| Tipo | **Programa de usuario** (*User program*) |
| Comando | `/usr/local/alwaysdata/bin/npm --prefix /home/<cuenta>/www/AppInventario/backend start` |
| Directorio de trabajo | `/home/<cuenta>/www/AppInventario/backend` |
| Puerto | el mismo que `PORT` en el `.env` del servidor |

Lo importante del tipo «Programa de usuario» es que alwaysdata **supervisa** el proceso: lo arranca
al desplegar y lo reinicia si se cae. Un `npm start` lanzado por SSH muere con la sesión, y ésa es
la causa nº 1 del 502.

El código ya hace el bind correcto (`0.0.0.0` en `src/server.js`), así que el proxy lo alcanza en
cuanto el puerto cuadre.

---

## 3. Variables de entorno en el servidor

El `.env` **no viaja en el repositorio** (contiene credenciales). Hay que crearlo en el servidor a
partir de `backend/.env.example`.

Valores que **deben** cambiar respecto al ejemplo de desarrollo:

```bash
NODE_ENV=production                                  # ← ver el aviso de abajo
PORT=<el mismo puerto del panel>
PUBLIC_BASE_URL=https://inventarios.alwaysdata.net   # https, no http
CORS_ORIGINS=https://inventarios.alwaysdata.net

DB_HOST=mysql-inventarios.alwaysdata.net
DB_USER=<usuario>
DB_PASSWORD=<contraseña>
DB_NAME=<base>

JWT_ACCESS_SECRET=<48 bytes aleatorios>
JWT_REFRESH_SECRET=<otros 48 bytes, distintos>
```

Genera cada secreto con:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

> **`NODE_ENV=production` no es cosmético.** Tu log actual sale con colores ANSI, lo que demuestra
> que el servidor está en modo desarrollo: el logger usa `pino-pretty`, que es una
> **devDependency**. En cuanto instales con `npm ci --omit=dev` —lo normal en producción— el
> paquete no estará y **el proceso morirá al arrancar**. En producción el logger emite JSON y no
> necesita nada extra.

---

## 4. Despliegue paso a paso

```bash
ssh <cuenta>@ssh-<cuenta>.alwaysdata.net

cd ~/www
git clone https://github.com/DiBeltran95/AppInventario.git
cd AppInventario/backend

npm ci --omit=dev          # sin devDependencies: exige NODE_ENV=production

cp .env.example .env
nano .env                  # rellena lo de §3

npm run db:migrate         # crea el esquema
npm run db:seed -- --password "TuClaveSegura"
npm run db:check           # verifica invariantes: triggers, append-only, modo estricto
```

Después, en el panel: **Sitios → tu sitio → Reiniciar**.

Para actualizar más adelante:

```bash
cd ~/www/AppInventario && git pull && cd backend && npm ci --omit=dev
# y reiniciar el sitio desde el panel
```

---

## 5. Comprobación final

```bash
# 1. Salud
curl https://inventarios.alwaysdata.net/health

# 2. Login (usa la contraseña que pasaste a db:seed)
curl -X POST https://inventarios.alwaysdata.net/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@inventario.local","password":"TuClaveSegura"}'
```

Si el login devuelve `access_token`, el backend está listo y la app puede entrar: apunta por
defecto a `https://inventarios.alwaysdata.net` sin que haya que tocar nada.

---

## 6. Seguridad mínima antes de usarlo de verdad

- [ ] Cambiar la contraseña del usuario `admin@inventario.local` que creó el seed.
- [ ] `JWT_ACCESS_SECRET` y `JWT_REFRESH_SECRET` distintos entre sí y aleatorios de verdad.
- [ ] `NODE_ENV=production`.
- [ ] Usar siempre **https** en la app (ya es el valor por defecto).
- [ ] Que el `.env` no acabe nunca en el repositorio (ya está en `.gitignore`).
