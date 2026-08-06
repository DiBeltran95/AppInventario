#!/usr/bin/env node
/**
 * Prueba de humo extremo a extremo contra el servidor en marcha.
 *
 * El caso central es el #6: reenviar la MISMA venta con el mismo
 * `client_op_id`. Si esa prueba pasa, un corte de red a mitad de la
 * sincronización no puede cobrar dos veces ni descontar el doble de stock.
 *
 * Uso:  node scripts/smoke.mjs [http://localhost:3000]
 */
import 'dotenv/config';
import { randomUUID } from 'node:crypto';

const BASE = process.argv[2] ?? `http://localhost:${process.env.PORT ?? 3000}`;
const DISPOSITIVO = randomUUID();

const c = { reset: '\x1b[0m', dim: '\x1b[2m', red: '\x1b[31m', green: '\x1b[32m', cyan: '\x1b[36m', yellow: '\x1b[33m' };

let ok = 0;
let fallos = 0;
let token = null;

function afirmar(condicion, descripcion, detalle = '') {
  if (condicion) {
    console.log(`  ${c.green}✓${c.reset} ${descripcion}`);
    ok += 1;
  } else {
    console.log(`  ${c.red}✗ ${descripcion}${c.reset}${detalle ? `\n      ${c.dim}${detalle}${c.reset}` : ''}`);
    fallos += 1;
  }
}

async function api(metodo, ruta, cuerpo, { esperarError = false } = {}) {
  const r = await fetch(`${BASE}${ruta}`, {
    method: metodo,
    headers: {
      'Content-Type': 'application/json',
      'X-Dispositivo': DISPOSITIVO,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(cuerpo ? { body: JSON.stringify(cuerpo) } : {}),
  });
  const texto = await r.text();
  let json;
  try {
    json = texto ? JSON.parse(texto) : null;
  } catch {
    json = { crudo: texto.slice(0, 300) };
  }
  if (!r.ok && !esperarError) {
    throw new Error(`${metodo} ${ruta} -> ${r.status} ${JSON.stringify(json).slice(0, 400)}`);
  }
  return { status: r.status, json };
}

const seccion = (t) => console.log(`\n${c.cyan}${t}${c.reset}`);

try {
  // ── 1. Salud ──────────────────────────────────────────────────────────────
  seccion('1. Salud del servicio');
  const salud = await api('GET', '/health');
  afirmar(salud.json.ok === true, 'GET /health responde ok');
  afirmar(salud.json.base_datos?.conectada === true, `Base conectada (${salud.json.base_datos?.motor})`);
  afirmar(salud.json.zona_negocio === 'America/Bogota', `Zona de negocio: ${salud.json.zona_negocio}`);

  // ── 2. Autenticación ──────────────────────────────────────────────────────
  seccion('2. Autenticación');
  const malo = await api('POST', '/api/v1/auth/login',
    { email: 'admin@inventario.local', password: 'incorrecta' }, { esperarError: true });
  afirmar(malo.status === 401, 'Contraseña incorrecta -> 401', `status=${malo.status}`);

  const login = await api('POST', '/api/v1/auth/login', {
    email: 'admin@inventario.local',
    password: 'Admin1234',
    dispositivo: { uuid: DISPOSITIVO, nombre: 'Smoke test', plataforma: 'node', app_version: '1.0.0' },
  });
  token = login.json.data.access_token;
  const prefijo = login.json.data.dispositivo?.prefijo_folio;
  afirmar(!!token, 'Login devuelve access_token');
  afirmar(!!login.json.data.refresh_token, 'Login devuelve refresh_token');
  afirmar(!!prefijo, `Dispositivo recibe prefijo de folio: ${prefijo}`);
  afirmar(login.json.data.usuario.rol === 'ADMIN', 'Rol correcto');

  const rot1 = await api('POST', '/api/v1/auth/refresh', { refresh_token: login.json.data.refresh_token });
  afirmar(
    rot1.json.data.refresh_token !== login.json.data.refresh_token,
    'El refresh ROTA el token (no devuelve el mismo)',
  );
  const reuso = await api('POST', '/api/v1/auth/refresh',
    { refresh_token: login.json.data.refresh_token }, { esperarError: true });
  afirmar(reuso.status === 401, 'Reutilizar un refresh revocado -> 401 (detección de robo)');
  const reusoNuevo = await api('POST', '/api/v1/auth/refresh',
    { refresh_token: rot1.json.data.refresh_token }, { esperarError: true });
  afirmar(reusoNuevo.status === 401, 'La familia entera queda revocada tras el reúso');

  // ── 3. Catálogo ───────────────────────────────────────────────────────────
  seccion('3. Catálogo');
  const productos = await api('GET', '/api/v1/productos?limite=100');
  afirmar(productos.json.data.length >= 13, `Lista ${productos.json.data.length} productos`);
  afirmar(typeof productos.json.data[0].precio_venta === 'string', 'El dinero viaja como string, no como number');

  const cola = productos.json.data.find((p) => p.sku === 'BEB-001');
  const arroz = productos.json.data.find((p) => p.sku === 'GRA-001');
  afirmar(!!cola && !!arroz, 'Productos de prueba presentes');

  const porEan = await api('GET', '/api/v1/productos/codigo/7702004003515');
  afirmar(porEan.json.data.sku === 'BEB-001', 'Resolución por código EAN-13');
  afirmar(porEan.json.data.origen === 'CODIGO', `Origen del match: ${porEan.json.data.origen}`);

  const porSku = await api('GET', '/api/v1/productos/codigo/GRA-001');
  afirmar(porSku.json.data.origen === 'SKU', 'Resolución por SKU cuando no hay código registrado');

  const detalle = await api('GET', `/api/v1/productos/${cola.uuid}`);
  afirmar(detalle.json.data.qr_payload === `inv://p/${cola.uuid}`, 'qr_payload con el prefijo inv://p/');

  const porQr = await api('GET', `/api/v1/productos/codigo/${encodeURIComponent(`inv://p/${cola.uuid}`)}`);
  afirmar(porQr.json.data.origen === 'QR_APP', 'Resolución por QR generado por la app');

  const inexistente = await api('GET', '/api/v1/productos/codigo/0000000000000', null, { esperarError: true });
  afirmar(inexistente.status === 404, 'Código desconocido -> 404 (la app ofrece "crear producto")');

  // ── 4. Validación ─────────────────────────────────────────────────────────
  seccion('4. Validación de entrada');
  const invalido = await api('POST', '/api/v1/productos',
    { sku: '', nombre: '', precio_venta: 'abc' }, { esperarError: true });
  afirmar(invalido.status === 400, 'Cuerpo inválido -> 400');
  afirmar(Array.isArray(invalido.json.error?.detalles), 'El error detalla campo por campo');
  afirmar(invalido.json.error?.permanente === true, 'Marcado como permanente (el cliente no debe reintentar)');

  const stockDirecto = await api('PATCH', `/api/v1/productos/${cola.uuid}`,
    { stock_actual: '9999' }, { esperarError: true });
  afirmar(
    stockDirecto.status === 400 && stockDirecto.json.error.codigo === 'STOCK_NO_EDITABLE',
    'Editar stock_actual directamente se rechaza (es derivado)',
  );

  // ── 5. Entrada de inventario ──────────────────────────────────────────────
  seccion('5. Entrada de inventario');
  const stockAntes = Number(cola.stock_actual);
  await api('POST', '/api/v1/inventario/movimientos', {
    producto_uuid: cola.uuid,
    tipo: 'ENTRADA',
    cantidad: '24.000',
    costo_unitario: '1850.00',
    documento_ref: 'FAC-9981',
  });
  const trasEntrada = await api('GET', `/api/v1/productos/${cola.uuid}`);
  afirmar(
    Number(trasEntrada.json.data.stock_actual) === stockAntes + 24,
    `Stock ${stockAntes} + 24 = ${trasEntrada.json.data.stock_actual}`,
  );
  afirmar(trasEntrada.json.data.precio_compra === '1850.00', 'La entrada actualiza el costo de compra');

  // La cantidad negativa en una ENTRADA debe interpretarse como entrada igual:
  // el signo lo impone el tipo, no el cliente.
  await api('POST', '/api/v1/inventario/movimientos', {
    producto_uuid: cola.uuid, tipo: 'ENTRADA', cantidad: '-5.000',
  });
  const trasNegativa = await api('GET', `/api/v1/productos/${cola.uuid}`);
  afirmar(
    Number(trasNegativa.json.data.stock_actual) === stockAntes + 29,
    'Una ENTRADA con cantidad negativa SUMA igual (el tipo impone el signo)',
  );

  // ── 6. IDEMPOTENCIA DE VENTA — la prueba crítica ──────────────────────────
  seccion('6. Venta offline e IDEMPOTENCIA (prueba crítica)');
  // Línea base: esta base de datos es la REAL del negocio y puede tener ventas
  // del día. Comprobar «ventas de hoy === 0» sólo funcionaría con la base
  // recién sembrada, así que se mide el DELTA.
  const ventasHoyBase = Number(
    (await api('GET', '/api/v1/reportes/dashboard')).json.data.resumen.ventas_hoy,
  );
  const stockColaAntes = Number(trasNegativa.json.data.stock_actual);
  const stockArrozAntes = Number(arroz.stock_actual);

  const ventaUuid = randomUUID();
  const opId = randomUUID();
  const operacion = {
    client_op_id: opId,
    tipo: 'VENTA_CREAR',
    payload: {
      uuid: ventaUuid,
      numero: `${prefijo}-000001`,
      metodo_pago: 'EFECTIVO',
      monto_recibido: '20000.00',
      creada_offline: true,
      fecha: new Date().toISOString(),
      lineas: [
        { producto_uuid: cola.uuid, cantidad: '2.000', precio_unitario: '2500.00', tasa_iva: '19.00' },
        { producto_uuid: arroz.uuid, cantidad: '1.000', precio_unitario: '3200.00', tasa_iva: '5.00' },
      ],
    },
  };

  const push1 = await api('POST', '/api/v1/sync/push', { operaciones: [operacion] });
  const r1 = push1.json.data.resultados[0];
  afirmar(r1.estado === 'OK', 'Primer envío: aplicado', JSON.stringify(r1.error ?? {}));
  afirmar(r1.reprocesada === true, 'Primer envío marcado como procesado por primera vez');

  const venta1 = r1.resultado;
  // 2 × 2500 = 5000 con IVA 19 % incluido -> base 4201.68, IVA 798.32
  // 1 × 3200 = 3200 con IVA 5 % incluido  -> base 3047.62, IVA 152.38
  afirmar(venta1.total === '8200.00', `Total = 8200.00 (obtuve ${venta1.total})`);
  afirmar(venta1.impuesto_total === '950.70', `IVA desglosado = 950.70 (obtuve ${venta1.impuesto_total})`);
  afirmar(venta1.subtotal === '7249.30', `Base gravable = 7249.30 (obtuve ${venta1.subtotal})`);
  afirmar(
    (Number(venta1.subtotal) + Number(venta1.impuesto_total)).toFixed(2) === venta1.total,
    'base + IVA === total exactamente (sin centavos perdidos)',
  );
  afirmar(venta1.cambio === '11800.00', `Cambio = 20000 - 8200 = 11800 (obtuve ${venta1.cambio})`);
  afirmar(venta1.numero === `${prefijo}-000001`, 'Conserva el folio generado por el dispositivo');
  afirmar(venta1.detalles[0].descripcion === cola.nombre, 'Guarda snapshot del nombre del producto');

  // ── EL REENVÍO ──
  const push2 = await api('POST', '/api/v1/sync/push', { operaciones: [operacion] });
  const r2 = push2.json.data.resultados[0];
  afirmar(r2.estado === 'OK', 'Reenvío: responde OK (no error)');
  afirmar(r2.idempotente === true, 'Reenvío marcado como IDEMPOTENTE');
  afirmar(r2.reprocesada === false, 'Reenvío NO vuelve a aplicar el efecto');

  const ventas = await api('GET', '/api/v1/ventas?limite=200&estado=todas');
  const coincidencias = ventas.json.data.filter((v) => v.uuid === ventaUuid);
  afirmar(coincidencias.length === 1, `Existe UNA sola venta con ese uuid (hay ${coincidencias.length})`);

  const colaDespues = await api('GET', `/api/v1/productos/${cola.uuid}`);
  const arrozDespues = await api('GET', `/api/v1/productos/${arroz.uuid}`);
  afirmar(
    Number(colaDespues.json.data.stock_actual) === stockColaAntes - 2,
    `Stock descontado UNA vez: ${stockColaAntes} - 2 = ${colaDespues.json.data.stock_actual}`,
  );
  afirmar(
    Number(arrozDespues.json.data.stock_actual) === stockArrozAntes - 1,
    `Arroz descontado UNA vez: ${stockArrozAntes} - 1 = ${arrozDespues.json.data.stock_actual}`,
  );

  // Tres reenvíos concurrentes: la carrera contra la PK de idempotencia.
  const concurrentes = await Promise.all(
    [1, 2, 3].map(() => api('POST', '/api/v1/sync/push', { operaciones: [operacion] })),
  );
  afirmar(
    concurrentes.every((p) => p.json.data.resultados[0].estado === 'OK'),
    'Tres reenvíos simultáneos responden OK',
  );
  const colaTrasCarrera = await api('GET', `/api/v1/productos/${cola.uuid}`);
  afirmar(
    Number(colaTrasCarrera.json.data.stock_actual) === stockColaAntes - 2,
    'El stock sigue descontado UNA sola vez tras la carrera',
  );

  // ── 7. Rechazo permanente ─────────────────────────────────────────────────
  seccion('7. Rechazo permanente en la cola');
  const opMala = {
    client_op_id: randomUUID(),
    tipo: 'VENTA_CREAR',
    payload: { uuid: randomUUID(), lineas: [{ producto_uuid: randomUUID(), cantidad: '1.000' }] },
  };
  const pushMalo = await api('POST', '/api/v1/sync/push', { operaciones: [opMala] });
  const rm = pushMalo.json.data.resultados[0];
  afirmar(rm.estado === 'ERROR', 'Venta con producto inexistente -> ERROR');
  afirmar(rm.error?.permanente === true, 'Marcada como PERMANENTE (sale de la cola, no se reintenta)');
  const pushMalo2 = await api('POST', '/api/v1/sync/push', { operaciones: [opMala] });
  afirmar(
    pushMalo2.json.data.resultados[0].idempotente === true,
    'El rechazo también se memoriza (no se reprocesa infinitamente)',
  );

  // ── 8. Bajada delta ───────────────────────────────────────────────────────
  seccion('8. Sincronización delta (pull)');
  const pull1 = await api('POST', '/api/v1/sync/pull', { cursores: {}, limite: 500 });
  const ents = pull1.json.data.entidades;
  afirmar(ents.productos.items.length >= 13, `Bajada inicial: ${ents.productos.items.length} productos`);
  afirmar(ents.ventas.items.length >= 1, `Bajada inicial: ${ents.ventas.items.length} ventas`);
  afirmar(!!ents.productos.cursor?.t && ents.productos.cursor.i > 0, 'Devuelve cursor keyset (t, i)');
  afirmar(
    ents.productos.items.every((p) => p.categoria_uuid !== undefined && p._id === undefined),
    'Expone UUID de la categoría y oculta los ids internos',
  );
  afirmar(!!ents.configuracion.items.length, 'La configuración viaja completa');

  const pull2 = await api('POST', '/api/v1/sync/pull', { cursores: ents.productos.cursor ? { productos: ents.productos.cursor } : {}, entidades: ['productos'] });
  afirmar(
    pull2.json.data.entidades.productos.items.length === 0,
    `Segunda bajada con el cursor no trae nada (trajo ${pull2.json.data.entidades.productos.items.length})`,
  );

  // Valor distinto en cada ejecución a propósito: MariaDB sólo dispara
  // `ON UPDATE CURRENT_TIMESTAMP` si la fila CAMBIA de verdad. Reescribir el
  // mismo valor no mueve `updated_at` y el delta no traería nada — que es el
  // comportamiento correcto, pero invalidaría esta prueba.
  await api('PATCH', `/api/v1/productos/${arroz.uuid}`, { ubicacion: `Pasillo ${Date.now() % 97}` });
  const pull3 = await api('POST', '/api/v1/sync/pull', { cursores: { productos: ents.productos.cursor }, entidades: ['productos'] });
  afirmar(
    pull3.json.data.entidades.productos.items.length === 1 &&
      pull3.json.data.entidades.productos.items[0].uuid === arroz.uuid,
    'Tras editar, el delta trae exactamente ese producto',
  );

  // Borrado lógico propagado
  const desechable = await api('POST', '/api/v1/productos', {
    sku: `TMP-${Date.now()}`, nombre: 'Producto temporal', precio_venta: '1000.00',
  });
  const cursorTrasAlta = (
    await api('POST', '/api/v1/sync/pull', { cursores: { productos: pull3.json.data.entidades.productos.cursor }, entidades: ['productos'] })
  ).json.data.entidades.productos.cursor;
  await api('DELETE', `/api/v1/productos/${desechable.json.data.uuid}`);
  const pullBorrado = await api('POST', '/api/v1/sync/pull', { cursores: { productos: cursorTrasAlta }, entidades: ['productos'] });
  const borrado = pullBorrado.json.data.entidades.productos.items.find((p) => p.uuid === desechable.json.data.uuid);
  afirmar(!!borrado && borrado.deleted_at !== null, 'El borrado viaja como fila con deleted_at (no desaparece)');

  // ── 9. Anulación ──────────────────────────────────────────────────────────
  seccion('9. Anulación con documento de reversa');
  const stockPreAnul = Number((await api('GET', `/api/v1/productos/${cola.uuid}`)).json.data.stock_actual);
  const anulacion = await api('POST', `/api/v1/ventas/${ventaUuid}/anular`, { motivo: 'Prueba de humo' });
  afirmar(anulacion.json.data.anulada === true, 'Venta anulada');
  afirmar(
    anulacion.json.data.reversa_numero === `${prefijo}-000001-R`,
    `Se emitió reversa ${anulacion.json.data.reversa_numero}`,
  );
  const stockPostAnul = Number((await api('GET', `/api/v1/productos/${cola.uuid}`)).json.data.stock_actual);
  afirmar(stockPostAnul === stockPreAnul + 2, `El stock se devuelve: ${stockPreAnul} + 2 = ${stockPostAnul}`);

  const ventaAnulada = await api('GET', `/api/v1/ventas/${ventaUuid}`);
  afirmar(ventaAnulada.json.data.estado === 'ANULADA', 'La original queda en estado ANULADA');
  afirmar(ventaAnulada.json.data.detalles.length === 2, 'La original conserva sus líneas (no se borró nada)');

  const reAnular = await api('POST', `/api/v1/ventas/${ventaUuid}/anular`, { motivo: 'Otra vez' });
  afirmar(reAnular.json.data.duplicada === true, 'Anular dos veces es idempotente');

  // ── 10. Reportes ──────────────────────────────────────────────────────────
  seccion('10. Reportes');
  const dash = await api('GET', '/api/v1/reportes/dashboard');
  afirmar(typeof dash.json.data.resumen.productos_activos === 'number', 'Dashboard responde');
  afirmar(Array.isArray(dash.json.data.serie_14_dias), 'Incluye serie de 14 días');
  afirmar(Array.isArray(dash.json.data.stock_bajo), `Detecta ${dash.json.data.stock_bajo.length} productos con stock bajo`);
  afirmar(
    Number(dash.json.data.resumen.ventas_hoy) === ventasHoyBase,
    'Tras anular, las ventas de hoy vuelven al valor previo '
      + `(base ${ventasHoyBase}, ahora ${dash.json.data.resumen.ventas_hoy})`,
  );

  const valor = await api('GET', '/api/v1/reportes/valorizacion');
  afirmar(Number(valor.json.data.resumen.valor_costo) > 0, 'Valorización del inventario calculada');

  // ── 11. Roles ─────────────────────────────────────────────────────────────
  seccion('11. Control de acceso por rol');
  const tokenAdmin = token;

  // Se crea un vendedor desechable en lugar de usar el sembrado: su contraseña
  // pudo cambiarse desde la app, y entonces el test fallaría por un motivo que
  // no tiene nada que ver con lo que pretende comprobar.
  const emailVend = `smoke-vendedor-${Date.now()}@inventario.local`;
  const passVend = 'SmokeVend1234';
  const vendCreado = await api('POST', '/api/v1/auth/usuarios', {
    nombre: 'Vendedor de prueba', email: emailVend, password: passVend, rol: 'VENDEDOR',
  });
  afirmar(vendCreado.status === 201, 'ADMIN puede crear un empleado vendedor');
  const uuidVendPrueba = vendCreado.json.data.uuid;

  const loginVend = await api('POST', '/api/v1/auth/login', {
    email: emailVend, password: passVend,
  });
  token = loginVend.json.data.access_token;

  const intentoCrear = await api('POST', '/api/v1/productos',
    { sku: `X-${Date.now()}`, nombre: 'No permitido' }, { esperarError: true });
  afirmar(intentoCrear.status === 403, 'VENDEDOR no puede crear productos -> 403');

  const listaVend = await api('GET', '/api/v1/productos?limite=5');
  afirmar(
    listaVend.json.data.every((p) => p.precio_compra === undefined),
    'VENDEDOR no ve el precio de compra',
  );
  const dashVend = await api('GET', '/api/v1/reportes/dashboard');
  afirmar(
    dashVend.json.data.top_productos_mes.every((p) => p.margen === undefined && p.costo === undefined),
    'VENDEDOR no ve márgenes ni costos en reportes',
  );
  const puedeVender = await api('GET', '/api/v1/productos/codigo/7702004003515');
  afirmar(puedeVender.status === 200, 'VENDEDOR sí puede escanear y consultar');
  token = tokenAdmin;

  // ── 12. Errores ───────────────────────────────────────────────────────────
  seccion('12. Manejo de errores');
  const dup = await api('POST', '/api/v1/productos',
    { sku: 'BEB-001', nombre: 'Duplicado' }, { esperarError: true });
  afirmar(dup.status === 409 && dup.json.error.codigo === 'DUPLICADO', 'SKU duplicado -> 409 con mensaje legible');
  afirmar(/BEB-001/.test(dup.json.error.mensaje), `Mensaje: "${dup.json.error.mensaje}"`);

  const sinAuth = (async () => {
    const r = await fetch(`${BASE}/api/v1/productos`);
    return r.status;
  })();
  afirmar((await sinAuth) === 401, 'Sin token -> 401');

  const noExiste = await api('GET', '/api/v1/nope', null, { esperarError: true });
  afirmar(noExiste.status === 404 && noExiste.json.error.codigo === 'RUTA_NO_ENCONTRADA', 'Ruta inexistente -> 404 con formato de error');

  // ── 13. BARRERA DE ROL EN /sync/push (antifraude) ─────────────────────────
  // Es la prueba más importante de esta sección: las rutas REST llevan
  // `soloAdmin`, pero la app offline-first manda TODO por /sync/push. Si el push
  // no comprobara el rol, la protección entera sería decorativa.
  seccion('13. Barrera de rol en la sincronización');
  const tokenAdmin2 = token;
  const loginV = await api('POST', '/api/v1/auth/login', {
    email: emailVend, password: passVend,
    dispositivo: { uuid: randomUUID(), nombre: 'Caja de prueba', plataforma: 'node' },
  });
  token = loginV.json.data.access_token;

  const prohibidas = [
    ['PRODUCTO_CREAR', { uuid: randomUUID(), sku: `HACK-${Date.now()}`, nombre: 'Producto pirata' }],
    ['MOVIMIENTO_CREAR', { uuid: randomUUID(), producto_uuid: cola.uuid, tipo: 'ENTRADA', cantidad: '500.000' }],
    ['CONTEO_AJUSTAR', { uuid: randomUUID(), producto_uuid: cola.uuid, stock_contado: '0.000' }],
    ['PRODUCTO_ACTUALIZAR', { uuid: cola.uuid, precio_venta: '1.00' }],
    ['VENTA_ANULAR', { venta_uuid: randomUUID(), motivo: 'no deberia poder' }],
  ];

  for (const [tipo, payload] of prohibidas) {
    const r = await api('POST', '/api/v1/sync/push', {
      operaciones: [{ client_op_id: randomUUID(), tipo, payload }],
    });
    const res = r.json.data.resultados[0];
    afirmar(
      res.estado === 'ERROR' && res.error?.codigo === 'SIN_PERMISO',
      `VENDEDOR no puede ${tipo} por sync -> SIN_PERMISO`,
      JSON.stringify(res.error ?? res),
    );
  }

  // Y lo que SÍ debe poder hacer.
  const ventaV = await api('POST', '/api/v1/sync/push', {
    operaciones: [{
      client_op_id: randomUUID(),
      tipo: 'VENTA_CREAR',
      payload: {
        uuid: randomUUID(), metodo_pago: 'EFECTIVO', creada_offline: true,
        lineas: [{ producto_uuid: cola.uuid, cantidad: '1.000', precio_unitario: '2500.00' }],
      },
    }],
  });
  afirmar(
    ventaV.json.data.resultados[0].estado === 'OK',
    'VENDEDOR SÍ puede registrar una venta por sync',
    JSON.stringify(ventaV.json.data.resultados[0].error ?? {}),
  );

  // Las rutas REST equivalentes también.
  const movRest = await api('POST', '/api/v1/inventario/movimientos',
    { producto_uuid: cola.uuid, tipo: 'ENTRADA', cantidad: '99.000' }, { esperarError: true });
  afirmar(movRest.status === 403, 'VENDEDOR no puede cargar inventario por REST -> 403');

  const conteoRest = await api('POST', '/api/v1/inventario/conteo',
    { producto_uuid: cola.uuid, stock_contado: '0.000' }, { esperarError: true });
  afirmar(conteoRest.status === 403, 'VENDEDOR no puede ajustar el conteo -> 403');

  const empleadosV = await api('GET', '/api/v1/reportes/por-empleado', null, { esperarError: true });
  afirmar(empleadosV.status === 403, 'VENDEDOR no ve el control de cajas -> 403');

  token = tokenAdmin2;
  const empleadosA = await api('GET', '/api/v1/reportes/por-empleado?periodo=mes');
  afirmar(Array.isArray(empleadosA.json.data), 'ADMIN sí ve el control de cajas');
  afirmar(
    empleadosA.json.data.some((e) => e.email === emailVend),
    'El reporte incluye al vendedor',
  );
  const filaV = empleadosA.json.data.find((e) => e.email === emailVend);
  afirmar(
    filaV && Number(filaV.num_ventas) >= 1,
    `Registra las ventas del vendedor (${filaV?.num_ventas})`,
  );

  // Limpieza: el vendedor de prueba se da de baja lógica para no ensuciar el
  // control de cajas del negocio.
  await api('DELETE', `/api/v1/auth/usuarios/${uuidVendPrueba}`);
} catch (err) {
  console.error(`\n${c.red}Error no controlado:${c.reset}`, err.message);
  fallos += 1;
}

console.log(
  `\n${fallos === 0 ? c.green : c.red}${ok} pruebas correctas, ${fallos} fallidas${c.reset}\n`,
);
process.exit(fallos === 0 ? 0 : 1);
