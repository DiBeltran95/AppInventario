import 'package:drift/drift.dart';

import '../../money/money.dart';
import '../../utils/fechas.dart';
import '../app_database.dart';

/// Reportes calculados **en el dispositivo**.
///
/// No son una caché de lo que devuelve el servidor: son agregados SQL sobre la
/// base local. Por eso funcionan en modo avión, que es justo cuando el dueño
/// quiere saber cuánto lleva vendido en el día.
///
/// Todo agrupa por `fecha_local` (día hábil de la tienda), nunca por UTC.

class ResumenDashboard {
  const ResumenDashboard({
    required this.ventasHoy,
    required this.numVentasHoy,
    required this.ventasAyer,
    required this.ventasSemana,
    required this.ventasMes,
    required this.margenMes,
    required this.ticketPromedio,
    required this.productosActivos,
    required this.productosStockBajo,
    required this.productosAgotados,
    required this.valorInventario,
    required this.ventasPendientesSync,
  });

  final Money ventasHoy;
  final int numVentasHoy;
  final Money ventasAyer;
  final Money ventasSemana;
  final Money ventasMes;
  final Money margenMes;
  final Money ticketPromedio;
  final int productosActivos;
  final int productosStockBajo;
  final int productosAgotados;
  final Money valorInventario;
  final int ventasPendientesSync;

  /// Variación porcentual frente a ayer. `null` si ayer no hubo ventas: un
  /// «+∞ %» no informa de nada.
  double? get variacionVsAyer {
    if (ventasAyer.esCero) return null;
    return (ventasHoy.centavos - ventasAyer.centavos) / ventasAyer.centavos * 100;
  }
}

class PuntoSerie {
  const PuntoSerie({required this.dia, required this.total, required this.numVentas});
  final String dia;
  final Money total;
  final int numVentas;
}

class ProductoVendido {
  const ProductoVendido({
    required this.productoUuid,
    required this.nombre,
    required this.unidades,
    required this.ingreso,
    required this.margen,
  });

  final String? productoUuid;
  final String nombre;
  final Cantidad unidades;
  final Money ingreso;
  final Money margen;
}

/// Rendimiento de un empleado en un periodo.
class RendimientoEmpleado {
  const RendimientoEmpleado({
    required this.uuid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    required this.numVentas,
    required this.total,
    required this.margen,
    required this.ticketPromedio,
    required this.creadasOffline,
    required this.anuladas,
    this.ultimaVenta,
  });

  final String uuid;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final int numVentas;
  final Money total;
  final Money margen;
  final Money ticketPromedio;

  /// Cuántas de sus ventas se registraron sin conexión. Un número muy alto en
  /// una tienda con buen wifi merece una pregunta.
  final int creadasOffline;

  /// Ventas suyas que acabaron anuladas. Anular una venta ya cobrada y quedarse
  /// el efectivo es el fraude clásico de caja: aquí se ve concentrado por turno.
  final int anuladas;

  final DateTime? ultimaVenta;

  bool get esAdmin => rol == 'ADMIN';
  bool get sinActividad => numVentas == 0;

  /// Señal de que conviene mirar este turno con detalle.
  bool get requiereAtencion => anuladas > 0;
}

class ReportesDao {
  ReportesDao(this.db);

  final AppDatabase db;

  /// Se declaran las tablas leídas para que Drift reemita el stream cuando
  /// cualquiera de ellas cambie: al cobrar una venta, el dashboard se actualiza
  /// solo, sin que nadie invalide nada a mano.
  Set<TableInfo<Table, dynamic>> _lee() => {
        db.ventas,
        db.ventaDetalles,
        db.productos,
        db.movimientos,
      };

  Stream<ResumenDashboard> observarResumen() {
    final hoy = Fechas.hoy();
    final ayer = Fechas.sumarDias(hoy, -1);
    final semana = Fechas.sumarDias(hoy, -6);
    final mes = Fechas.sumarDias(hoy, -29);

    return db
        .customSelect(
          '''
          SELECT
            (SELECT COALESCE(SUM(total),0) FROM ventas
              WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local = ?)   AS ventas_hoy,
            (SELECT COUNT(*) FROM ventas
              WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local = ?)   AS num_hoy,
            (SELECT COALESCE(SUM(total),0) FROM ventas
              WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local = ?)   AS ventas_ayer,
            (SELECT COALESCE(SUM(total),0) FROM ventas
              WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local >= ?)  AS ventas_semana,
            (SELECT COALESCE(SUM(total),0) FROM ventas
              WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local >= ?)  AS ventas_mes,
            (SELECT COALESCE(SUM(total - costo_total),0) FROM ventas
              WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local >= ?)  AS margen_mes,
            (SELECT COUNT(*) FROM productos WHERE deleted_at IS NULL AND activo = 1)  AS activos,
            (SELECT COUNT(*) FROM productos
              WHERE deleted_at IS NULL AND activo = 1
                AND stock_actual <= stock_minimo AND stock_actual > 0)                AS bajos,
            (SELECT COUNT(*) FROM productos
              WHERE deleted_at IS NULL AND activo = 1 AND stock_actual <= 0)          AS agotados,
            (SELECT COALESCE(SUM(stock_actual * precio_compra / 1000), 0) FROM productos
              WHERE deleted_at IS NULL AND activo = 1)                                AS valor_inv,
            (SELECT COUNT(*) FROM ventas
              WHERE sincronizada_en IS NULL AND deleted_at IS NULL)                   AS pendientes
          ''',
          variables: [
            Variable<String>(hoy),
            Variable<String>(hoy),
            Variable<String>(ayer),
            Variable<String>(semana),
            Variable<String>(mes),
            Variable<String>(mes),
          ],
          readsFrom: _lee(),
        )
        .watchSingle()
        .map((f) {
      final ventasHoy = Money(f.read<int>('ventas_hoy'));
      final numHoy = f.read<int>('num_hoy');
      return ResumenDashboard(
        ventasHoy: ventasHoy,
        numVentasHoy: numHoy,
        ventasAyer: Money(f.read<int>('ventas_ayer')),
        ventasSemana: Money(f.read<int>('ventas_semana')),
        ventasMes: Money(f.read<int>('ventas_mes')),
        margenMes: Money(f.read<int>('margen_mes')),
        ticketPromedio: numHoy > 0 ? Money(ventasHoy.centavos ~/ numHoy) : const Money.cero(),
        productosActivos: f.read<int>('activos'),
        productosStockBajo: f.read<int>('bajos'),
        productosAgotados: f.read<int>('agotados'),
        // stock (milésimas) × precio (centavos) / 1000 = centavos
        valorInventario: Money(f.read<int>('valor_inv')),
        ventasPendientesSync: f.read<int>('pendientes'),
      );
    });
  }

  Stream<List<PuntoSerie>> observarSerie({int dias = 14}) {
    final desde = Fechas.sumarDias(Fechas.hoy(), -(dias - 1));

    return db
        .customSelect(
          '''
          SELECT fecha_local, COALESCE(SUM(total),0) AS total, COUNT(*) AS n
            FROM ventas
           WHERE estado='COMPLETADA' AND deleted_at IS NULL AND fecha_local >= ?
           GROUP BY fecha_local
           ORDER BY fecha_local
          ''',
          variables: [Variable<String>(desde)],
          readsFrom: {db.ventas},
        )
        .watch()
        .map((filas) {
      final porDia = {
        for (final f in filas)
          f.read<String>('fecha_local'): (
            total: Money(f.read<int>('total')),
            n: f.read<int>('n'),
          ),
      };
      // Se rellenan los días sin ventas: una gráfica con huecos miente sobre la
      // forma de la serie.
      return List.generate(dias, (i) {
        final dia = Fechas.sumarDias(desde, i);
        final dato = porDia[dia];
        return PuntoSerie(
          dia: dia,
          total: dato?.total ?? const Money.cero(),
          numVentas: dato?.n ?? 0,
        );
      });
    });
  }

  Stream<List<ProductoVendido>> observarTopProductos({
    String? desde,
    String? hasta,
    int limite = 10,
    String por = 'unidades',
  }) {
    final d = desde ?? Fechas.sumarDias(Fechas.hoy(), -29);
    final h = hasta ?? Fechas.hoy();
    final orden = switch (por) {
      'ingreso' => 'ingreso DESC',
      'margen' => 'margen DESC',
      _ => 'unidades DESC',
    };

    return db
        .customSelect(
          '''
          SELECT d.producto_uuid,
                 MAX(d.descripcion)                                        AS nombre,
                 COALESCE(SUM(d.cantidad),0)                               AS unidades,
                 COALESCE(SUM(d.total),0)                                  AS ingreso,
                 COALESCE(SUM(d.total - (d.costo_unitario * d.cantidad / 1000)),0) AS margen
            FROM venta_detalles d
            JOIN ventas v ON v.uuid = d.venta_uuid
           WHERE v.estado='COMPLETADA' AND v.deleted_at IS NULL
             AND v.fecha_local BETWEEN ? AND ?
           GROUP BY d.producto_uuid
           ORDER BY $orden
           LIMIT ?
          ''',
          variables: [Variable<String>(d), Variable<String>(h), Variable<int>(limite)],
          readsFrom: {db.ventaDetalles, db.ventas},
        )
        .watch()
        .map((filas) => filas
            .map((f) => ProductoVendido(
                  productoUuid: f.read<String?>('producto_uuid'),
                  nombre: f.read<String>('nombre'),
                  unidades: Cantidad(f.read<int>('unidades')),
                  ingreso: Money(f.read<int>('ingreso')),
                  margen: Money(f.read<int>('margen')),
                ))
            .toList());
  }

  /// Rendimiento por empleado. Es la vista de control cuando hay varias cajas.
  ///
  /// Se calcula **en local** sobre las ventas ya sincronizadas, como el resto de
  /// los reportes: el dueño puede revisar los turnos sin depender de la red.
  ///
  /// Se incluyen los empleados SIN ventas a propósito (`LEFT JOIN`): alguien que
  /// estuvo en turno y no registró nada es exactamente lo que hay que ver.
  Stream<List<RendimientoEmpleado>> observarPorEmpleado({
    String? desde,
    String? hasta,
  }) {
    final d = desde ?? Fechas.inicioMes();
    final h = hasta ?? Fechas.hoy();

    return db
        .customSelect(
          '''
          SELECT u.uuid, u.nombre, u.email, u.rol, u.activo,
                 COUNT(v.uuid)                                      AS num_ventas,
                 COALESCE(SUM(v.total), 0)                          AS total,
                 COALESCE(SUM(v.total - v.costo_total), 0)          AS margen,
                 COALESCE(SUM(CASE WHEN v.creada_offline = 1 THEN 1 ELSE 0 END), 0)
                                                                    AS offline,
                 MAX(v.fecha)                                       AS ultima_venta,
                 (SELECT COUNT(*) FROM ventas a
                   WHERE a.usuario_uuid = u.uuid
                     AND a.estado = 'ANULADA'
                     AND a.anula_a_venta_uuid IS NULL
                     AND a.deleted_at IS NULL
                     AND a.fecha_local BETWEEN ? AND ?)             AS anuladas
            FROM usuarios u
            LEFT JOIN ventas v
                   ON v.usuario_uuid = u.uuid
                  AND v.estado = 'COMPLETADA'
                  AND v.deleted_at IS NULL
                  AND v.anula_a_venta_uuid IS NULL
                  AND v.fecha_local BETWEEN ? AND ?
           WHERE u.deleted_at IS NULL
           GROUP BY u.uuid, u.nombre, u.email, u.rol, u.activo
           ORDER BY total DESC, u.nombre ASC
          ''',
          variables: [
            Variable<String>(d), Variable<String>(h),
            Variable<String>(d), Variable<String>(h),
          ],
          readsFrom: {db.usuarios, db.ventas},
        )
        .watch()
        .map((filas) => filas.map((f) {
              final num = f.read<int>('num_ventas');
              final total = Money(f.read<int>('total'));
              return RendimientoEmpleado(
                uuid: f.read<String>('uuid'),
                nombre: f.read<String>('nombre'),
                email: f.read<String>('email'),
                rol: f.read<String>('rol'),
                activo: f.read<int>('activo') == 1,
                numVentas: num,
                total: total,
                margen: Money(f.read<int>('margen')),
                ticketPromedio: num > 0 ? Money(total.centavos ~/ num) : const Money.cero(),
                creadasOffline: f.read<int>('offline'),
                anuladas: f.read<int>('anuladas'),
                ultimaVenta: f.read<DateTime?>('ultima_venta'),
              );
            }).toList());
  }

  /// Ventas agrupadas por día, semana o mes, para la pantalla de reportes.
  Future<List<PuntoSerie>> ventasPorPeriodo({
    required String desde,
    required String hasta,
    String agrupar = 'dia',
  }) async {
    // SQLite no tiene DATE_FORMAT: se recorta la cadena 'AAAA-MM-DD', que ya
    // está en el formato correcto para agrupar por mes.
    final expr = switch (agrupar) {
      'mes' => "substr(fecha_local, 1, 7)",
      'semana' => "strftime('%Y-W%W', fecha_local)",
      _ => 'fecha_local',
    };

    final filas = await db.customSelect(
      '''
      SELECT $expr AS periodo, COALESCE(SUM(total),0) AS total, COUNT(*) AS n
        FROM ventas
       WHERE estado='COMPLETADA' AND deleted_at IS NULL
         AND fecha_local BETWEEN ? AND ?
       GROUP BY periodo
       ORDER BY periodo
      ''',
      variables: [Variable<String>(desde), Variable<String>(hasta)],
      readsFrom: {db.ventas},
    ).get();

    return filas
        .map((f) => PuntoSerie(
              dia: f.read<String>('periodo'),
              total: Money(f.read<int>('total')),
              numVentas: f.read<int>('n'),
            ))
        .toList();
  }

  /// Valorización del inventario por categoría.
  Stream<List<({String categoria, int productos, Money costo, Money venta})>>
      observarValorizacion() {
    return db
        .customSelect(
          '''
          SELECT COALESCE(c.nombre, 'Sin categoría')                    AS categoria,
                 COUNT(p.uuid)                                          AS n,
                 COALESCE(SUM(p.stock_actual * p.precio_compra / 1000),0) AS costo,
                 COALESCE(SUM(p.stock_actual * p.precio_venta / 1000),0)  AS venta
            FROM productos p
            LEFT JOIN categorias c ON c.uuid = p.categoria_uuid
           WHERE p.deleted_at IS NULL AND p.activo = 1
           GROUP BY c.uuid, c.nombre
           ORDER BY costo DESC
          ''',
          readsFrom: {db.productos, db.categorias},
        )
        .watch()
        .map((filas) => filas
            .map((f) => (
                  categoria: f.read<String>('categoria'),
                  productos: f.read<int>('n'),
                  costo: Money(f.read<int>('costo')),
                  venta: Money(f.read<int>('venta')),
                ))
            .toList());
  }

  /// Resumen de movimientos por tipo en un rango.
  Future<List<({String tipo, int n, Cantidad neto})>> resumenMovimientos({
    required String desde,
    required String hasta,
  }) async {
    final filas = await db.customSelect(
      '''
      SELECT tipo, COUNT(*) AS n, COALESCE(SUM(cantidad),0) AS neto
        FROM movimientos
       WHERE fecha_local BETWEEN ? AND ?
       GROUP BY tipo
       ORDER BY n DESC
      ''',
      variables: [Variable<String>(desde), Variable<String>(hasta)],
      readsFrom: {db.movimientos},
    ).get();

    return filas
        .map((f) => (
              tipo: f.read<String>('tipo'),
              n: f.read<int>('n'),
              neto: Cantidad(f.read<int>('neto')),
            ))
        .toList();
  }
}
