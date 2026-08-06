import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/imagen_producto.dart';
import 'productos_providers.dart';

/// Alta y edición de producto.
///
/// La misma pantalla sirve para ambas cosas: los campos son idénticos y
/// mantener dos formularios gemelos garantiza que tarde o temprano divergan.
/// Sólo cambian el título, el botón y la presencia del stock inicial.
class ProductoFormPage extends ConsumerStatefulWidget {
  const ProductoFormPage({super.key, this.uuid, this.codigoInicial});

  /// `null` en un alta.
  final String? uuid;

  /// Código que venía del escáner cuando el producto no existía. Se registra
  /// junto con el producto para que el siguiente escaneo ya lo resuelva.
  final String? codigoInicial;

  @override
  ConsumerState<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends ConsumerState<ProductoFormPage> {
  final _formulario = GlobalKey<FormState>();

  final _nombre = TextEditingController();
  final _sku = TextEditingController();
  final _descripcion = TextEditingController();
  final _precioCompra = TextEditingController();
  final _precioVenta = TextEditingController();
  final _stockMinimo = TextEditingController(text: '0');
  final _stockInicial = TextEditingController(text: '0');
  final _ubicacion = TextEditingController();

  String? _categoriaUuid;
  String _unidad = 'UND';
  TasaIva _iva = const TasaIva(1900);
  String? _rutaImagen;
  String? _codigo;

  bool _cargado = false;
  bool _guardando = false;

  bool get _esEdicion => widget.uuid != null;

  static const _unidades = ['UND', 'KG', 'GR', 'LT', 'ML', 'MT', 'CAJA', 'PAQ'];

  @override
  void initState() {
    super.initState();
    _codigo = widget.codigoInicial;
    if (_esEdicion) {
      _cargarExistente();
    } else {
      _cargado = true;
      // Un SKU tecleado a mano acaba en duplicados y erratas. Se propone uno
      // libre en cuanto hay nombre, y el usuario puede sobrescribirlo.
      _nombre.addListener(_sugerirSku);
    }
  }

  @override
  void dispose() {
    _nombre.removeListener(_sugerirSku);
    _nombre.dispose();
    _sku.dispose();
    _descripcion.dispose();
    _precioCompra.dispose();
    _precioVenta.dispose();
    _stockMinimo.dispose();
    _stockInicial.dispose();
    _ubicacion.dispose();
    super.dispose();
  }

  bool _skuTocado = false;

  Future<void> _sugerirSku() async {
    if (_skuTocado || _nombre.text.trim().length < 3) return;
    final sugerido = await ref.read(productosDaoProvider).sugerirSku(_nombre.text);
    if (mounted && !_skuTocado) _sku.text = sugerido;
  }

  Future<void> _cargarExistente() async {
    final item = await ref.read(productosDaoProvider).obtener(widget.uuid!);
    if (item == null || !mounted) {
      if (mounted) setState(() => _cargado = true);
      return;
    }

    _nombre.text = item.nombre;
    _sku.text = item.sku;
    _descripcion.text = item.producto.descripcion ?? '';
    _precioCompra.text =
        item.precioCompra.esCero ? '' : item.precioCompra.formatSinSimbolo();
    _precioVenta.text = item.precioVenta.esCero ? '' : item.precioVenta.formatSinSimbolo();
    _stockMinimo.text = item.stockMinimo.format();
    _ubicacion.text = item.producto.ubicacion ?? '';

    setState(() {
      _categoriaUuid = item.producto.categoriaUuid;
      _unidad = item.producto.unidadMedida;
      _iva = item.tasaIva;
      _rutaImagen = item.producto.imagenLocal;
      _cargado = true;
    });
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _tomarFoto(ImageSource origen) async {
    try {
      final foto = await ImagePicker().pickImage(
        source: origen,
        // Se reduce en el propio dispositivo: guardar el JPEG de 12 MP de la
        // cámara para una miniatura de 52 px llena la memoria del teléfono.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (foto != null && mounted) setState(() => _rutaImagen = foto.path);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo abrir la cámara: $e', esError: true);
    }
  }

  Future<void> _escanearCodigo() async {
    final codigo = await context.push<String>('${Rutas.escanear}?modo=codigo');
    if (codigo == null || !mounted) return;

    final existente = await ref.read(productosDaoProvider).productoDelCodigo(codigo);
    if (!mounted) return;
    if (existente != null && existente.uuid != widget.uuid) {
      mostrarMensaje(context, 'Ese código ya es de "${existente.nombre}"', esError: true);
      return;
    }
    setState(() => _codigo = codigo);
  }

  Future<void> _guardar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final dao = ref.read(productosDaoProvider);
    final sku = _sku.text.trim();

    // El SKU se comprueba aquí y no al sincronizar: un rechazo diferido de la
    // cola aparecería media hora después, cuando ya nadie recuerda el alta.
    if (!await dao.skuDisponible(sku, exceptoUuid: widget.uuid)) {
      if (mounted) mostrarMensaje(context, 'Ya existe un producto con ese SKU', esError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _guardando = true);

    try {
      final compra = _aMoney(_precioCompra.text);
      final venta = _aMoney(_precioVenta.text);
      final minimo = Cantidad.tryParse(_stockMinimo.text.replaceAll(',', '.'));

      if (_esEdicion) {
        var rutaImagen = _rutaImagen;
        if (rutaImagen != null) {
          rutaImagen =
              await ImagenProducto.persistir(rutaImagen, widget.uuid!) ?? rutaImagen;
        }

        await dao.actualizar(
          widget.uuid!,
          sku: sku,
          nombre: _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          categoriaUuid: _categoriaUuid,
          limpiarCategoria: _categoriaUuid == null,
          unidadMedida: _unidad,
          precioCompra: compra,
          precioVenta: venta,
          tasaIva: _iva,
          stockMinimo: minimo,
          imagenLocal: rutaImagen,
          ubicacion: _ubicacion.text.trim(),
        );

        if (_codigo != null && _codigo!.isNotEmpty) {
          await dao.agregarCodigo(widget.uuid!, _codigo!, _tipoDe(_codigo!));
        }
      } else {
        final uuid = await dao.crear(
          sku: sku,
          nombre: _nombre.text.trim(),
          descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
          categoriaUuid: _categoriaUuid,
          unidadMedida: _unidad,
          precioCompra: compra,
          precioVenta: venta,
          tasaIva: _iva,
          stockMinimo: minimo,
          imagenLocal: _rutaImagen,
          ubicacion: _ubicacion.text.trim().isEmpty ? null : _ubicacion.text.trim(),
          codigos: _codigo == null || _codigo!.isEmpty
              ? const []
              : [(codigo: _codigo!, tipo: _tipoDe(_codigo!))],
        );

        // La ruta de image_picker es temporal: se copia a Documents para que
        // sobreviva al reinicio y el SyncEngine pueda subirla después.
        if (_rutaImagen != null) {
          final permanente = await ImagenProducto.persistir(_rutaImagen, uuid);
          if (permanente != null) await dao.fijarImagenLocal(uuid, permanente);
        }

        // El stock inicial es un movimiento, no una columna que se escribe:
        // así queda en el libro con su fecha y su costo, igual que todo lo
        // demás. El producto nace con stock 0 y este movimiento lo levanta.
        final inicial = Cantidad.tryParse(_stockInicial.text.replaceAll(',', '.'));
        if (!inicial.esCero) {
          await ref.read(inventarioDaoProvider).registrarMovimiento(
                productoUuid: uuid,
                tipo: 'INICIAL',
                cantidad: inicial,
                costoUnitario: compra.esCero ? null : compra,
                usuarioUuid: ref.read(sesionProvider).value?.usuarioUuid,
                motivo: 'Inventario inicial',
              );
        }
      }

      ref.read(syncEngineProvider).solicitar();
      await HapticFeedback.mediumImpact();

      if (!mounted) return;
      context.pop();
      mostrarMensaje(
        context,
        _esEdicion ? 'Producto actualizado' : 'Producto creado',
        esExito: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarMensaje(context, 'No se pudo guardar: $e', esError: true);
      }
    }
  }

  // ── Construcción ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_cargado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categorias = ref.watch(categoriasProvider).value ?? const <Categoria>[];
    final esAdmin = ref.watch(esAdminProvider);

    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(),
        body: const EstadoVacio(
          icono: Icons.lock_outline_rounded,
          titulo: 'Sin permiso',
          descripcion: 'Sólo un administrador puede crear o editar productos.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          // Arrastrar la lista también baja el teclado (texto y numérico).
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _SelectorImagen(
              ruta: _rutaImagen,
              onCamara: () => _tomarFoto(ImageSource.camera),
              onGaleria: () => _tomarFoto(ImageSource.gallery),
              onQuitar: _rutaImagen == null ? null : () => setState(() => _rutaImagen = null),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'El nombre es obligatorio';
                if (t.length < 2) return 'Demasiado corto';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _sku,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _skuTocado = true,
              decoration: const InputDecoration(
                labelText: 'SKU *',
                helperText: 'Código interno. Debe ser único.',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'El SKU es obligatorio' : null,
            ),
            const SizedBox(height: 14),

            _CampoCodigoBarras(
              codigo: _codigo,
              onEscanear: _escanearCodigo,
              onQuitar: () => setState(() => _codigo = null),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String?>(
              initialValue: _categoriaUuid,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                for (final c in categorias)
                  DropdownMenuItem(value: c.uuid, child: Text(c.nombre)),
              ],
              onChanged: (v) => setState(() => _categoriaUuid = v),
            ),
            const SizedBox(height: 24),

            Text('Precios', style: context.textos.titleSmall),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioCompra,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Costo',
                      prefixText: r'$ ',
                    ),
                    validator: _validarImporte,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioVenta,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Venta *',
                      prefixText: r'$ ',
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Indica el precio';
                      return _validarImporte(v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AvisoMargen(
              compra: _aMoney(_precioCompra.text),
              venta: _aMoney(_precioVenta.text),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<int>(
              initialValue: _iva.escalada,
              decoration: const InputDecoration(
                labelText: 'IVA (incluido en el precio de venta)',
                prefixIcon: Icon(Icons.percent_rounded),
              ),
              items: [
                for (final tasa in TasaIva.comunes)
                  DropdownMenuItem(value: tasa.escalada, child: Text(tasa.format())),
              ],
              onChanged: (v) => setState(() => _iva = TasaIva(v ?? 0)),
            ),
            const SizedBox(height: 24),

            Text('Inventario', style: context.textos.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidad,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: [
                      for (final u in _unidades)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) => setState(() => _unidad = v ?? 'UND'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockMinimo,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                      helperText: 'Avisa al bajar de aquí',
                    ),
                  ),
                ),
              ],
            ),
            if (!_esEdicion) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _stockInicial,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Stock inicial',
                  helperText: 'Se registra como movimiento de inventario inicial',
                  prefixIcon: Icon(Icons.inventory_rounded),
                ),
              ),
            ],
            const SizedBox(height: 14),

            TextFormField(
              controller: _ubicacion,
              decoration: const InputDecoration(
                labelText: 'Ubicación (opcional)',
                helperText: 'Estante, bodega, vitrina…',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descripcion,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_esEdicion ? 'Guardar cambios' : 'Crear producto'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
        ),
      ),
    );
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  /// Acepta lo que la gente teclea de verdad: «12.500», «12500,50», «12500».
  static Money _aMoney(String texto) {
    final limpio = texto.trim().replaceAll('.', '').replaceAll(',', '.');
    if (limpio.isEmpty) return const Money.cero();
    return Money.tryParse(limpio);
  }

  static String? _validarImporte(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final limpio = v!.trim().replaceAll('.', '').replaceAll(',', '.');
    try {
      final valor = Money.parse(limpio);
      return valor.esNegativo ? 'No puede ser negativo' : null;
    } on FormatException {
      return 'Importe no válido';
    }
  }

  static String _tipoDe(String codigo) {
    if (!RegExp(r'^\d+$').hasMatch(codigo)) return 'CODE128';
    return switch (codigo.length) {
      13 => 'EAN13',
      12 => 'UPCA',
      8 => 'EAN8',
      _ => 'INTERNO',
    };
  }
}

// ─── Piezas ─────────────────────────────────────────────────────────────────

class _SelectorImagen extends StatelessWidget {
  const _SelectorImagen({
    required this.ruta,
    required this.onCamara,
    required this.onGaleria,
    this.onQuitar,
  });

  final String? ruta;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCamara,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.colores.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              image: ruta != null && File(ruta!).existsSync()
                  ? DecorationImage(image: FileImage(File(ruta!)), fit: BoxFit.cover)
                  : null,
            ),
            child: ruta != null && File(ruta!).existsSync()
                ? null
                : Icon(
                    Icons.add_a_photo_outlined,
                    color: context.colores.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Foto del producto', style: context.textos.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Opcional. Se guarda en el dispositivo.',
                style: context.textos.bodySmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onGaleria,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Galería'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                  ),
                  if (onQuitar != null)
                    TextButton(onPressed: onQuitar, child: const Text('Quitar')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampoCodigoBarras extends StatelessWidget {
  const _CampoCodigoBarras({
    required this.codigo,
    required this.onEscanear,
    required this.onQuitar,
  });

  final String? codigo;
  final VoidCallback onEscanear;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    if (codigo == null || codigo!.isEmpty) {
      return OutlinedButton.icon(
        onPressed: onEscanear,
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
        label: const Text('Asignar código de barras'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.dominio.exitoContenedor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.barcode_reader, size: 20, color: context.dominio.exito),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código asignado',
                  style: context.textos.labelSmall?.copyWith(color: context.dominio.exito),
                ),
                Text(
                  codigo!,
                  style: context.textos.titleSmall?.copyWith(color: context.dominio.exito),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onQuitar,
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Quitar',
          ),
        ],
      ),
    );
  }
}

/// Aviso de margen mientras se teclea el precio.
///
/// Vender por debajo del costo es un error caro y silencioso: si el aviso no
/// aparece aquí, se descubre al cierre del mes.
class _AvisoMargen extends StatelessWidget {
  const _AvisoMargen({required this.compra, required this.venta});

  final Money compra;
  final Money venta;

  @override
  Widget build(BuildContext context) {
    if (compra.esCero || venta.esCero) return const SizedBox.shrink();

    final margen = venta - compra;
    final porcentaje = compra.centavos == 0
        ? 0.0
        : margen.centavos / compra.centavos * 100;
    final perdida = margen.esNegativo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: perdida ? context.dominio.peligroContenedor : context.dominio.exitoContenedor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            perdida ? Icons.warning_amber_rounded : Icons.trending_up_rounded,
            size: 16,
            color: perdida ? context.dominio.peligro : context.dominio.exito,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              perdida
                  ? 'Estás vendiendo por debajo del costo (${margen.format()})'
                  : 'Margen ${margen.format()} · ${porcentaje.toStringAsFixed(0)} %',
              style: context.textos.labelMedium?.copyWith(
                color: perdida ? context.dominio.peligro : context.dominio.exito,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
