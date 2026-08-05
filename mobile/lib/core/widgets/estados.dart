import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Estado vacío con acción.
///
/// Un vacío no es un error: casi siempre significa «aún no has hecho esto».
/// Por eso siempre lleva el siguiente paso a mano en lugar de dejar al usuario
/// mirando una pantalla en blanco.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.descripcion,
    this.textoAccion,
    this.onAccion,
    this.compacto = false,
  });

  final IconData icono;
  final String titulo;
  final String? descripcion;
  final String? textoAccion;
  final VoidCallback? onAccion;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compacto ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compacto ? 14 : 20),
              decoration: BoxDecoration(
                color: context.colores.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                size: compacto ? 28 : 40,
                color: context.colores.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compacto ? 12 : 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: (compacto ? context.textos.titleSmall : context.textos.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (descripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                descripcion!,
                textAlign: TextAlign.center,
                style: context.textos.bodyMedium?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
            ],
            if (textoAccion != null && onAccion != null) ...[
              SizedBox(height: compacto ? 16 : 24),
              FilledButton.tonal(onPressed: onAccion, child: Text(textoAccion!)),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
    );
  }
}

class EstadoError extends StatelessWidget {
  const EstadoError({super.key, required this.mensaje, this.onReintentar});

  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return EstadoVacio(
      icono: Icons.error_outline_rounded,
      titulo: 'Algo salió mal',
      descripcion: mensaje,
      textoAccion: onReintentar != null ? 'Reintentar' : null,
      onAccion: onReintentar,
    );
  }
}

/// Esqueleto de carga.
///
/// Se usa en lugar de un `CircularProgressIndicator` porque adelanta la FORMA
/// de lo que va a aparecer: la pantalla no «salta» al llegar los datos y la
/// espera se percibe más corta.
class SkeletonLista extends StatelessWidget {
  const SkeletonLista({super.key, this.filas = 6, this.alturaFila = 76});

  final int filas;
  final double alturaFila;

  @override
  Widget build(BuildContext context) {
    final base = context.colores.surfaceContainerHighest;
    final brillo = context.colores.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: brillo,
      period: const Duration(milliseconds: 1400),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filas,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: alturaFila,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class SkeletonBloque extends StatelessWidget {
  const SkeletonBloque({super.key, this.alto = 120, this.ancho = double.infinity});

  final double alto;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colores.surfaceContainerHighest,
      highlightColor: context.colores.surfaceContainerLow,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: ancho,
        height: alto,
        decoration: BoxDecoration(
          color: context.colores.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// Marca de verificación animada, dibujada a mano.
///
/// Se dibuja con `CustomPainter` en vez de usar Lottie: una animación de éxito
/// no justifica añadir una dependencia que además necesita un archivo .json
/// externo que habría que empaquetar y mantener.
class CheckAnimado extends StatefulWidget {
  const CheckAnimado({
    super.key,
    this.tamano = 72,
    this.color,
    this.duracion = const Duration(milliseconds: 620),
  });

  final double tamano;
  final Color? color;
  final Duration duracion;

  @override
  State<CheckAnimado> createState() => _CheckAnimadoState();
}

class _CheckAnimadoState extends State<CheckAnimado> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador =
      AnimationController(vsync: this, duration: widget.duracion)..forward();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.dominio.exito;
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.tamano),
        painter: _PintorCheck(progreso: _controlador.value, color: color),
      ),
    );
  }
}

class _PintorCheck extends CustomPainter {
  _PintorCheck({required this.progreso, required this.color});

  final double progreso;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2 - 3;

    // El círculo se dibuja en el primer 55 % y el trazo en el resto: el ojo lee
    // «se cerró el círculo, luego se confirmó».
    final avanceCirculo = (progreso / 0.55).clamp(0.0, 1.0);
    final avanceTrazo = ((progreso - 0.45) / 0.55).clamp(0.0, 1.0);

    final lapiz = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -1.5708,
      6.2832 * Curves.easeOutCubic.transform(avanceCirculo),
      false,
      lapiz,
    );

    if (avanceTrazo <= 0) return;

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.73, size.height * 0.35);

    final t = Curves.easeOutCubic.transform(avanceTrazo);
    final ruta = Path()..moveTo(p1.dx, p1.dy);

    if (t <= 0.45) {
      final f = t / 0.45;
      ruta.lineTo(p1.dx + (p2.dx - p1.dx) * f, p1.dy + (p2.dy - p1.dy) * f);
    } else {
      ruta.lineTo(p2.dx, p2.dy);
      final f = (t - 0.45) / 0.55;
      ruta.lineTo(p2.dx + (p3.dx - p2.dx) * f, p2.dy + (p3.dy - p2.dy) * f);
    }

    canvas.drawPath(ruta, lapiz);
  }

  @override
  bool shouldRepaint(_PintorCheck anterior) =>
      anterior.progreso != progreso || anterior.color != color;
}

/// Snackbar con identidad, en lugar del gris por defecto.
void mostrarMensaje(
  BuildContext context,
  String texto, {
  bool esError = false,
  bool esExito = false,
  SnackBarAction? accion,
  Duration duracion = const Duration(seconds: 3),
}) {
  final dominio = context.dominio;
  final (fondo, frente, icono) = esError
      ? (dominio.peligroContenedor, dominio.peligro, Icons.error_outline_rounded)
      : esExito
          ? (dominio.exitoContenedor, dominio.exito, Icons.check_circle_outline_rounded)
          : (
              context.colores.inverseSurface,
              context.colores.onInverseSurface,
              Icons.info_outline_rounded,
            );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: frente, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(texto, style: TextStyle(color: frente, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: fondo,
        duration: duracion,
        action: accion,
      ),
    );
}
