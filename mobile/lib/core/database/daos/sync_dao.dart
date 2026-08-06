import 'package:drift/drift.dart';

import '../../money/money.dart';
import '../app_database.dart';

/// Aplica en la base local lo que llega del servidor y custodia los cursores.
class SyncDao {
  SyncDao(this.db);

  final AppDatabase db;

  // ── Cursores ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> cursores() async {
    final filas = await db.select(db.syncCursores).get();
    return {
      for (final f in filas)
        f.entidad: {'t': f.cursorT.toUtc().toIso8601String(), 'i': f.cursorI},
    };
  }

  Future<void> guardarCursor(String entidad, String iso, int id) async {
    await db.into(db.syncCursores).insertOnConflictUpdate(
          SyncCursoresCompanion.insert(
            entidad: entidad,
            cursorT: DateTime.parse(iso).toUtc(),
            cursorI: Value(id),
            ultimoSync: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> reiniciarCursores() => db.delete(db.syncCursores).go();

  /// Elimina movimientos locales huérfanos de ventas ya bajadas del servidor.
  ///
  /// Corrige dispositivos que sincronizaron con la versión anterior del bug
  /// (venta local + movimiento del servidor con otro uuid).
  Future<int> purgarMovimientosDuplicadosDeVenta() async {
    return db.customUpdate(
      '''
      DELETE FROM movimientos
      WHERE sincronizado_en IS NULL
        AND venta_uuid IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM movimientos AS m2
          WHERE m2.venta_uuid = movimientos.venta_uuid
            AND m2.producto_uuid = movimientos.producto_uuid
            AND m2.tipo = movimientos.tipo
            AND m2.uuid != movimientos.uuid
            AND m2.sincronizado_en IS NOT NULL
        )
      ''',
      updates: {db.movimientos},
      updateKind: UpdateKind.delete,
    );
  }

  // ── Aplicación de la bajada ───────────────────────────────────────────────

  /// Aplica un bloque de cambios del servidor.
  ///
  /// Dos reglas gobiernan los conflictos (ver docs/ARQUITECTURA.md §3.4):
  ///
  ///  1. **No se pisa lo que aún no se ha enviado.** Si una entidad tiene una
  ///     operación pendiente en la cola, la versión del servidor se descarta:
  ///     lo local es más nuevo por definición.
  ///
  ///  2. **El stock del servidor es autoritativo, pero se le suman los
  ///     movimientos locales aún sin enviar.** Si no, el pull "revertiría" en
  ///     pantalla las tres ventas que todavía están en la cola.
  Future<int> aplicarCambios(Map<String, dynamic> entidades) async {
    var total = 0;

    await db.transaction(() async {
      final bloqueados = await _uuidsConCambiosPendientes();

      total += await _aplicarUsuarios(entidades['usuarios'], bloqueados);
      total += await _aplicarCategorias(entidades['categorias'], bloqueados);
      total += await _aplicarProveedores(entidades['proveedores'], bloqueados);
      total += await _aplicarProductos(entidades['productos'], bloqueados);
      total += await _aplicarCodigos(entidades['producto_codigos'], bloqueados);
      total += await _aplicarVentas(entidades['ventas'], bloqueados);
      total += await _aplicarDetalles(entidades['venta_detalles']);
      total += await _aplicarMovimientos(entidades['movimientos_inventario']);
      total += await _aplicarAlertas(entidades['alertas']);
      total += await _aplicarConfiguracion(entidades['configuracion']);

      for (final entrada in entidades.entries) {
        final bloque = entrada.value;
        if (bloque is! Map) continue;
        final cursor = bloque['cursor'];
        if (cursor is Map && cursor['t'] != null) {
          await guardarCursor(entrada.key, cursor['t'] as String, (cursor['i'] as num).toInt());
        }
      }
    });

    return total;
  }

  Future<Set<String>> _uuidsConCambiosPendientes() async {
    final filas = await (db.select(db.syncOutbox)
          ..where((t) => t.estado.isIn(['PENDIENTE', 'ENVIANDO'])))
        .get();
    return filas.map((f) => f.entidadUuid).whereType<String>().toSet();
  }

  List<Map<String, dynamic>> _items(dynamic bloque) {
    if (bloque is! Map) return const [];
    final items = bloque['items'];
    if (items is! List) return const [];
    return items.cast<Map<String, dynamic>>();
  }

  DateTime _fecha(dynamic v) =>
      v == null ? DateTime.now().toUtc() : DateTime.parse(v as String).toUtc();

  DateTime? _fechaOpcional(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String)?.toUtc();

  int _centavos(dynamic v) => Money.tryParse(v as String?).centavos;
  int _milesimas(dynamic v) => Cantidad.tryParse(v as String?).milesimas;

  // ── Por entidad ───────────────────────────────────────────────────────────

  Future<int> _aplicarUsuarios(dynamic bloque, Set<String> bloqueados) async {
    final items = _items(bloque);
    for (final u in items) {
      // Se preservan el hash y la sal locales: el servidor no los conoce y
      // sobrescribirlos con null dejaría al usuario sin login offline.
      final existente = await (db.select(db.usuarios)
            ..where((t) => t.uuid.equals(u['uuid'] as String)))
          .getSingleOrNull();

      await db.into(db.usuarios).insertOnConflictUpdate(
            UsuariosCompanion.insert(
              uuid: u['uuid'] as String,
              nombre: u['nombre'] as String,
              email: u['email'] as String,
              rol: Value(u['rol'] as String? ?? 'VENDEDOR'),
              activo: Value(u['activo'] == true || u['activo'] == 1),
              passwordHashLocal: Value(existente?.passwordHashLocal),
              saltLocal: Value(existente?.saltLocal),
              updatedAt: Value(_fecha(u['updated_at'])),
              deletedAt: Value(_fechaOpcional(u['deleted_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarCategorias(dynamic bloque, Set<String> bloqueados) async {
    final items = _items(bloque).where((c) => !bloqueados.contains(c['uuid'])).toList();
    for (final c in items) {
      await db.into(db.categorias).insertOnConflictUpdate(
            CategoriasCompanion.insert(
              uuid: c['uuid'] as String,
              nombre: c['nombre'] as String,
              descripcion: Value(c['descripcion'] as String?),
              color: Value(c['color'] as String? ?? '#6750A4'),
              icono: Value(c['icono'] as String?),
              orden: Value((c['orden'] as num?)?.toInt() ?? 0),
              updatedAt: Value(_fecha(c['updated_at'])),
              deletedAt: Value(_fechaOpcional(c['deleted_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarProveedores(dynamic bloque, Set<String> bloqueados) async {
    final items = _items(bloque).where((p) => !bloqueados.contains(p['uuid'])).toList();
    for (final p in items) {
      await db.into(db.proveedores).insertOnConflictUpdate(
            ProveedoresCompanion.insert(
              uuid: p['uuid'] as String,
              nombre: p['nombre'] as String,
              nit: Value(p['nit'] as String?),
              contacto: Value(p['contacto'] as String?),
              telefono: Value(p['telefono'] as String?),
              email: Value(p['email'] as String?),
              direccion: Value(p['direccion'] as String?),
              notas: Value(p['notas'] as String?),
              updatedAt: Value(_fecha(p['updated_at'])),
              deletedAt: Value(_fechaOpcional(p['deleted_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarProductos(dynamic bloque, Set<String> bloqueados) async {
    final items = _items(bloque).where((p) => !bloqueados.contains(p['uuid'])).toList();

    for (final p in items) {
      final uuid = p['uuid'] as String;

      // Stock autoritativo del servidor + lo que aún no ha salido de la cola.
      // Sin este ajuste, un pull haría "reaparecer" en pantalla el stock de las
      // ventas que todavía están pendientes de enviar.
      final stockServidor = _milesimas(p['stock_actual']);
      final pendienteLocal = await _movimientosNoSincronizados(uuid);

      final existente =
          await (db.select(db.productos)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

      await db.into(db.productos).insertOnConflictUpdate(
            ProductosCompanion.insert(
              uuid: uuid,
              sku: p['sku'] as String,
              nombre: p['nombre'] as String,
              nombreBusqueda: Value(normalizarBusqueda(p['nombre'] as String)),
              descripcion: Value(p['descripcion'] as String?),
              categoriaUuid: Value(p['categoria_uuid'] as String?),
              unidadMedida: Value(p['unidad_medida'] as String? ?? 'UND'),
              precioCompra: Value(_centavos(p['precio_compra'])),
              precioVenta: Value(_centavos(p['precio_venta'])),
              tasaIva: Value(TasaIva.parse((p['tasa_iva'] as String?) ?? '0.00').escalada),
              stockActual: Value(stockServidor + pendienteLocal),
              stockMinimo: Value(_milesimas(p['stock_minimo'])),
              stockMaximo: Value(
                p['stock_maximo'] == null ? null : _milesimas(p['stock_maximo']),
              ),
              imagenUrl: Value(p['imagen_url'] as String?),
              // La foto local sobrevive al pull hasta que se sube.
              imagenLocal: Value(existente?.imagenLocal),
              ubicacion: Value(p['ubicacion'] as String?),
              activo: Value(p['activo'] == true || p['activo'] == 1),
              updatedAt: Value(_fecha(p['updated_at'])),
              deletedAt: Value(_fechaOpcional(p['deleted_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _movimientosNoSincronizados(String productoUuid) async {
    final fila = await db
        .customSelect(
          'SELECT COALESCE(SUM(cantidad),0) AS total FROM movimientos '
          'WHERE producto_uuid = ? AND sincronizado_en IS NULL',
          variables: [Variable<String>(productoUuid)],
          readsFrom: {db.movimientos},
        )
        .getSingle();
    return fila.read<int>('total');
  }

  Future<int> _aplicarCodigos(dynamic bloque, Set<String> bloqueados) async {
    final items = _items(bloque).where((c) => !bloqueados.contains(c['uuid'])).toList();
    for (final c in items) {
      await db.into(db.productoCodigos).insertOnConflictUpdate(
            ProductoCodigosCompanion.insert(
              uuid: c['uuid'] as String,
              productoUuid: c['producto_uuid'] as String,
              codigo: c['codigo'] as String,
              tipo: Value(c['tipo'] as String? ?? 'INTERNO'),
              esPrincipal: Value(c['es_principal'] == true || c['es_principal'] == 1),
              factor: Value(_milesimas(c['factor'] ?? '1.000')),
              updatedAt: Value(_fecha(c['updated_at'])),
              deletedAt: Value(_fechaOpcional(c['deleted_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarVentas(dynamic bloque, Set<String> bloqueados) async {
    final items = _items(bloque).where((v) => !bloqueados.contains(v['uuid'])).toList();
    for (final v in items) {
      await db.into(db.ventas).insertOnConflictUpdate(
            VentasCompanion.insert(
              uuid: v['uuid'] as String,
              numero: v['numero'] as String,
              usuarioUuid: Value(v['usuario_uuid'] as String?),
              dispositivoUuid: Value(v['dispositivo_uuid'] as String?),
              clienteNombre: Value(v['cliente_nombre'] as String?),
              clienteDocumento: Value(v['cliente_documento'] as String?),
              subtotal: Value(_centavos(v['subtotal'])),
              descuentoTotal: Value(_centavos(v['descuento_total'])),
              impuestoTotal: Value(_centavos(v['impuesto_total'])),
              total: Value(_centavos(v['total'])),
              costoTotal: Value(_centavos(v['costo_total'])),
              metodoPago: Value(v['metodo_pago'] as String? ?? 'EFECTIVO'),
              montoRecibido: Value(
                v['monto_recibido'] == null ? null : _centavos(v['monto_recibido']),
              ),
              cambio: Value(v['cambio'] == null ? null : _centavos(v['cambio'])),
              estado: Value(v['estado'] as String? ?? 'COMPLETADA'),
              anulaAVentaUuid: Value(v['anula_a_venta_uuid'] as String?),
              motivoAnulacion: Value(v['motivo_anulacion'] as String?),
              notas: Value(v['notas'] as String?),
              fecha: _fecha(v['fecha']),
              fechaLocal: v['fecha_local'] as String,
              creadaOffline: Value(v['creada_offline'] == true || v['creada_offline'] == 1),
              // Si viene del servidor, por definición está sincronizada.
              sincronizadaEn: Value(_fecha(v['updated_at'])),
              updatedAt: Value(_fecha(v['updated_at'])),
              deletedAt: Value(_fechaOpcional(v['deleted_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarDetalles(dynamic bloque) async {
    final items = _items(bloque);
    for (final d in items) {
      await db.into(db.ventaDetalles).insertOnConflictUpdate(
            VentaDetallesCompanion.insert(
              uuid: d['uuid'] as String,
              ventaUuid: d['venta_uuid'] as String,
              productoUuid: Value(d['producto_uuid'] as String?),
              linea: Value((d['linea'] as num?)?.toInt() ?? 1),
              descripcion: d['descripcion'] as String,
              skuSnapshot: Value(d['sku_snapshot'] as String?),
              cantidad: _milesimas(d['cantidad']),
              precioUnitario: _centavos(d['precio_unitario']),
              costoUnitario: Value(_centavos(d['costo_unitario'])),
              descuento: Value(_centavos(d['descuento'])),
              tasaIva: Value(TasaIva.parse((d['tasa_iva'] as String?) ?? '0.00').escalada),
              baseGravable: Value(_centavos(d['base_gravable'])),
              impuesto: Value(_centavos(d['impuesto'])),
              total: Value(_centavos(d['total'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarMovimientos(dynamic bloque) async {
    final items = _items(bloque);
    for (final m in items) {
      final uuid = m['uuid'] as String;
      final ventaUuid = m['venta_uuid'] as String?;
      final productoUuid = m['producto_uuid'] as String;
      final tipo = m['tipo'] as String;

      // Limpieza de duplicados de ventas offline: el cliente escribió el
      // movimiento con uuid A; versiones viejas del servidor crearon uuid B.
      // Al bajar B, se borra la copia local A (aún sin sincronizar) para que
      // el kardex no muestre la misma venta dos veces.
      if (ventaUuid != null) {
        await (db.delete(db.movimientos)
              ..where(
                (t) =>
                    t.ventaUuid.equals(ventaUuid) &
                    t.productoUuid.equals(productoUuid) &
                    t.tipo.equals(tipo) &
                    t.uuid.isNotValue(uuid) &
                    t.sincronizadoEn.isNull(),
              ))
            .go();
      }

      await db.into(db.movimientos).insertOnConflictUpdate(
            MovimientosCompanion.insert(
              uuid: uuid,
              productoUuid: productoUuid,
              tipo: tipo,
              cantidad: _milesimas(m['cantidad']),
              costoUnitario: Value(
                m['costo_unitario'] == null ? null : _centavos(m['costo_unitario']),
              ),
              precioUnitario: Value(
                m['precio_unitario'] == null ? null : _centavos(m['precio_unitario']),
              ),
              stockAnterior: Value(
                m['stock_anterior'] == null ? null : _milesimas(m['stock_anterior']),
              ),
              stockResultante: Value(
                m['stock_resultante'] == null ? null : _milesimas(m['stock_resultante']),
              ),
              ventaUuid: Value(ventaUuid),
              proveedorUuid: Value(m['proveedor_uuid'] as String?),
              usuarioUuid: Value(m['usuario_uuid'] as String?),
              lote: Value(m['lote'] as String?),
              venceEl: Value(m['vence_el'] as String?),
              documentoRef: Value(m['documento_ref'] as String?),
              motivo: Value(m['motivo'] as String?),
              fecha: _fecha(m['fecha']),
              fechaLocal: m['fecha_local'] as String,
              creadoOffline: Value(m['creado_offline'] == true || m['creado_offline'] == 1),
              sincronizadoEn: Value(_fecha(m['updated_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarAlertas(dynamic bloque) async {
    final items = _items(bloque);
    for (final a in items) {
      await db.into(db.alertas).insertOnConflictUpdate(
            AlertasCompanion.insert(
              uuid: a['uuid'] as String,
              tipo: a['tipo'] as String,
              severidad: Value(a['severidad'] as String? ?? 'ADVERTENCIA'),
              productoUuid: Value(a['producto_uuid'] as String?),
              ventaUuid: Value(a['venta_uuid'] as String?),
              mensaje: a['mensaje'] as String,
              resueltaEn: Value(_fechaOpcional(a['resuelta_en'])),
              updatedAt: Value(_fecha(a['updated_at'])),
            ),
          );
    }
    return items.length;
  }

  Future<int> _aplicarConfiguracion(dynamic bloque) async {
    final items = _items(bloque);
    for (final c in items) {
      await db.into(db.configuracion).insertOnConflictUpdate(
            ConfiguracionCompanion.insert(
              clave: c['clave'] as String,
              valor: c['valor'] as String,
              tipo: Value(c['tipo'] as String? ?? 'STRING'),
            ),
          );
    }
    return items.length;
  }

  // ── Configuración ─────────────────────────────────────────────────────────

  Future<String?> config(String clave) async {
    final fila = await (db.select(db.configuracion)..where((t) => t.clave.equals(clave)))
        .getSingleOrNull();
    return fila?.valor;
  }

  Stream<Map<String, String>> observarConfiguracion() => db
      .select(db.configuracion)
      .watch()
      .map((filas) => {for (final f in filas) f.clave: f.valor});
}
