import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/inventario_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../productos/presentation/productos_providers.dart';
import 'inventario_providers.dart';

/// Historial de movimientos: el libro mayor del inventario.
///
/// Es la única fuente de verdad del stock; `productos.stockActual` no es más
/// que una suma materializada de esta lista. Por eso aquí no se puede editar
/// ni borrar nada: una corrección es un movimiento nuevo, no un borrado.
class MovimientosPage extends ConsumerStatefulWidget {
  const MovimientosPage({super.key, this.productoUuid});

  final String? productoUuid;

  @override
  ConsumerState<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends ConsumerState<MovimientosPage> {
  late FiltroMovimientos _filtro = FiltroMovimientos(productoUuid: widget.productoUuid);

  static const _tipos = [
    'ENTRADA',
    'VENTA',
    'AJUSTE',
    'MERMA',
    'DEVOLUCION',
    'ANULACION_VENTA',
  ];

  @override
  Widget build(BuildContext context) {
    final movimientos = ref.watch(movimientosProvider(_filtro));
    final producto = widget.productoUuid == null
        ? null
        : ref.watch(productoProvider(widget.productoUuid!)).value;
    final verCostos = ref.watch(esAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Movimientos'),
            if (producto != null)
              Text(
                producto.nombre,
                style: context.textos.bodySmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (widget.productoUuid != null)
            IconButton(
              onPressed: () =>
                  context.push('${Rutas.entrada}?producto=${widget.productoUuid}'),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nueva entrada',
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _filtro.tipo == null,
                  onSelected: (_) =>
                      setState(() => _filtro = _filtro.copyWith(limpiarTipo: true)),
                ),
                for (final tipo in _tipos) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(etiquetaMovimiento(tipo)),
                    selected: _filtro.tipo == tipo,
                    onSelected: (sel) => setState(
                      () => _filtro = sel
                          ? _filtro.copyWith(tipo: tipo)
                          : _filtro.copyWith(limpiarTipo: true),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: movimientos.when(
              loading: () => const SkeletonLista(),
              error: (e, _) => EstadoError(mensaje: '$e'),
              data: (lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.swap_vert_rounded,
                    titulo: 'Sin movimientos',
                    descripcion:
                        'Aquí aparecerán las entradas, ventas y ajustes de inventario.',
                  );
                }

                // Se agrupa por día para que el historial se lea como un
                // extracto bancario y no como una lista plana de 200 filas.
                final porDia = <String, List<MovimientoConProducto>>{};
                for (final m in lista) {
                  porDia.putIfAbsent(m.movimiento.fechaLocal, () => []).add(m);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: porDia.length,
                  itemBuilder: (context, i) {
                    final dia = porDia.keys.elementAt(i);
                    final delDia = porDia[dia]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                          child: Text(
                            Fechas.formatDiaIso(dia),
                            style: context.textos.labelLarge?.copyWith(
                              color: context.colores.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Card(
                          child: Column(
                            children: [
                              for (var j = 0; j < delDia.length; j++) ...[
                                if (j > 0)
                                  const Divider(height: 1, indent: 60, endIndent: 16),
                                _FilaMovimiento(
                                  item: delDia[j],
                                  mostrarProducto: widget.productoUuid == null,
                                  verCostos: verCostos,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento({
    required this.item,
    required this.mostrarProducto,
    required this.verCostos,
  });

  final MovimientoConProducto item;
  final bool mostrarProducto;
  final bool verCostos;

  @override
  Widget build(BuildContext context) {
    final entrada = item.esEntrada;
    final color = entrada ? context.dominio.exito : context.dominio.peligro;
    final fondo = entrada ? context.dominio.exitoContenedor : context.dominio.peligroContenedor;
    final m = item.movimiento;

    return ListTile(
      onTap: item.producto == null
          ? null
          : () => context.push(Rutas.productoDetalle(m.productoUuid)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
        child: Icon(_icono(m.tipo), size: 20, color: color),
      ),
      title: Text(
        mostrarProducto
            ? (item.producto?.nombre ?? 'Producto eliminado')
            : etiquetaMovimiento(m.tipo),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (mostrarProducto) etiquetaMovimiento(m.tipo),
          Fechas.formatHora(m.fecha),
          if (item.proveedor != null) item.proveedor!.nombre,
          if (m.documentoRef != null) m.documentoRef!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textos.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.pendienteDeSync) ...[
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 14,
                  color: context.dominio.advertencia,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '${entrada ? '+' : ''}${item.cantidad.format()}',
                style: context.textos.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
          if (verCostos && m.costoUnitario != null)
            Text(
              Money(m.costoUnitario!).format(),
              style: context.textos.labelSmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            )
          else if (m.stockResultante != null)
            Text(
              'queda ${Cantidad(m.stockResultante!).format()}',
              style: context.textos.labelSmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  static IconData _icono(String tipo) => switch (tipo) {
        'ENTRADA' => Icons.move_to_inbox_rounded,
        'VENTA' => Icons.point_of_sale_rounded,
        'AJUSTE' => Icons.tune_rounded,
        'MERMA' => Icons.delete_outline_rounded,
        'DEVOLUCION' => Icons.undo_rounded,
        'ANULACION_VENTA' => Icons.restore_rounded,
        'INICIAL' => Icons.flag_outlined,
        _ => Icons.swap_vert_rounded,
      };
}
