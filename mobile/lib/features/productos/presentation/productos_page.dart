import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/productos_dao.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/sync_chip.dart';
import '../../auth/presentation/auth_providers.dart';
import 'productos_providers.dart';
import 'widgets/tarjeta_producto.dart';

/// Catálogo.
///
/// La búsqueda consulta SQLite contra una columna ya normalizada (minúsculas y
/// sin tildes), así que responde igual con 50 productos que con 10.000 y no
/// necesita conexión.
class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  final _busqueda = TextEditingController();
  Timer? _rebote;
  bool _aplicoParametroInicial = false;

  @override
  void dispose() {
    _rebote?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_aplicoParametroInicial) return;
    _aplicoParametroInicial = true;

    // El dashboard enlaza aquí con `?stock=bajo` desde la tarjeta de alertas.
    final parametro = GoRouterState.of(context).uri.queryParameters['stock'];
    final filtro = switch (parametro) {
      'bajo' => FiltroStock.bajo,
      'agotado' => FiltroStock.agotado,
      _ => null,
    };
    if (filtro != null) {
      // Se aplica tras el primer fotograma: modificar un provider durante el
      // build lanza en Riverpod.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(filtroProductosProvider.notifier).porStock(filtro);
      });
    }
  }

  void _buscar(String texto) {
    // Rebote corto: teclear «gaseosa» dispararía siete consultas seguidas.
    _rebote?.cancel();
    _rebote = Timer(const Duration(milliseconds: 220), () {
      ref.read(filtroProductosProvider.notifier).buscar(texto);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(filtroProductosProvider);
    final productos = ref.watch(productosProvider);
    final esAdmin = ref.watch(esAdminProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Productos', style: context.textos.headlineSmall)),
                  const SyncChip(compacto: true),
                  IconButton(
                    onPressed: () => context.push('${Rutas.escanear}?modo=consulta'),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: 'Buscar escaneando',
                  ),
                  _MenuOrden(
                    orden: filtro.orden,
                    onCambiar: ref.read(filtroProductosProvider.notifier).ordenar,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _busqueda,
                onChanged: _buscar,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, SKU o código',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _busqueda.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _busqueda.clear();
                            _buscar('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Limpiar',
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _BarraFiltros(filtro: filtro),
            const SizedBox(height: 4),
            Expanded(
              child: productos.when(
                loading: () => const SkeletonLista(),
                error: (e, _) => EstadoError(mensaje: '$e'),
                data: (lista) {
                  if (lista.isEmpty) {
                    return EstadoVacio(
                      icono: filtro.hayFiltros
                          ? Icons.filter_alt_off_outlined
                          : Icons.inventory_2_outlined,
                      titulo: filtro.hayFiltros
                          ? 'Ningún producto coincide'
                          : 'Aún no hay productos',
                      descripcion: filtro.hayFiltros
                          ? 'Prueba con otro término o quita los filtros.'
                          : 'Crea el primero o escanea un código para darlo de alta.',
                      textoAccion: filtro.hayFiltros ? 'Quitar filtros' : 'Crear producto',
                      onAccion: filtro.hayFiltros
                          ? () {
                              _busqueda.clear();
                              ref.read(filtroProductosProvider.notifier).limpiar();
                            }
                          : () => context.push(Rutas.productoNuevo),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => TarjetaProducto(
                      item: lista[i],
                      mostrarCosto: esAdmin,
                      onTap: () => context.push(Rutas.productoDetalle(lista[i].uuid)),
                      onLongPress: () => _hojaAcciones(context, lista[i], esAdmin),
                    )
                        .animate()
                        // El retardo se acota a las primeras filas: escalonar
                        // 300 elementos dejaría el final de la lista en blanco
                        // durante segundos.
                        .fadeIn(
                          duration: 220.ms,
                          delay: Duration(milliseconds: 18 * (i < 8 ? i : 8)),
                        )
                        .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: esAdmin
          ? Padding(
              // Se desplaza para no chocar con el FAB de escanear del shell.
              padding: const EdgeInsets.only(bottom: 4),
              child: FloatingActionButton(
                heroTag: 'fab-nuevo-producto',
                onPressed: () => context.push(Rutas.productoNuevo),
                tooltip: 'Nuevo producto',
                child: const Icon(Icons.add_rounded),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _hojaAcciones(BuildContext context, ProductoConCategoria item, bool esAdmin) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(item.nombre, style: context.textos.titleMedium),
              subtitle: Text(item.sku),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver ficha'),
              onTap: () {
                Navigator.pop(hoja);
                context.push(Rutas.productoDetalle(item.uuid));
              },
            ),
            // Entrada, movimientos y edición tocan el inventario: son de
            // administración. Al vendedor le rebotarían contra el enrutador,
            // y un atajo que parpadea y devuelve al inicio confunde más que
            // no estar.
            if (esAdmin) ...[
              ListTile(
                leading: const Icon(Icons.move_to_inbox_rounded),
                title: const Text('Registrar entrada'),
                onTap: () {
                  Navigator.pop(hoja);
                  context.push('${Rutas.entrada}?producto=${item.uuid}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_vert_rounded),
                title: const Text('Ver movimientos'),
                onTap: () {
                  Navigator.pop(hoja);
                  context.push('${Rutas.movimientos}?producto=${item.uuid}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(hoja);
                  context.push(Rutas.productoEditar(item.uuid));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarraFiltros extends ConsumerWidget {
  const _BarraFiltros({required this.filtro});

  final FiltroProductos filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasProvider).value ?? const [];
    final notifier = ref.read(filtroProductosProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('Stock bajo'),
            selected: filtro.stock == FiltroStock.bajo,
            avatar: filtro.stock == FiltroStock.bajo
                ? null
                : Icon(Icons.warning_amber_rounded, size: 16, color: context.dominio.advertencia),
            onSelected: (sel) =>
                notifier.porStock(sel ? FiltroStock.bajo : FiltroStock.todos),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Agotados'),
            selected: filtro.stock == FiltroStock.agotado,
            onSelected: (sel) =>
                notifier.porStock(sel ? FiltroStock.agotado : FiltroStock.todos),
          ),
          for (final categoria in categorias) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(categoria.nombre),
              selected: filtro.categoriaUuid == categoria.uuid,
              onSelected: (sel) => notifier.porCategoria(sel ? categoria.uuid : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuOrden extends StatelessWidget {
  const _MenuOrden({required this.orden, required this.onCambiar});

  final OrdenProductos orden;
  final ValueChanged<OrdenProductos> onCambiar;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OrdenProductos>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Ordenar',
      initialValue: orden,
      onSelected: onCambiar,
      itemBuilder: (context) => const [
        PopupMenuItem(value: OrdenProductos.nombre, child: Text('Nombre (A-Z)')),
        PopupMenuItem(value: OrdenProductos.stockAsc, child: Text('Menos stock primero')),
        PopupMenuItem(value: OrdenProductos.precioDesc, child: Text('Mayor precio')),
        PopupMenuItem(value: OrdenProductos.reciente, child: Text('Modificados hace poco')),
      ],
    );
  }
}
