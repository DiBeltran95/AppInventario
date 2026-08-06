import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/ventas_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import 'carrito_provider.dart';
import 'widgets/hoja_cobro.dart';
import 'widgets/venta_exitosa.dart';

/// Carrito y cobro.
///
/// Cobrar **no toca la red**: la venta se escribe en SQLite junto con su
/// entrada en la cola de salida, dentro de una sola transacción. El ticket se
/// imprime desde el dispositivo. Que haya internet o no sólo cambia cuándo
/// llega la venta al servidor, nunca si se puede vender.
class CarritoPage extends ConsumerWidget {
  const CarritoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(carritoProvider);
    final notifier = ref.read(carritoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (!carrito.vacio)
            TextButton.icon(
              onPressed: () => _confirmarVaciar(context, notifier),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Vaciar'),
            ),
        ],
      ),
      body: carrito.vacio
          ? EstadoVacio(
              icono: Icons.shopping_cart_outlined,
              titulo: 'El carrito está vacío',
              descripcion: 'Escanea un producto para empezar a vender.',
              textoAccion: 'Escanear',
              onAccion: () => volverAlEscaner(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final linea in carrito.lineas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FilaCarrito(
                      linea: linea,
                      resaltada: carrito.ultimaAgregada == linea.productoUuid,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  // `volverAlEscaner` reutiliza el escáner que ya está debajo en la
                  // pila. Empujar otro dejaba dos cámaras vivas y la segunda
                  // no podía arrancar.
                  onPressed: () => volverAlEscaner(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir otro producto'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: 20),
                _Totales(carrito: carrito),
                if (carrito.hayExcesoDeStock) ...[
                  const SizedBox(height: 12),
                  const _AvisoSobreventa(),
                ],
              ],
            ),
      bottomNavigationBar: carrito.vacio
          ? null
          : _BarraCobro(
              total: carrito.total,
              articulos: carrito.articulos,
              onCobrar: () => _cobrar(context, ref, carrito),
            ),
    );
  }

  void _confirmarVaciar(BuildContext context, CarritoNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Vaciar el carrito?'),
        content: const Text('Se quitarán todos los productos. La venta no se registra.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              notifier.vaciar();
              Navigator.pop(dialogo);
            },
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cobrar(BuildContext context, WidgetRef ref, CarritoEstado carrito) async {
    final pago = await showModalBottomSheet<ResultadoCobro>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => HojaCobro(total: carrito.total),
    );
    if (pago == null || !context.mounted) return;

    final notifier = ref.read(carritoProvider.notifier);
    notifier.fijarMetodoPago(pago.metodo);

    late VentaCompleta venta;
    try {
      venta = await notifier.cobrar(montoRecibido: pago.recibido);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo registrar la venta: $e', esError: true);
      }
      return;
    }

    await HapticFeedback.heavyImpact();
    if (!context.mounted) return;

    // Pantalla de confirmación a página completa, no un snackbar: el vendedor
    // necesita ver el cambio a devolver y decidir sobre el ticket antes de
    // atender al siguiente cliente.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VentaExitosa(venta: venta),
        fullscreenDialog: true,
      ),
    );

    if (context.mounted) context.pop();
  }
}

// ─── Línea del carrito ──────────────────────────────────────────────────────

class _FilaCarrito extends ConsumerWidget {
  const _FilaCarrito({required this.linea, required this.resaltada});

  final LineaCarrito linea;
  final bool resaltada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(carritoProvider.notifier);

    final tarjeta = Dismissible(
      key: ValueKey(linea.productoUuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: context.dominio.peligroContenedor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.delete_outline_rounded, color: context.dominio.peligro),
      ),
      onDismissed: (_) {
        notifier.quitar(linea.productoUuid);
        HapticFeedback.lightImpact();
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          linea.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textos.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _editarPrecio(context, notifier),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                linea.precioUnitario.format(),
                                style: context.textos.bodySmall?.copyWith(
                                  color: context.colores.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_outlined,
                                size: 13,
                                color: context.colores.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Contador(linea: linea, notifier: notifier),
                  SizedBox(
                    width: 84,
                    child: Text(
                      linea.total.format(),
                      textAlign: TextAlign.right,
                      style: context.textos.titleSmall,
                    ),
                  ),
                ],
              ),
              if (linea.excedeStock) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: context.dominio.advertencia,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sólo hay ${linea.stockDisponible.format()} en inventario. '
                        'Se puede vender igual; el stock quedará en negativo.',
                        style: context.textos.labelSmall
                            ?.copyWith(color: context.dominio.advertencia),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!resaltada) return tarjeta;
    // Destello breve en la línea recién escaneada: confirma qué cambió cuando
    // el carrito tiene quince artículos y la vista no ha hecho scroll.
    return tarjeta.animate().shimmer(
          duration: 700.ms,
          color: context.colores.primary.withValues(alpha: 0.18),
        );
  }

  void _editarPrecio(BuildContext context, CarritoNotifier notifier) {
    final controlador =
        TextEditingController(text: linea.precioUnitario.formatSinSimbolo());

    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(linea.nombre),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Precio unitario', prefixText: r'$ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final limpio =
                  controlador.text.trim().replaceAll('.', '').replaceAll(',', '.');
              final precio = Money.tryParse(limpio);
              if (!precio.esNegativo) {
                notifier.cambiarPrecio(linea.productoUuid, precio);
              }
              Navigator.pop(dialogo);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ).whenComplete(controlador.dispose);
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.linea, required this.notifier});

  final LineaCarrito linea;
  final CarritoNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            notifier.decrementar(linea.productoUuid);
            HapticFeedback.selectionClick();
          },
          icon: const Icon(Icons.remove_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
          tooltip: 'Quitar uno',
        ),
        GestureDetector(
          onTap: () => _editarCantidad(context),
          child: Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: Alignment.center,
            child: Text(linea.cantidad.format(), style: context.textos.titleMedium),
          ),
        ),
        IconButton(
          onPressed: () {
            notifier.incrementar(linea.productoUuid);
            HapticFeedback.selectionClick();
          },
          icon: const Icon(Icons.add_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
          tooltip: 'Añadir uno',
        ),
      ],
    );
  }

  /// Teclear la cantidad importa cuando se venden 24 unidades o 0,750 kg:
  /// pulsar «+» veinticuatro veces no es una interfaz.
  void _editarCantidad(BuildContext context) {
    final controlador = TextEditingController(text: linea.cantidad.format());

    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Cantidad'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cantidad',
            suffixText: linea.unidadMedida,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final cantidad =
                  Cantidad.tryParse(controlador.text.trim().replaceAll(',', '.'));
              notifier.cambiarCantidad(linea.productoUuid, cantidad);
              Navigator.pop(dialogo);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ).whenComplete(controlador.dispose);
  }
}

// ─── Totales y barra de cobro ───────────────────────────────────────────────

class _Totales extends StatelessWidget {
  const _Totales({required this.carrito});

  final CarritoEstado carrito;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _fila(context, 'Base gravable', carrito.subtotal.format()),
            if (!carrito.descuento.esCero)
              _fila(context, 'Descuentos', '-${carrito.descuento.format()}'),
            _fila(context, 'IVA', carrito.impuesto.format()),
            const Divider(height: 20),
            Row(
              children: [
                Text('Total', style: context.textos.titleMedium),
                const Spacer(),
                Text(
                  carrito.total.format(),
                  style: context.textos.headlineSmall
                      ?.copyWith(color: context.colores.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(BuildContext context, String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(
              etiqueta,
              style: context.textos.bodyMedium
                  ?.copyWith(color: context.colores.onSurfaceVariant),
            ),
            const Spacer(),
            Text(valor, style: context.textos.bodyMedium),
          ],
        ),
      );
}

class _AvisoSobreventa extends StatelessWidget {
  const _AvisoSobreventa();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dominio.advertenciaContenedor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: context.dominio.advertencia),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alguna línea supera el stock registrado. La venta se registra igual '
              'y el servidor levantará una alerta para que ajustes el inventario.',
              style: context.textos.bodySmall
                  ?.copyWith(color: context.dominio.advertencia),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraCobro extends StatelessWidget {
  const _BarraCobro({
    required this.total,
    required this.articulos,
    required this.onCobrar,
  });

  final Money total;
  final int articulos;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: onCobrar,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Cobrar $articulos artículo${articulos == 1 ? '' : 's'}'),
              const SizedBox(width: 12),
              Container(width: 1, height: 22, color: context.colores.onPrimary.withValues(alpha: 0.3)),
              const SizedBox(width: 12),
              Text(
                total.format(),
                style: context.textos.titleMedium
                    ?.copyWith(color: context.colores.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
