import jwt from 'jsonwebtoken';
import * as argon2 from '@node-rs/argon2';
import { env } from '../../config/env.js';
import { query, queryOne } from '../../db/pool.js';
import { withTransaction, txQuery, txQueryOne, txExecute } from '../../db/tx.js';
import { nuevoUuid, sha256, tokenAleatorio, prefijoFolioAleatorio } from '../../utils/ids.js';
import { unauthorized, notFound, badRequest, conflict } from '../../utils/ApiError.js';
import { logger } from '../../utils/logger.js';

/**
 * Parámetros de Argon2id.
 *
 * 19 MiB / 2 iteraciones / paralelismo 1 son los mínimos recomendados por OWASP
 * (2024) para argon2id. Se elige argon2id y no bcrypt porque resiste ataques
 * con GPU y ASIC gracias al coste en memoria, cosa que bcrypt no hace.
 */
const ARGON = { memoryCost: 19_456, timeCost: 2, parallelism: 1 };

export const hashearPassword = (plano) => argon2.hash(plano, ARGON);

export async function verificarPassword(hash, plano) {
  try {
    return await argon2.verify(hash, plano);
  } catch {
    return false;
  }
}

function firmarAccessToken(usuario, dispositivoUuid) {
  return jwt.sign(
    {
      sub: usuario.uuid,
      rol: usuario.rol,
      email: usuario.email,
      dispositivo: dispositivoUuid ?? undefined,
    },
    env.JWT_ACCESS_SECRET,
    { algorithm: 'HS256', expiresIn: env.JWT_ACCESS_TTL, issuer: 'inventario-api' },
  );
}

async function emitirRefreshToken(conn, usuarioId, familia, dispositivoUuid, userAgent) {
  const token = tokenAleatorio(48);
  const expira = new Date(Date.now() + env.JWT_REFRESH_TTL_DAYS * 86_400_000);
  await txExecute(
    conn,
    `INSERT INTO refresh_tokens (usuario_id, token_hash, familia, dispositivo_uuid, user_agent, expires_at)
     VALUES (?,?,?,?,?,?)`,
    [usuarioId, sha256(token), familia, dispositivoUuid ?? null, (userAgent ?? '').slice(0, 255), expira],
  );
  return { token, expira };
}

/**
 * Registra o actualiza el dispositivo y le garantiza un prefijo de folio único.
 *
 * El prefijo es lo que permite que dos cajas sin conexión numeren ventas
 * (A1-000001, B7-000001) sin colisionar al sincronizar.
 */
async function registrarDispositivo(conn, dispositivo, usuarioId) {
  if (!dispositivo) return null;

  const existente = await txQueryOne(
    conn,
    'SELECT id, prefijo_folio FROM dispositivos WHERE uuid = ?',
    [dispositivo.uuid],
  );

  if (existente) {
    await txExecute(
      conn,
      `UPDATE dispositivos
          SET usuario_id = ?, nombre = ?, plataforma = ?, app_version = ?, activo = 1, deleted_at = NULL
        WHERE id = ?`,
      [
        usuarioId,
        dispositivo.nombre,
        dispositivo.plataforma ?? null,
        dispositivo.app_version ?? null,
        existente.id,
      ],
    );
    return existente.prefijo_folio;
  }

  // Prefijo aleatorio con reintento; se alarga si el espacio de 2 caracteres
  // empieza a saturarse (más de ~500 dispositivos).
  for (let intento = 0; intento < 12; intento += 1) {
    const longitud = intento < 8 ? 2 : 3;
    const prefijo = prefijoFolioAleatorio(longitud);
    try {
      await txExecute(
        conn,
        `INSERT INTO dispositivos (uuid, usuario_id, nombre, plataforma, app_version, prefijo_folio)
         VALUES (?,?,?,?,?,?)`,
        [
          dispositivo.uuid,
          usuarioId,
          dispositivo.nombre,
          dispositivo.plataforma ?? null,
          dispositivo.app_version ?? null,
          prefijo,
        ],
      );
      return prefijo;
    } catch (err) {
      if (err.code !== 'ER_DUP_ENTRY') throw err;
      if (err.sqlMessage?.includes('uk_dispositivos_uuid')) {
        // Carrera con otro login del mismo dispositivo: relee y usa el suyo.
        const otro = await txQueryOne(
          conn,
          'SELECT prefijo_folio FROM dispositivos WHERE uuid = ?',
          [dispositivo.uuid],
        );
        if (otro) return otro.prefijo_folio;
      }
      // Prefijo ocupado: siguiente intento.
    }
  }
  throw conflict('SIN_PREFIJO', 'No se pudo asignar un prefijo de folio al dispositivo');
}

function perfilPublico(u) {
  return { uuid: u.uuid, nombre: u.nombre, email: u.email, rol: u.rol, activo: !!u.activo };
}

export async function login({ email, password, dispositivo }, userAgent) {
  const usuario = await queryOne(
    'SELECT id, uuid, nombre, email, password_hash, rol, activo FROM usuarios WHERE email = ? AND deleted_at IS NULL',
    [email],
  );

  // Se verifica siempre contra un hash (real o señuelo) para que el tiempo de
  // respuesta no revele si el correo existe.
  const hashSenuelo = '$argon2id$v=19$m=19456,t=2,p=1$c2FsdHNhbHRzYWx0c2E$0000000000000000000000000000000000000000000';
  const valida = await verificarPassword(usuario?.password_hash ?? hashSenuelo, password);

  if (!usuario || !valida) throw unauthorized('Correo o contraseña incorrectos', 'CREDENCIALES_INVALIDAS');
  if (!usuario.activo) throw unauthorized('La cuenta está desactivada', 'CUENTA_DESACTIVADA');

  return withTransaction(async (conn) => {
    const prefijoFolio = await registrarDispositivo(conn, dispositivo, usuario.id);
    const familia = nuevoUuid();
    const { token: refreshToken, expira } = await emitirRefreshToken(
      conn,
      usuario.id,
      familia,
      dispositivo?.uuid,
      userAgent,
    );

    await txExecute(conn, 'UPDATE usuarios SET ultimo_acceso = UTC_TIMESTAMP(3) WHERE id = ?', [
      usuario.id,
    ]);

    return {
      access_token: firmarAccessToken(usuario, dispositivo?.uuid),
      refresh_token: refreshToken,
      refresh_expira: expira.toISOString(),
      usuario: perfilPublico(usuario),
      dispositivo: dispositivo ? { uuid: dispositivo.uuid, prefijo_folio: prefijoFolio } : null,
      // El cliente usa esto para saber cuántos días puede operar sin volver a
      // ver al servidor antes de exigir una reconexión.
      offline_grace_days: env.OFFLINE_GRACE_DAYS,
      servidor_utc: new Date().toISOString(),
    };
  });
}

/**
 * Rotación de refresh tokens con detección de reutilización.
 *
 * Cada refresh invalida el token usado y emite uno nuevo de la misma familia.
 * Si llega un token ya revocado, significa que alguien clonó la cadena: se
 * revoca la familia entera y ambos (legítimo y atacante) quedan fuera.
 */
export async function refrescar({ refresh_token: recibido, dispositivo }, userAgent) {
  const hash = sha256(recibido);

  /**
   * La revocación de la familia NO puede ir dentro de la transacción.
   *
   * Al detectar el reúso hay que lanzar 401, y `withTransaction` hace rollback
   * ante cualquier excepción: la revocación se desharía junto con el error y la
   * cadena robada seguiría viva. Se anota la familia, se deja que la
   * transacción se revierta —liberando el bloqueo de la fila— y sólo entonces
   * se revoca, ya fuera de ella.
   */
  let familiaComprometida = null;

  try {
    return await withTransaction(async (conn) => {
      const fila = await txQueryOne(
        conn,
        `SELECT rt.id, rt.usuario_id, rt.familia, rt.expires_at, rt.revoked_at,
                u.uuid, u.nombre, u.email, u.rol, u.activo
           FROM refresh_tokens rt
           JOIN usuarios u ON u.id = rt.usuario_id
          WHERE rt.token_hash = ?
          FOR UPDATE`,
        [hash],
      );

      if (!fila) throw unauthorized('Refresh token inválido', 'REFRESH_INVALIDO');

      if (fila.revoked_at) {
        familiaComprometida = { familia: fila.familia, usuario: fila.uuid };
        throw unauthorized('Sesión comprometida; inicia sesión de nuevo', 'REFRESH_REUTILIZADO');
      }

      if (new Date(fila.expires_at).getTime() < Date.now()) {
        throw unauthorized('El refresh token expiró', 'REFRESH_EXPIRADO');
      }
      if (!fila.activo) throw unauthorized('La cuenta está desactivada', 'CUENTA_DESACTIVADA');

      await txExecute(conn, 'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE id = ?', [
        fila.id,
      ]);

      const { token, expira } = await emitirRefreshToken(
        conn,
        fila.usuario_id,
        fila.familia,
        dispositivo?.uuid ?? null,
        userAgent,
      );

      return {
        access_token: firmarAccessToken(fila, dispositivo?.uuid),
        refresh_token: token,
        refresh_expira: expira.toISOString(),
        usuario: perfilPublico(fila),
        servidor_utc: new Date().toISOString(),
      };
    });
  } finally {
    if (familiaComprometida) {
      await query(
        'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE familia = ? AND revoked_at IS NULL',
        [familiaComprometida.familia],
      );
      logger.warn(familiaComprometida, 'Reutilización de refresh token: se revocó la familia completa');
    }
  }
}

export async function logout({ refresh_token: recibido, todos_los_dispositivos }, usuarioId) {
  if (todos_los_dispositivos) {
    await query(
      'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE usuario_id = ? AND revoked_at IS NULL',
      [usuarioId],
    );
    return { cerradas: 'todas' };
  }
  if (!recibido) throw badRequest('FALTA_TOKEN', 'Envía refresh_token o todos_los_dispositivos=true');
  await query(
    'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE token_hash = ? AND usuario_id = ?',
    [sha256(recibido), usuarioId],
  );
  return { cerradas: 1 };
}

export async function cambiarPassword(usuarioId, { password_actual, password_nueva }) {
  const usuario = await queryOne('SELECT id, password_hash FROM usuarios WHERE id = ?', [usuarioId]);
  if (!usuario) throw notFound('Usuario');
  if (!(await verificarPassword(usuario.password_hash, password_actual))) {
    throw unauthorized('La contraseña actual no es correcta', 'PASSWORD_INCORRECTA');
  }

  return withTransaction(async (conn) => {
    await txExecute(conn, 'UPDATE usuarios SET password_hash = ? WHERE id = ?', [
      await hashearPassword(password_nueva),
      usuarioId,
    ]);
    // Cambiar la contraseña cierra todas las sesiones: es el gesto que hace un
    // usuario cuando cree que le robaron la cuenta.
    await txExecute(
      conn,
      'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE usuario_id = ? AND revoked_at IS NULL',
      [usuarioId],
    );
    return { ok: true };
  });
}

// ── Gestión de usuarios (sólo ADMIN) ────────────────────────────────────────

export async function listarUsuarios() {
  return query(
    `SELECT uuid, nombre, email, rol, activo, telefono, ultimo_acceso, created_at, updated_at
       FROM usuarios WHERE deleted_at IS NULL ORDER BY nombre`,
  );
}

export async function crearUsuario(datos) {
  const uuid = datos.uuid ?? nuevoUuid();
  await query(
    `INSERT INTO usuarios (uuid, nombre, email, password_hash, rol, telefono)
     VALUES (?,?,?,?,?,?)`,
    [uuid, datos.nombre, datos.email, await hashearPassword(datos.password), datos.rol, datos.telefono ?? null],
  );
  return queryOne(
    'SELECT uuid, nombre, email, rol, activo, telefono, created_at FROM usuarios WHERE uuid = ?',
    [uuid],
  );
}

export async function actualizarUsuario(uuid, datos, solicitanteId) {
  const usuario = await queryOne('SELECT id FROM usuarios WHERE uuid = ? AND deleted_at IS NULL', [uuid]);
  if (!usuario) throw notFound('Usuario');

  const campos = [];
  const valores = [];
  for (const clave of ['nombre', 'email', 'rol', 'telefono']) {
    if (datos[clave] !== undefined) {
      campos.push(`${clave} = ?`);
      valores.push(datos[clave]);
    }
  }
  if (datos.activo !== undefined) {
    if (usuario.id === solicitanteId && datos.activo === false) {
      throw badRequest('AUTO_DESACTIVACION', 'No puedes desactivar tu propia cuenta');
    }
    campos.push('activo = ?');
    valores.push(datos.activo ? 1 : 0);
  }
  if (datos.password !== undefined) {
    campos.push('password_hash = ?');
    valores.push(await hashearPassword(datos.password));
  }
  if (!campos.length) throw badRequest('SIN_CAMBIOS', 'No se envió ningún campo a modificar');

  valores.push(usuario.id);
  await query(`UPDATE usuarios SET ${campos.join(', ')} WHERE id = ?`, valores);

  if (datos.activo === false || datos.password !== undefined) {
    await query(
      'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE usuario_id = ? AND revoked_at IS NULL',
      [usuario.id],
    );
  }

  return queryOne(
    'SELECT uuid, nombre, email, rol, activo, telefono, updated_at FROM usuarios WHERE id = ?',
    [usuario.id],
  );
}

export async function eliminarUsuario(uuid, solicitanteId) {
  const usuario = await queryOne('SELECT id FROM usuarios WHERE uuid = ? AND deleted_at IS NULL', [uuid]);
  if (!usuario) throw notFound('Usuario');
  if (usuario.id === solicitanteId) {
    throw badRequest('AUTO_ELIMINACION', 'No puedes eliminar tu propia cuenta');
  }

  const [{ n }] = await query(
    "SELECT COUNT(*) n FROM usuarios WHERE rol = 'ADMIN' AND activo = 1 AND deleted_at IS NULL",
  );
  const esAdmin = await queryOne("SELECT 1 x FROM usuarios WHERE id = ? AND rol = 'ADMIN'", [usuario.id]);
  if (esAdmin && n <= 1) {
    throw conflict('ULTIMO_ADMIN', 'No puedes eliminar al único administrador activo');
  }

  // Borrado lógico: las ventas y movimientos históricos deben seguir
  // apuntando a quién los hizo.
  await query('UPDATE usuarios SET deleted_at = UTC_TIMESTAMP(3), activo = 0 WHERE id = ?', [usuario.id]);
  await query(
    'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(3) WHERE usuario_id = ? AND revoked_at IS NULL',
    [usuario.id],
  );
  return { ok: true };
}
