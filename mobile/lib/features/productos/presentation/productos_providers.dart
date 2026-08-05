import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/productos_dao.dart';
import '../../../core/providers/providers.dart';

/// Filtros de la lista de productos.
///
/// Van en un provider y no en el `State` de la página para que sobrevivan a la
/// navegación: entrar a un producto y volver no debe borrar la búsqueda que
/// costó teclear.
class FiltroProductos {
  const FiltroProductos({
    this.busqueda = '',
    this.categoriaUuid,
    this.stock = FiltroStock.todos,
    this.orden = OrdenProductos.nombre,
  });

  final String busqueda;
  final String? categoriaUuid;
  final FiltroStock stock;
  final OrdenProductos orden;

  bool get hayFiltros =>
      categoriaUuid != null || stock != FiltroStock.todos || busqueda.isNotEmpty;

  FiltroProductos copyWith({
    String? busqueda,
    String? categoriaUuid,
    bool limpiarCategoria = false,
    FiltroStock? stock,
    OrdenProductos? orden,
  }) =>
      FiltroProductos(
        busqueda: busqueda ?? this.busqueda,
        categoriaUuid: limpiarCategoria ? null : (categoriaUuid ?? this.categoriaUuid),
        stock: stock ?? this.stock,
        orden: orden ?? this.orden,
      );
}

class FiltroProductosNotifier extends Notifier<FiltroProductos> {
  @override
  FiltroProductos build() => const FiltroProductos();

  void buscar(String texto) => state = state.copyWith(busqueda: texto);

  void porCategoria(String? uuid) => state = uuid == null
      ? state.copyWith(limpiarCategoria: true)
      : state.copyWith(categoriaUuid: uuid);

  void porStock(FiltroStock stock) => state = state.copyWith(stock: stock);

  void ordenar(OrdenProductos orden) => state = state.copyWith(orden: orden);

  void limpiar() => state = const FiltroProductos();
}

final filtroProductosProvider =
    NotifierProvider<FiltroProductosNotifier, FiltroProductos>(
  FiltroProductosNotifier.new,
);

/// Lista filtrada. Es un stream de Drift: al sincronizar o al vender, la lista
/// se repinta sola sin que nadie la invalide.
final productosProvider = StreamProvider<List<ProductoConCategoria>>((ref) {
  final filtro = ref.watch(filtroProductosProvider);
  return ref.watch(productosDaoProvider).observar(
        busqueda: filtro.busqueda,
        categoriaUuid: filtro.categoriaUuid,
        filtroStock: filtro.stock,
        orden: filtro.orden,
      );
});

final categoriasProvider = StreamProvider<List<Categoria>>(
  (ref) => ref.watch(productosDaoProvider).observarCategorias(),
);

final proveedoresProvider = StreamProvider<List<Proveedor>>(
  (ref) => ref.watch(productosDaoProvider).observarProveedores(),
);

final productoProvider = StreamProvider.family<ProductoConCategoria?, String>(
  (ref, uuid) => ref.watch(productosDaoProvider).observarUno(uuid),
);

final codigosProductoProvider = FutureProvider.family<List<ProductoCodigo>, String>(
  (ref, uuid) => ref.watch(productosDaoProvider).codigosDe(uuid),
);
