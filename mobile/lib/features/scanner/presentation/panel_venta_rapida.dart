import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/productos_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/widgets/contador_animado.dart';
import '../../../core/widgets/estados.dart';
import '../../ventas/presentation/carrito_provider.dart';

/// Rejilla de venta rápida.
///
/// Con un catálogo de 100–200 productos, **tocar es más rápido que escanear**:
/// no hay que enfocar, ni buscar luz, ni pelearse con una etiqueta arrugada o
/// con un envase abollado. La cámara sigue siendo el camino principal; esto es
/// la salida cuando el código no se deja leer, y el atajo para los diez
/// productos que se venden todo el día.
///
/// Se abre desde el escáner y **no se cierra al añadir**: el patrón es tocar
/// varios artículos seguidos, igual que se escanean varios seguidos.
class PanelVentaRapida extends ConsumerStatefulWidget {
  const PanelVentaRapida({super.key});

  /// Abre el panel como hoja inferior a casi pantalla completa.
  static Future<void> mostrar(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const PanelVentaRapida(),
    );
  }

  @override
  ConsumerState<PanelVentaRapida> createState() => _PanelVentaRapidaState();
}

class _PanelVentaRapidaState extends ConsumerState<PanelVentaRapida>
    with AnimacionPrimeraCarga {
  final _controladorBusqueda = TextEditingController();
  String _busqueda = '';
  String? _ultimoTocado;

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _agregar(ProductoConCategoria producto) {
    HapticFeedback.mediumImpact();
    ref.read(carritoProvider.notifier).agregar(producto);
    // Marca la baldosa para que confirme visualmente sin robar el foco ni
    // tapar la rejilla con un aviso.
    setState(() => _ultimoTocado = producto.uuid);
  }

  @override
  Widget build(BuildContext context) {
    final buscando = _busqueda.trim().isNotEmpty;

    // Sin búsqueda se muestran los frecuentes; al escribir, el catálogo entero.
    final lista = buscando
        ? ref.watch(_resultadosProvider(_busqueda))
        : ref.watch(_frecuentesProvider);

    final carrito = ref.watch(carritoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controladorBusqueda,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: 'Buscar producto o código',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: buscando
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Limpiar',
                        onPressed: () {
                          _controladorBusqueda.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (!buscando)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: context.dominio.advertencia,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Los que más vendes',
                    style: context.textos.labelLarge?.copyWith(
                      color: context.colores.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: lista.when(
              loading: () => const SkeletonLista(filas: 6, alturaFila: 96),
              error: (e, _) => EstadoError(mensaje: '$e'),
              data: (productos) {
                if (productos.isEmpty) {
                  return EstadoVacio(
                    icono: buscando ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                    titulo: buscando
                        ? 'Nada coincide con «${_busqueda.trim()}»'
                        : 'Aún no tienes productos',
                    descripcion: buscando
                        ? 'Prueba con menos letras o con el código.'
                        : 'Crea el primero desde el catálogo.',
                    compacto: true,
                  );
                }

                return GridView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    // Ancho máximo en vez de nº de columnas: así se adapta solo
                    // a pantallas estrechas y a móviles grandes.
                    maxCrossAxisExtent: 168,
                    mainAxisExtent: 132,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, i) {
                    final p = productos[i];
                    final baldosa = _Baldosa(
                      producto: p,
                      recienTocado: p.uuid == _ultimoTocado,
                      onTap: () => _agregar(p),
                    );

                    return EntradaEscalonada(
                      indice: i,
                      activo: enPrimeraCarga,
                      child: baldosa,
                    );
                  },
                );
              },
            ),
          ),
          if (!carrito.vacio)
            _PieCarrito(
              articulos: carrito.articulos,
              total: carrito.total,
              onCobrar: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

/// Baldosa de producto. Grande a propósito: se toca con el pulgar y con prisa.
class _Baldosa extends StatelessWidget {
  const _Baldosa({
    required this.producto,
    required this.recienTocado,
    required this.onTap,
  });

  final ProductoConCategoria producto;
  final bool recienTocado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dominio = context.dominio;
    final (colorStock, fondoStock) = producto.agotado
        ? (dominio.peligro, dominio.peligroContenedor)
        : producto.bajoStock
            ? (dominio.advertencia, dominio.advertenciaContenedor)
            : (dominio.exito, dominio.exitoContenedor);

    return Semantics(
      button: true,
      label: '${producto.nombre}. '
          '${producto.precioVenta.format()}. '
          '${producto.agotado ? "Agotado" : producto.bajoStock ? "Stock bajo" : "Disponible"}. '
          'Toca para agregar al carrito.',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: context.duracion(Motion.rapida),
        curve: Motion.entrada,
        decoration: BoxDecoration(
          // La baldosa se tiñe un instante al añadirla: confirma sin tapar nada.
          color: recienTocado
              ? dominio.exitoContenedor
              : context.colores.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: recienTocado ? dominio.exito : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: fondoStock,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icono además del color: el estado de stock no puede
                          // depender sólo del color (WCAG 1.4.1) ni perderse con
                          // el brillo al mínimo bajo el sol.
                          if (producto.agotado || producto.bajoStock) ...[
                            Icon(
                              producto.agotado
                                  ? Icons.error_rounded
                                  : Icons.warning_amber_rounded,
                              size: 11,
                              color: colorStock,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            producto.stock.format(),
                            style: context.textos.labelSmall?.copyWith(
                              color: colorStock,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (recienTocado)
                      Icon(Icons.check_circle_rounded, size: 16, color: dominio.exito)
                          .animate()
                          .scaleXY(begin: 0.4, duration: Motion.rapida, curve: Motion.enfasis),
                  ],
                ),
                const Spacer(),
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  producto.precioVenta.format(),
                  style: context.textos.titleSmall?.copyWith(color: context.colores.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PieCarrito extends StatelessWidget {
  const _PieCarrito({
    required this.articulos,
    required this.total,
    required this.onCobrar,
  });

  final int articulos;
  final Money total;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colores.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$articulos artículo${articulos == 1 ? '' : 's'}',
                    style: context.textos.labelMedium?.copyWith(
                      color: context.colores.onSurfaceVariant,
                    ),
                  ),
                  ContadorMoney(
                    total,
                    style: context.textos.titleLarge,
                    duracion: Motion.media,
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onCobrar,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Listo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final _frecuentesProvider = StreamProvider.autoDispose<List<ProductoConCategoria>>(
  (ref) => ref.watch(productosDaoProvider).observarFrecuentes(limite: 24),
);

final _resultadosProvider =
    StreamProvider.autoDispose.family<List<ProductoConCategoria>, String>(
  (ref, busqueda) =>
      ref.watch(productosDaoProvider).observar(busqueda: busqueda, limite: 60),
);
