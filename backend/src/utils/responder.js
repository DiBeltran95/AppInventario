/**
 * Envoltorio uniforme de respuestas.
 *
 * Toda respuesta exitosa lleva `data`; las listas añaden `meta`. Los errores
 * llevan `error`. Un formato único permite que el cliente Dart tenga un solo
 * decodificador en lugar de uno por endpoint.
 */
export const ok = (res, data, status = 200) => res.status(status).json({ data });

export const creado = (res, data) => res.status(201).json({ data });

export const lista = (res, items, meta = {}) => res.json({ data: items, meta });

export const paginado = (res, items, { total, pagina, limite }) =>
  res.json({
    data: items,
    meta: {
      total,
      pagina,
      limite,
      paginas: limite > 0 ? Math.ceil(total / limite) : 0,
    },
  });

export const sinContenido = (res) => res.status(204).end();
