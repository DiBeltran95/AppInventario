import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Marco de enfoque sobre el visor de la cámara.
///
/// Cumple dos funciones que no son decorativas:
///  · **Dice dónde apuntar.** Sin un recorte visible, la gente acerca el
///    teléfono hasta pegarlo al código y la cámara pierde el enfoque.
///  · **Confirma la lectura sin texto.** El marco pasa a verde (o a ámbar si el
///    código no está registrado) antes de que el usuario alcance a leer nada.
///    Es el canal de feedback más rápido que hay, junto con el háptico.
///
/// Se dibuja con `CustomPaint` y no con imágenes: cualquier tamaño de pantalla
/// queda nítido y no hay assets que empaquetar.
class MarcoEscaner extends StatefulWidget {
  const MarcoEscaner({
    super.key,
    this.exito = false,
    this.error = false,
    this.proporcion = 0.72,
  });

  /// Código leído y resuelto correctamente.
  final bool exito;

  /// Código leído pero no reconocido.
  final bool error;

  /// Ancho del recorte respecto al de la pantalla.
  final double proporcion;

  @override
  State<MarcoEscaner> createState() => _MarcoEscanerState();
}

class _MarcoEscanerState extends State<MarcoEscaner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barrido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _barrido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dominio = context.dominio;
    final color = widget.exito
        ? dominio.exito
        : widget.error
            ? dominio.advertencia
            : Colors.white;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _barrido,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _PintorMarco(
            color: color,
            avanceBarrido: _barrido.value,
            // La línea de barrido se detiene al detectar: seguir animando
            // sugiere que la app aún está buscando cuando ya encontró.
            mostrarBarrido: !widget.exito && !widget.error,
            proporcion: widget.proporcion,
          ),
        ),
      ),
    );
  }
}

class _PintorMarco extends CustomPainter {
  _PintorMarco({
    required this.color,
    required this.avanceBarrido,
    required this.mostrarBarrido,
    required this.proporcion,
  });

  final Color color;
  final double avanceBarrido;
  final bool mostrarBarrido;
  final double proporcion;

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.width * proporcion;
    final recorte = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: lado,
      height: lado,
    );
    final redondeado = RRect.fromRectAndRadius(recorte, const Radius.circular(24));

    // Velo oscuro con el recorte en claro. `Path.combine` con difference deja
    // el hueco transparente de una sola pasada, sin capas superpuestas.
    final velo = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(redondeado),
    );
    canvas.drawPath(velo, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Esquinas en L: marcan el área sin encerrarla en un cuadro completo, que
    // compite visualmente con el propio código.
    final lapiz = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final brazo = lado * 0.18;
    final r = 24.0;

    void esquina(Offset origen, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(origen.dx + dx * (brazo + r), origen.dy)
          ..lineTo(origen.dx + dx * r, origen.dy)
          ..arcToPoint(
            Offset(origen.dx, origen.dy + dy * r),
            radius: Radius.circular(r),
            clockwise: dx * dy > 0,
          )
          ..lineTo(origen.dx, origen.dy + dy * (brazo + r)),
        lapiz,
      );
    }

    esquina(recorte.topLeft, 1, 1);
    esquina(recorte.topRight, -1, 1);
    esquina(recorte.bottomLeft, 1, -1);
    esquina(recorte.bottomRight, -1, -1);

    if (!mostrarBarrido) return;

    // Línea de barrido con degradado: sugiere movimiento incluso en la captura
    // de un fotograma, y deja claro que la cámara está activa.
    final y = recorte.top + recorte.height * Curves.easeInOut.transform(avanceBarrido);
    final franja = Rect.fromLTRB(recorte.left + 8, y - 22, recorte.right - 8, y + 2);

    canvas.drawRect(
      franja,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.35)],
        ).createShader(franja),
    );

    canvas.drawLine(
      Offset(recorte.left + 8, y),
      Offset(recorte.right - 8, y),
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PintorMarco anterior) =>
      anterior.avanceBarrido != avanceBarrido ||
      anterior.color != color ||
      anterior.mostrarBarrido != mostrarBarrido;
}
