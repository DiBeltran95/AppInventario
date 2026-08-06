import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/daos/productos_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../ventas/presentation/carrito_provider.dart';
import '../data/etiquetas_pdf.dart';
import 'productos_providers.dart';

/// Ficha de producto.
///
/// Lo primero de la pantalla es el stock, no el nombre: quien abre esta ficha
/// ya sabe qué producto eligió, lo que viene a averiguar es cuánto queda.
class ProductoDetallePage extends ConsumerWidget {
  const ProductoDetallePage({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asincrono = ref.watch(productoProvider(uuid));
    final esAdmin = ref.watch(esAdminProvider);

    return asincrono.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: EstadoError(mensaje: '$e'),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EstadoVacio(
              icono: Icons.search_off_rounded,
              titulo: 'Producto no encontrado',
              descripcion: 'Puede que se haya eliminado desde otro dispositivo.',
              textoAccion: 'Volver',
              onAccion: () => context.pop(),
            ),
          );
        }
        return _Contenido(item: item, esAdmin: esAdmin);
      },
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.item, required this.esAdmin});

  final ProductoConCategoria item;
  final bool esAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominio = context.dominio;
    final (colorStock, fondoStock) = item.agotado
        ? (dominio.peligro, dominio.peligroContenedor)
        : item.bajoStock
            ? (dominio.advertencia, dominio.advertenciaContenedor)
            : (dominio.exito, dominio.exitoContenedor);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.nombre, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: () => _mostrarQr(context, ref, item),
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Código QR',
          ),
          if (esAdmin)
            PopupMenuButton<String>(
              onSelected: (opcion) => switch (opcion) {
                'editar' => context.push(Rutas.productoEditar(item.uuid)),
                'movimientos' =>
                  context.push('${Rutas.movimientos}?producto=${item.uuid}'),
                'ajustar' => _hojaConteo(context, ref, item),
                'eliminar' => _confirmarEliminar(context, ref, item),
                _ => null,
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                const PopupMenuItem(value: 'movimientos', child: Text('Ver movimientos')),
                const PopupMenuItem(value: 'ajustar', child: Text('Ajustar por conteo')),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Text('Eliminar', style: TextStyle(color: dominio.peligro)),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'producto-${item.uuid}',
                child: _Imagen(item: item),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nombre, style: context.textos.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      item.sku,
                      style: context.textos.bodyMedium?.copyWith(
                        color: context.colores.onSurfaceVariant,
                      ),
                    ),
                    if (item.categoria != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(item.categoria!.nombre),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stock ──────────────────────────────────────────────────────
          Card(
            color: fondoStock,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock actual',
                        style: context.textos.labelLarge?.copyWith(color: colorStock),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.stock.formatConUnidad(item.producto.unidadMedida),
                        style: context.textos.displaySmall?.copyWith(color: colorStock),
                      ),
                      Text(
                        'Mínimo: ${item.stockMinimo.format()}',
                        style: context.textos.bodySmall?.copyWith(color: colorStock),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    item.agotado
                        ? Icons.remove_shopping_cart_rounded
                        : item.bajoStock
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                    size: 44,
                    color: colorStock,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.06),

          const SizedBox(height: 16),

          // ── Precios ────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Dato(
                    etiqueta: 'Precio de venta',
                    valor: item.precioVenta.format(),
                    destacado: true,
                  ),
                  _Dato(etiqueta: 'IVA incluido', valor: item.tasaIva.format()),
                  // El vendedor no ve costos ni márgenes: dato sensible del
                  // negocio que no necesita para despachar.
                  if (esAdmin) ...[
                    const Divider(height: 20),
                    _Dato(etiqueta: 'Costo de compra', valor: item.precioCompra.format()),
                    _Dato(
                      etiqueta: 'Margen unitario',
                      valor: item.margenUnitario.format(),
                      color: item.margenUnitario.esNegativo
                          ? dominio.peligro
                          : dominio.exito,
                    ),
                    _Dato(
                      etiqueta: 'Valor en inventario',
                      valor: item.precioCompra.porCantidad(item.stock).format(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _Codigos(uuid: item.uuid, esAdmin: esAdmin),

          if ((item.producto.descripcion ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descripción', style: context.textos.titleSmall),
                    const SizedBox(height: 6),
                    Text(item.producto.descripcion!, style: context.textos.bodyMedium),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          _UltimosMovimientos(uuid: item.uuid),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Cargar mercancía es de administración. Al vendedor el botón
              // sólo le daría un rechazo del enrutador, así que no aparece y
              // «Vender» ocupa todo el ancho: es la única acción que le toca
              // desde aquí, y así queda bajo el pulgar.
              if (esAdmin) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('${Rutas.entrada}?producto=${item.uuid}'),
                    icon: const Icon(Icons.move_to_inbox_rounded),
                    label: const Text('Entrada'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(carritoProvider.notifier).agregar(item);
                    HapticFeedback.mediumImpact();
                    mostrarMensaje(
                      context,
                      '${item.nombre} agregado al carrito',
                      esExito: true,
                      accion: SnackBarAction(
                        label: 'Ver',
                        onPressed: () => context.push(Rutas.carrito),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Vender'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Diálogos ──────────────────────────────────────────────────────────────

  void _mostrarQr(BuildContext context, WidgetRef ref, ProductoConCategoria item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Código QR del producto', style: context.textos.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Imprímelo y pégalo si el producto no trae código de fábrica.',
                textAlign: TextAlign.center,
                style: context.textos.bodySmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Fondo blanco fijo: un QR sobre superficie oscura no lo lee
                  // ningún escáner.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: '${AppConfig.qrPrefix}${item.uuid}',
                  size: 200,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 12),
              Text(item.sku, style: context.textos.titleSmall),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: '${AppConfig.qrPrefix}${item.uuid}'),
                        );
                        Navigator.pop(hoja);
                        mostrarMensaje(context, 'Contenido del QR copiado');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(hoja);
                        await _imprimirEtiquetas(context, ref, item);
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Imprimir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _imprimirEtiquetas(
    BuildContext context,
    WidgetRef ref,
    ProductoConCategoria item,
  ) async {
    final copias = await showDialog<int>(
      context: context,
      builder: (dialogo) {
        var valor = 12;
        return StatefulBuilder(
          builder: (context, refrescar) => AlertDialog(
            title: const Text('Imprimir etiquetas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$valor etiqueta${valor == 1 ? '' : 's'}',
                    style: context.textos.headlineSmall),
                Slider(
                  value: valor.toDouble(),
                  min: 1,
                  max: 48,
                  divisions: 47,
                  label: '$valor',
                  onChanged: (v) => refrescar(() => valor = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogo),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogo, valor),
                child: const Text('Imprimir'),
              ),
            ],
          ),
        );
      },
    );

    if (copias == null) return;

    try {
      await EtiquetasPdf.imprimir(
        [item],
        copiasPorProducto: copias,
        nombreNegocio: ref.read(nombreNegocioProvider),
      );
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo generar el PDF: $e', esError: true);
      }
    }
  }

  void _hojaConteo(BuildContext context, WidgetRef ref, ProductoConCategoria item) {
    final controlador = TextEditingController(text: item.stock.format());

    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Ajustar por conteo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribe cuántas unidades HAY en el estante, no la diferencia. '
              'La app calcula el ajuste y lo registra como movimiento.',
              style: context.textos.bodySmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controlador,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Stock contado',
                suffixText: item.producto.unidadMedida,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final contado = Cantidad.tryParse(controlador.text.replaceAll(',', '.'));
              Navigator.pop(dialogo);
              try {
                await ref.read(inventarioDaoProvider).ajustarPorConteo(
                      productoUuid: item.uuid,
                      stockContado: contado,
                      usuarioUuid: ref.read(sesionProvider).value?.usuarioUuid,
                    );
                ref.read(syncEngineProvider).solicitar();
                if (context.mounted) {
                  mostrarMensaje(context, 'Inventario ajustado', esExito: true);
                }
              } catch (e) {
                if (context.mounted) {
                  mostrarMensaje(context, 'No se pudo ajustar: $e', esError: true);
                }
              }
            },
            child: const Text('Ajustar'),
          ),
        ],
      ),
    ).whenComplete(controlador.dispose);
  }

  void _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    ProductoConCategoria item,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Eliminar el producto?'),
        content: Text(
          'Se marcará como eliminado y dejará de aparecer en el catálogo. '
          'El historial de ventas de "${item.nombre}" se conserva intacto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.dominio.peligro),
            onPressed: () async {
              Navigator.pop(dialogo);
              await ref.read(productosDaoProvider).eliminar(item.uuid);
              ref.read(syncEngineProvider).solicitar();
              if (context.mounted) {
                context.pop();
                mostrarMensaje(context, 'Producto eliminado');
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── Piezas ─────────────────────────────────────────────────────────────────

class _Imagen extends StatelessWidget {
  const _Imagen({required this.item});

  final ProductoConCategoria item;

  @override
  Widget build(BuildContext context) {
    final local = item.producto.imagenLocal;
    final remota = item.producto.imagenUrl;

    Widget marcador() => Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.colores.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: context.colores.onSecondaryContainer,
          ),
        );

    final imagen = local != null && File(local).existsSync()
        ? Image.file(File(local), width: 96, height: 96, fit: BoxFit.cover)
        : (remota != null && remota.isNotEmpty)
            ? Image.network(
                remota,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => marcador(),
              )
            : marcador();

    return ClipRRect(borderRadius: BorderRadius.circular(20), child: imagen);
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
    this.color,
  });

  final String etiqueta;
  final String valor;
  final bool destacado;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: context.textos.bodyMedium?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            valor,
            style: (destacado ? context.textos.titleLarge : context.textos.titleSmall)
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Codigos extends ConsumerWidget {
  const _Codigos({required this.uuid, required this.esAdmin});

  final String uuid;
  final bool esAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codigos = ref.watch(codigosProductoProvider(uuid)).value ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Códigos', style: context.textos.titleSmall),
                const Spacer(),
                if (esAdmin)
                  TextButton.icon(
                    onPressed: () => _agregar(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Añadir'),
                  ),
              ],
            ),
            if (codigos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin códigos de barras. Usa el QR generado por la app.',
                  style: context.textos.bodySmall?.copyWith(
                    color: context.colores.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final codigo in codigos)
                    Chip(
                      label: Text('${codigo.codigo}  ·  ${codigo.tipo}'),
                      onDeleted: esAdmin
                          ? () async {
                              await ref
                                  .read(productosDaoProvider)
                                  .eliminarCodigo(codigo.uuid);
                              ref.invalidate(codigosProductoProvider(uuid));
                            }
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    // Se escanea en lugar de teclear: un EAN-13 mal copiado a mano es un
    // producto que nunca más aparece al escanear.
    final codigo = await context.push<String>('${Rutas.escanear}?modo=codigo');
    if (codigo == null || codigo.isEmpty || !context.mounted) return;

    final dao = ref.read(productosDaoProvider);
    final existente = await dao.productoDelCodigo(codigo);
    if (existente != null) {
      if (context.mounted) {
        mostrarMensaje(
          context,
          'Ese código ya pertenece a "${existente.nombre}"',
          esError: true,
        );
      }
      return;
    }

    await dao.agregarCodigo(uuid, codigo, _tipoDe(codigo));
    ref.read(syncEngineProvider).solicitar();
    ref.invalidate(codigosProductoProvider(uuid));
    if (context.mounted) mostrarMensaje(context, 'Código añadido', esExito: true);
  }

  /// Deduce el tipo por la longitud: es lo que hace cualquier POS con un código
  /// numérico, y el usuario no tiene por qué saber qué es un «UPC-A».
  static String _tipoDe(String codigo) {
    final soloDigitos = RegExp(r'^\d+$').hasMatch(codigo);
    if (!soloDigitos) return 'CODE128';
    return switch (codigo.length) {
      13 => 'EAN13',
      12 => 'UPCA',
      8 => 'EAN8',
      _ => 'INTERNO',
    };
  }
}

class _UltimosMovimientos extends ConsumerWidget {
  const _UltimosMovimientos({required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos =
        ref.watch(movimientosProvider(FiltroMovimientos(productoUuid: uuid, limite: 5)))
                .value ??
            const [];

    if (movimientos.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Últimos movimientos', style: context.textos.titleSmall),
            trailing: TextButton(
              onPressed: () => context.push('${Rutas.movimientos}?producto=$uuid'),
              child: const Text('Ver todo'),
            ),
          ),
          for (final m in movimientos)
            ListTile(
              dense: true,
              leading: Icon(
                m.esEntrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: m.esEntrada ? context.dominio.exito : context.dominio.peligro,
                size: 20,
              ),
              title: Text(m.movimiento.tipo),
              subtitle: Text(m.movimiento.fechaLocal),
              trailing: Text(
                '${m.esEntrada ? '+' : ''}${m.cantidad.format()}',
                style: context.textos.titleSmall?.copyWith(
                  color: m.esEntrada ? context.dominio.exito : context.dominio.peligro,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
