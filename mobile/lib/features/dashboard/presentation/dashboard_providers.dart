import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/productos_dao.dart';
import '../../../core/database/daos/reportes_dao.dart';
import '../../../core/providers/providers.dart';

/// Todo lo que pinta el dashboard sale de SQLite, no de la red.
///
/// Son `StreamProvider`s sobre consultas de Drift: al cobrar una venta, el
/// resumen se actualiza solo porque Drift reemite el stream de las tablas
/// afectadas. No hay ningún `invalidate()` manual en toda la app.

final resumenDashboardProvider = StreamProvider<ResumenDashboard>(
  (ref) => ref.watch(reportesDaoProvider).observarResumen(),
);

final serieVentasProvider = StreamProvider<List<PuntoSerie>>(
  (ref) => ref.watch(reportesDaoProvider).observarSerie(dias: 14),
);

final stockBajoProvider = StreamProvider<List<ProductoConCategoria>>(
  (ref) => ref.watch(productosDaoProvider).observarStockBajo(limite: 8),
);

final alertasProvider = StreamProvider(
  (ref) => ref.watch(inventarioDaoProvider).observarAlertas(),
);

final topProductosProvider = StreamProvider<List<ProductoVendido>>(
  (ref) => ref.watch(reportesDaoProvider).observarTopProductos(limite: 5),
);
