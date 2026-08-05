import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/productos_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../productos/presentation/productos_providers.dart';

/// Entrada de mercancía.
///
/// El flujo es escanear → confirmar → guardar, en una sola pantalla y sin
/// diálogos intermedios. Al recibir un pedido se repite decenas de veces
/// seguidas, así que tras guardar la pantalla se **reinicia** en vez de
/// cerrarse: quien está descargando una caja quiere seguir con el siguiente
/// artículo, no volver al menú.
class EntradaPage extends ConsumerStatefulWidget {
  const EntradaPage({super.key, this.productoUuid});

  final String? productoUuid;

  @override
  ConsumerState<EntradaPage> createState() => _EntradaPageState();
}

class _EntradaPageState extends ConsumerState<EntradaPage> {
  final _formulario = GlobalKey<FormState>();
  final _cantidad = TextEditingController(text: '1');
  final _costo = TextEditingController();
  final _lote = TextEditingController();
  final _documento = TextEditingController();

  String? _productoUuid;
  String? _proveedorUuid;
  String _tipo = 'ENTRADA';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _productoUuid = widget.productoUuid;
    _precargarCosto();
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _costo.dispose();
    _lote.dispose();
    _documento.dispose();
    super.dispose();
  }

  /// El costo se precarga con el de la última compra: en la mayoría de las
  /// entradas no cambia, y reescribirlo cada vez es trabajo inútil.
  Future<void> _precargarCosto() async {
    final uuid = _productoUuid;
    if (uuid == null) return;
    final item = await ref.read(productosDaoProvider).obtener(uuid);
    if (item != null && mounted && _costo.text.isEmpty) {
      _costo.text = item.precioCompra.esCero ? '' : item.precioCompra.formatSinSimbolo();
    }
  }

  Future<void> _elegirProducto() async {
    final uuid = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SelectorProducto(),
    );
    if (uuid == null) return;
    setState(() => _productoUuid = uuid);
    _costo.clear();
    await _precargarCosto();
  }

  Future<void> _escanear() async {
    final resultado = await context.push<String>('${Rutas.escanear}?modo=codigo');
    if (resultado == null || !mounted) return;

    final resolucion = await ref.read(productosDaoProvider).resolverCodigo(resultado);
    if (!mounted) return;

    if (resolucion == null) {
      mostrarMensaje(
        context,
        'Código no registrado',
        esError: true,
        accion: SnackBarAction(
          label: 'Crear',
          onPressed: () => context.push('${Rutas.productoNuevo}?codigo=$resultado'),
        ),
      );
      return;
    }

    setState(() => _productoUuid = resolucion.producto.uuid);
    _costo.clear();
    await _precargarCosto();
  }

  Future<void> _guardar() async {
    if (_productoUuid == null) {
      mostrarMensaje(context, 'Elige un producto primero', esError: true);
      return;
    }
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    FocusScope.of(context).unfocus();

    try {
      final cantidad = Cantidad.parse(_cantidad.text.replaceAll(',', '.'));
      final costo = _costo.text.trim().isEmpty
          ? null
          : Money.parse(_costo.text.replaceAll('.', '').replaceAll(',', '.'));

      await ref.read(inventarioDaoProvider).registrarMovimiento(
            productoUuid: _productoUuid!,
            tipo: _tipo,
            cantidad: cantidad,
            costoUnitario: costo,
            proveedorUuid: _proveedorUuid,
            usuarioUuid: ref.read(sesionProvider).value?.usuarioUuid,
            lote: _lote.text.trim().isEmpty ? null : _lote.text.trim(),
            documentoRef: _documento.text.trim().isEmpty ? null : _documento.text.trim(),
          );

      // La venta ya está a salvo en SQLite; esto sólo adelanta el envío.
      ref.read(syncEngineProvider).solicitar();
      await HapticFeedback.mediumImpact();

      if (!mounted) return;
      mostrarMensaje(context, 'Movimiento registrado', esExito: true);

      // Reinicio para el siguiente artículo, conservando proveedor y documento:
      // toda la caja que se está recibiendo viene de la misma factura.
      setState(() {
        _productoUuid = null;
        _guardando = false;
      });
      _cantidad.text = '1';
      _costo.clear();
      _lote.clear();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarMensaje(context, 'No se pudo registrar: $e', esError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedores = ref.watch(proveedoresProvider).value ?? const <Proveedor>[];
    final producto = _productoUuid == null
        ? null
        : ref.watch(productoProvider(_productoUuid!)).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de mercancía'),
        actions: [
          IconButton(
            onPressed: _escanear,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear',
          ),
        ],
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _SelectorProductoActual(
              producto: producto,
              onElegir: _elegirProducto,
              onEscanear: _escanear,
            ),
            const SizedBox(height: 20),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'ENTRADA',
                  label: Text('Entrada'),
                  icon: Icon(Icons.add_rounded),
                ),
                ButtonSegment(
                  value: 'DEVOLUCION',
                  label: Text('Devolución'),
                  icon: Icon(Icons.undo_rounded),
                ),
                ButtonSegment(
                  value: 'MERMA',
                  label: Text('Merma'),
                  icon: Icon(Icons.delete_outline_rounded),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidad,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // Repinta la previsualización de stock a cada pulsación:
                    // ver «12 → 24» mientras se teclea es lo que hace útil el
                    // bloque de abajo.
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      suffixText: producto?.producto.unidadMedida ?? 'UND',
                    ),
                    validator: (v) {
                      final cantidad = Cantidad.tryParse((v ?? '').replaceAll(',', '.'));
                      if (cantidad.esCero) return 'Indica una cantidad';
                      if (cantidad.esNegativa) return 'Debe ser positiva';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _costo,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Costo unitario',
                      prefixText: r'$ ',
                    ),
                    // El costo es opcional en merma y devolución: no siempre se
                    // conoce, y exigirlo bloquearía el registro del movimiento.
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return null;
                      try {
                        Money.parse(v!.replaceAll('.', '').replaceAll(',', '.'));
                        return null;
                      } on FormatException {
                        return 'Importe no válido';
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_tipo == 'ENTRADA') ...[
              const SizedBox(height: 8),
              Text(
                'El costo de la última entrada pasa a ser el costo de compra del '
                'producto y se usa para calcular el margen.',
                style: context.textos.bodySmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),

            if (proveedores.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _proveedorUuid,
                decoration: const InputDecoration(labelText: 'Proveedor (opcional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin proveedor')),
                  for (final p in proveedores)
                    DropdownMenuItem(value: p.uuid, child: Text(p.nombre)),
                ],
                onChanged: (v) => setState(() => _proveedorUuid = v),
              ),
              const SizedBox(height: 14),
            ],

            TextFormField(
              controller: _documento,
              decoration: const InputDecoration(
                labelText: 'Factura o remisión (opcional)',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lote,
              decoration: const InputDecoration(
                labelText: 'Lote (opcional)',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),

            if (producto != null) ...[
              const SizedBox(height: 24),
              _Previsualizacion(
                producto: producto,
                cantidad: Cantidad.tryParse(_cantidad.text.replaceAll(',', '.')),
                tipo: _tipo,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _guardando || _productoUuid == null ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_guardando ? 'Guardando…' : 'Registrar movimiento'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
        ),
      ),
    );
  }
}

// ─── Piezas ─────────────────────────────────────────────────────────────────

class _SelectorProductoActual extends StatelessWidget {
  const _SelectorProductoActual({
    required this.producto,
    required this.onElegir,
    required this.onEscanear,
  });

  final ProductoConCategoria? producto;
  final VoidCallback onElegir;
  final VoidCallback onEscanear;

  @override
  Widget build(BuildContext context) {
    if (producto == null) {
      return Card(
        color: context.colores.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 36,
                color: context.colores.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text('¿Qué estás recibiendo?', style: context.textos.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Escanea el código del producto o búscalo en el catálogo.',
                textAlign: TextAlign.center,
                style: context.textos.bodySmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onElegir,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Buscar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEscanear,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Escanear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.colores.primaryContainer,
          child: Icon(
            Icons.inventory_2_rounded,
            color: context.colores.onPrimaryContainer,
          ),
        ),
        title: Text(producto!.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${producto!.sku} · stock '
          '${producto!.stock.formatConUnidad(producto!.producto.unidadMedida)}',
        ),
        trailing: IconButton(
          onPressed: onElegir,
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Cambiar producto',
        ),
      ),
    );
  }
}

/// Muestra cómo quedará el stock. Ver «12 → 24» antes de guardar evita el error
/// clásico de teclear la cantidad en el campo del costo.
class _Previsualizacion extends StatelessWidget {
  const _Previsualizacion({
    required this.producto,
    required this.cantidad,
    required this.tipo,
  });

  final ProductoConCategoria producto;
  final Cantidad cantidad;
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final resta = tipo == 'MERMA';
    final resultado = resta
        ? producto.stock - cantidad
        : producto.stock + cantidad;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            producto.stock.format(),
            style: context.textos.titleLarge?.copyWith(
              color: context.colores.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward_rounded, size: 20),
          const SizedBox(width: 16),
          Text(
            resultado.format(),
            style: context.textos.headlineSmall?.copyWith(
              color: resultado.esNegativa
                  ? context.dominio.peligro
                  : context.dominio.exito,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            producto.producto.unidadMedida.toLowerCase(),
            style: context.textos.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Buscador de productos en hoja inferior.
class _SelectorProducto extends ConsumerStatefulWidget {
  const _SelectorProducto();

  @override
  ConsumerState<_SelectorProducto> createState() => _SelectorProductoState();
}

class _SelectorProductoState extends ConsumerState<_SelectorProducto> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final productos = ref
            .watch(
              productosBusquedaProvider(_busqueda),
            )
            .value ??
        const <ProductoConCategoria>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar producto',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: productos.isEmpty
                  ? const EstadoVacio(
                      icono: Icons.search_off_rounded,
                      titulo: 'Sin resultados',
                      compacto: true,
                    )
                  : ListView.builder(
                      itemCount: productos.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(productos[i].nombre),
                        subtitle: Text(
                          '${productos[i].sku} · stock ${productos[i].stock.format()}',
                        ),
                        onTap: () => Navigator.pop(context, productos[i].uuid),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Búsqueda puntual, independiente de los filtros del catálogo: elegir un
/// producto aquí no debe alterar lo que el usuario dejó filtrado en la lista.
final productosBusquedaProvider =
    StreamProvider.family<List<ProductoConCategoria>, String>(
  (ref, busqueda) =>
      ref.watch(productosDaoProvider).observar(busqueda: busqueda, limite: 60),
);
