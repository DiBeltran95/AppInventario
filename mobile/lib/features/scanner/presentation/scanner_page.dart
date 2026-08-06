import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/daos/productos_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../ventas/presentation/carrito_provider.dart';
import '../domain/modo_escaner.dart';
import 'marco_escaner.dart';
import 'panel_venta_rapida.dart';

/// Pantalla de escaneo.
///
/// Tres decisiones sostienen esta pantalla:
///
/// 1. **La cámara no se cierra al detectar.** En modo venta, el resultado
///    aparece en una tarjeta sobre el visor y se sigue escaneando. Vender 20
///    artículos no puede costar 20 aperturas de cámara.
/// 2. **Confirmación implícita.** Se añade al carrito de inmediato con háptico
///    y marco verde, y se ofrece «Deshacer» durante unos segundos. Preguntar
///    «¿confirmar?» por artículo duplica los toques sin evitar errores.
/// 3. **La resolución del código es local.** Se consulta SQLite, nunca la red:
///    por eso el escáner responde igual en modo avión.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key, required this.modo});

  final ModoEscaner modo;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  late final MobileScannerController _controlador = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
    // Se declaran los formatos en vez de aceptar todos: limitar el conjunto
    // acelera el reconocimiento y evita que un QR de wifi pegado en la pared
    // se lea como si fuera un producto.
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf14,
    ],
  );

  /// Antirrebote: la cámara emite el mismo código decenas de veces por segundo.
  String? _ultimoCodigo;
  DateTime _ultimaLectura = DateTime.fromMillisecondsSinceEpoch(0);

  bool _procesando = false;
  bool _linterna = false;
  _Resultado? _resultado;
  Timer? _temporizadorResultado;

  @override
  void dispose() {
    _temporizadorResultado?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  // ── Detección ─────────────────────────────────────────────────────────────

  void _alDetectar(BarcodeCapture captura) {
    if (_procesando) return;

    final codigo = captura.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (codigo == null) return;

    final ahora = DateTime.now();
    if (codigo == _ultimoCodigo &&
        ahora.difference(_ultimaLectura) < AppConfig.ventanaAntirrebote) {
      return;
    }
    _ultimoCodigo = codigo;
    _ultimaLectura = ahora;

    unawaited(_procesar(codigo.trim()));
  }

  Future<void> _procesar(String codigo) async {
    setState(() => _procesando = true);

    try {
      // En modo «capturar código» no se resuelve nada: el formulario que abrió
      // la cámara sólo quiere el texto leído.
      if (widget.modo == ModoEscaner.capturarCodigo) {
        await HapticFeedback.mediumImpact();
        if (mounted) context.pop(codigo);
        return;
      }

      final resolucion = await ref.read(productosDaoProvider).resolverCodigo(codigo);

      if (!mounted) return;

      if (resolucion == null) {
        await HapticFeedback.heavyImpact();
        _mostrarResultado(_Resultado.noEncontrado(codigo));
        return;
      }

      await HapticFeedback.mediumImpact();
      unawaited(SystemSound.play(SystemSoundType.click));

      switch (widget.modo) {
        case ModoEscaner.venta:
          ref.read(carritoProvider.notifier).agregar(
                resolucion.producto,
                cantidad: resolucion.factor,
              );
          _mostrarResultado(_Resultado.agregado(resolucion));

        case ModoEscaner.entrada:
          if (mounted) {
            context.pushReplacement(
              '${Rutas.entrada}?producto=${resolucion.producto.uuid}',
            );
          }

        case ModoEscaner.consulta:
          if (mounted) {
            context.pushReplacement(Rutas.productoDetalle(resolucion.producto.uuid));
          }

        case ModoEscaner.capturarCodigo:
          break; // resuelto arriba
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarResultado(_Resultado resultado) {
    _temporizadorResultado?.cancel();
    setState(() => _resultado = resultado);

    // El resultado desaparece solo: en modo continuo, una tarjeta que exige un
    // toque para cerrarse convierte cada escaneo en dos gestos.
    if (resultado.encontrado) {
      _temporizadorResultado = Timer(AppConfig.ventanaDeshacer, () {
        if (mounted) setState(() => _resultado = null);
      });
    }
  }

  void _deshacer() {
    ref.read(carritoProvider.notifier).deshacerUltimo();
    HapticFeedback.lightImpact();
    _temporizadorResultado?.cancel();
    setState(() {
      _resultado = null;
      // Se limpia el antirrebote para poder volver a escanear el mismo código
      // inmediatamente después de deshacer.
      _ultimoCodigo = null;
    });
  }

  Future<void> _crearProductoCon(String codigo) async {
    _temporizadorResultado?.cancel();
    setState(() => _resultado = null);
    await context.push('${Rutas.productoNuevo}?codigo=$codigo');
    // Al volver del formulario se limpia el antirrebote: el código que antes no
    // existía ahora sí resuelve, y el usuario querrá escanearlo enseguida.
    _ultimoCodigo = null;
  }

  // ── Construcción ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final esVenta = widget.modo == ModoEscaner.venta;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controlador,
            onDetect: _alDetectar,
            fit: BoxFit.cover,
            errorBuilder: (context, error) => _ErrorCamara(
              error: error,
              onReintentar: () => _controlador.start(),
            ),
            placeholderBuilder: (context) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ),
            overlayBuilder: (context, restricciones) => MarcoEscaner(
              exito: _resultado?.encontrado ?? false,
              error: _resultado != null && !_resultado!.encontrado,
            ),
          ),

          _BarraSuperior(
            titulo: widget.modo.titulo,
            ayuda: widget.modo.ayuda,
            linternaEncendida: _linterna,
            onLinterna: () async {
              await _controlador.toggleTorch();
              if (mounted) setState(() => _linterna = !_linterna);
            },
            onCambiarCamara: () => _controlador.switchCamera(),
            onCerrar: () => context.pop(),
          ),

          // Todo lo inferior se apila en una sola columna. Antes cada pieza
          // llevaba su propio `bottom:` calculado a ojo y bastaba con que la
          // barra del carrito creciera un poco para que se solaparan.
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_resultado != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TarjetaResultado(
                      resultado: _resultado!,
                      modo: widget.modo,
                      onDeshacer: esVenta ? _deshacer : null,
                      onCrear: () => _crearProductoCon(_resultado!.codigo),
                      onCerrar: () {
                        _temporizadorResultado?.cancel();
                        setState(() => _resultado = null);
                      },
                    ),
                  ),

                if (esVenta) ...[
                  _BotonVentaRapida(onTap: _abrirVentaRapida),
                  const SizedBox(height: 12),
                ],

                if (esVenta && carrito.lineas.isNotEmpty)
                  _BarraCarrito(
                    articulos: carrito.articulos,
                    total: carrito.total,
                    onCobrar: () => context.push(Rutas.carrito),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Abre la rejilla de venta rápida y pausa la cámara mientras está encima.
  ///
  /// Sin pausarla, la cámara seguiría detectando códigos tras la hoja y
  /// añadiría productos que el usuario no ve.
  Future<void> _abrirVentaRapida() async {
    await _controlador.stop();
    if (!mounted) return;
    await PanelVentaRapida.mostrar(context);
    if (!mounted) return;
    await _controlador.start();
  }
}

/// Acceso a la rejilla de venta rápida.
///
/// Con un catálogo pequeño, tocar suele ser más rápido que escanear, y siempre
/// es la salida cuando una etiqueta no se deja leer. Por eso está en la zona
/// del pulgar y no escondido en un menú.
class _BotonVentaRapida extends StatelessWidget {
  const _BotonVentaRapida({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_view_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Tocar para vender',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Resultado de una lectura ───────────────────────────────────────────────

class _Resultado {
  const _Resultado._({
    required this.codigo,
    this.producto,
    this.cantidad,
  });

  factory _Resultado.agregado(ResolucionCodigo resolucion) => _Resultado._(
        codigo: resolucion.producto.sku,
        producto: resolucion.producto,
        cantidad: resolucion.factor,
      );

  factory _Resultado.noEncontrado(String codigo) => _Resultado._(codigo: codigo);

  final String codigo;
  final ProductoConCategoria? producto;
  final Cantidad? cantidad;

  bool get encontrado => producto != null;
}

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({
    required this.resultado,
    required this.modo,
    required this.onCrear,
    required this.onCerrar,
    this.onDeshacer,
  });

  final _Resultado resultado;
  final ModoEscaner modo;
  final VoidCallback onCrear;
  final VoidCallback onCerrar;
  final VoidCallback? onDeshacer;

  @override
  Widget build(BuildContext context) {
    final tarjeta = resultado.encontrado
        ? _contenidoEncontrado(context)
        : _contenidoNoEncontrado(context);

    return Material(
      color: context.colores.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: tarjeta),
    )
        .animate()
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.25, duration: 260.ms, curve: Curves.easeOutCubic);
  }

  Widget _contenidoEncontrado(BuildContext context) {
    final producto = resultado.producto!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.dominio.exitoContenedor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_rounded,
                color: context.dominio.exito,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textos.titleMedium,
                  ),
                  Text(
                    '${producto.sku} · ${producto.precioVenta.format()}',
                    style: context.textos.bodySmall?.copyWith(
                      color: context.colores.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (resultado.cantidad != null &&
                resultado.cantidad!.milesimas != 1000) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('×${resultado.cantidad!.format()}'),
                backgroundColor: context.colores.secondaryContainer,
              ),
            ],
          ],
        ),
        if (producto.agotado) ...[
          const SizedBox(height: 10),
          _Aviso(
            texto: 'Sin stock registrado. La venta se registra igual y quedará '
                'en negativo hasta que ajustes el inventario.',
            color: context.dominio.advertencia,
            fondo: context.dominio.advertenciaContenedor,
          ),
        ],
        if (onDeshacer != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeshacer,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Deshacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onCerrar,
                  child: const Text('Seguir'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _contenidoNoEncontrado(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.dominio.advertenciaContenedor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: context.dominio.advertencia,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Código no registrado', style: context.textos.titleMedium),
                  Text(
                    resultado.codigo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textos.bodySmall?.copyWith(
                      color: context.colores.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCerrar,
                child: const Text('Reintentar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onCrear,
                child: const Text('Crear producto'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.color, required this.fondo});

  final String texto;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(10)),
      child: Text(
        texto,
        style: context.textos.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

// ─── Cromo de la pantalla ───────────────────────────────────────────────────

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.titulo,
    required this.ayuda,
    required this.linternaEncendida,
    required this.onLinterna,
    required this.onCambiarCamara,
    required this.onCerrar,
  });

  final String titulo;
  final String ayuda;
  final bool linternaEncendida;
  final VoidCallback onLinterna;
  final VoidCallback onCambiarCamara;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              _BotonCromo(icono: Icons.close_rounded, onTap: onCerrar, etiqueta: 'Cerrar'),
              const Spacer(),
              Text(
                titulo,
                style: context.textos.titleMedium?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              _BotonCromo(
                icono: linternaEncendida
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
                onTap: onLinterna,
                etiqueta: 'Linterna',
                activo: linternaEncendida,
              ),
              _BotonCromo(
                icono: Icons.cameraswitch_rounded,
                onTap: onCambiarCamara,
                etiqueta: 'Cambiar cámara',
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              ayuda,
              textAlign: TextAlign.center,
              style: context.textos.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonCromo extends StatelessWidget {
  const _BotonCromo({
    required this.icono,
    required this.onTap,
    required this.etiqueta,
    this.activo = false,
  });

  final IconData icono;
  final VoidCallback onTap;
  final String etiqueta;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: activo ? Colors.white : Colors.black.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onTap,
          tooltip: etiqueta,
          icon: Icon(icono, color: activo ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}

class _BarraCarrito extends StatelessWidget {
  const _BarraCarrito({
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
      color: context.colores.primary,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      child: InkWell(
        onTap: onCobrar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Badge.count(
                count: articulos,
                backgroundColor: context.colores.onPrimary,
                textColor: context.colores.primary,
                child: Icon(
                  Icons.shopping_cart_rounded,
                  color: context.colores.onPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cobrar',
                      style: context.textos.labelMedium?.copyWith(
                        color: context.colores.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      total.format(),
                      style: context.textos.titleLarge
                          ?.copyWith(color: context.colores.onPrimary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: context.colores.onPrimary),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.4, duration: 280.ms, curve: Curves.easeOutCubic).fadeIn();
  }
}

class _ErrorCamara extends StatelessWidget {
  const _ErrorCamara({required this.error, required this.onReintentar});

  final MobileScannerException error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final sinPermiso =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                sinPermiso ? 'Sin permiso de cámara' : 'No se pudo abrir la cámara',
                textAlign: TextAlign.center,
                style: context.textos.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                sinPermiso
                    ? 'Concede el permiso de cámara a la app desde los ajustes '
                        'del sistema para poder escanear códigos.'
                    : error.errorDetails?.message ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: context.textos.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Volver'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: onReintentar, child: const Text('Reintentar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
