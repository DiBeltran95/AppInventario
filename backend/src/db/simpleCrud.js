/**
 * Repositorio genérico para tablas de catálogo simples (categorías,
 * proveedores): uuid + campos planos + borrado lógico.
 *
 * Los nombres de tabla y columna vienen SIEMPRE de constantes del código, nunca
 * de la petición, así que la interpolación en el SQL no es una vía de inyección.
 * Los valores van siempre parametrizados.
 */
import { query, queryOne } from './pool.js';
import { txQueryOne, txExecute } from './tx.js';
import { nuevoUuid } from '../utils/ids.js';
import { notFound, badRequest } from '../utils/ApiError.js';

export function crearRepositorioSimple({ tabla, campos, camposBusqueda = [], orden = 'nombre' }) {
  const columnas = ['uuid', ...campos, 'created_at', 'updated_at'].join(', ');

  return {
    async listar({ buscar = null, incluirEliminados = false } = {}) {
      const where = [];
      const params = [];
      if (!incluirEliminados) where.push('deleted_at IS NULL');
      if (buscar && camposBusqueda.length) {
        where.push(`(${camposBusqueda.map((c) => `${c} LIKE ?`).join(' OR ')})`);
        camposBusqueda.forEach(() => params.push(`%${buscar}%`));
      }
      const sql = `SELECT ${columnas} FROM ${tabla}
                   ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
                   ORDER BY ${orden} LIMIT 1000`;
      return query(sql, params);
    },

    async obtener(uuid) {
      const fila = await queryOne(
        `SELECT ${columnas} FROM ${tabla} WHERE uuid = ? AND deleted_at IS NULL`,
        [uuid],
      );
      if (!fila) throw notFound(tabla);
      return fila;
    },

    async crear(conn, datos) {
      const uuid = datos.uuid ?? nuevoUuid();
      const usados = campos.filter((c) => datos[c] !== undefined);
      await txExecute(
        conn,
        `INSERT INTO ${tabla} (uuid${usados.length ? `, ${usados.join(', ')}` : ''})
         VALUES (?${usados.map(() => ', ?').join('')})`,
        [uuid, ...usados.map((c) => datos[c])],
      );
      return txQueryOne(conn, `SELECT ${columnas} FROM ${tabla} WHERE uuid = ?`, [uuid]);
    },

    /**
     * Upsert idempotente: si el uuid ya existe se actualiza en lugar de fallar.
     * Lo necesita la sincronización, donde un reenvío del mismo alta debe
     * converger al mismo estado en vez de devolver "duplicado".
     */
    async crearOActualizar(conn, datos) {
      const existe = await txQueryOne(conn, `SELECT id FROM ${tabla} WHERE uuid = ?`, [datos.uuid]);
      if (existe) return this.actualizar(conn, datos.uuid, datos);
      return this.crear(conn, datos);
    },

    async actualizar(conn, uuid, datos) {
      const usados = campos.filter((c) => datos[c] !== undefined);
      if (!usados.length) throw badRequest('SIN_CAMBIOS', 'No se envió ningún campo a modificar');
      const fila = await txQueryOne(conn, `SELECT id FROM ${tabla} WHERE uuid = ?`, [uuid]);
      if (!fila) throw notFound(tabla);
      await txExecute(
        conn,
        `UPDATE ${tabla} SET ${usados.map((c) => `${c} = ?`).join(', ')}, deleted_at = NULL WHERE id = ?`,
        [...usados.map((c) => datos[c]), fila.id],
      );
      return txQueryOne(conn, `SELECT ${columnas} FROM ${tabla} WHERE id = ?`, [fila.id]);
    },

    /** Borrado lógico: un DELETE físico jamás llegaría al dispositivo offline. */
    async eliminar(conn, uuid) {
      const fila = await txQueryOne(conn, `SELECT id FROM ${tabla} WHERE uuid = ?`, [uuid]);
      if (!fila) throw notFound(tabla);
      await txExecute(
        conn,
        `UPDATE ${tabla} SET deleted_at = UTC_TIMESTAMP(3) WHERE id = ? AND deleted_at IS NULL`,
        [fila.id],
      );
      return { uuid, eliminado: true };
    },
  };
}
