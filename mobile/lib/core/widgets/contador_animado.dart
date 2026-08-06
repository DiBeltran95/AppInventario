import 'package:flutter/material.dart';

import '../money/money.dart';
import '../theme/motion.dart';

/// Cifras que suben en vez de aparecer de golpe.
///
/// Es la microinteracción con mejor relación impacto/esfuerzo de la app: el
/// importe de «ventas de hoy» es el dato que el dueño abre la app para ver, y
/// una cifra que asciende comunica acumulación además del número.
///
/// Dos detalles que no son cosméticos:
///
/// 1. Se interpola con `IntTween` sobre **centavos enteros**. Un `Tween<double>`
///    metería un coma flotante en el camino del dinero, justo lo que el resto
///    del proyecto evita con `Money`.
/// 2. `FontFeature.tabularFigures()` fija el ancho de los dígitos. Sin ella, con
///    una fuente proporcional el texto tiembla mientras los números cambian.

class ContadorMoney extends StatelessWidget {
  const ContadorMoney(
    this.valor, {
    super.key,
    this.style,
    this.duracion,
    this.textAlign,
  });

  final Money valor;
  final TextStyle? style;
  final Duration? duracion;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final estilo = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return TweenAnimationBuilder<int>(
      // `TweenAnimationBuilder` reanuda desde el valor actual cuando cambia
      // `end`: al entrar una venta nueva, la cifra sube desde donde estaba y no
      // vuelve a empezar en cero.
      tween: IntTween(begin: 0, end: valor.centavos),
      duration: context.duracion(duracion ?? Motion.cifra),
      curve: Curves.easeOutExpo,
      builder: (context, centavos, _) => Text(
        Money(centavos).format(),
        style: estilo,
        textAlign: textAlign,
      ),
    );
  }
}

/// Igual, para conteos enteros (nº de ventas, productos, unidades).
class ContadorEntero extends StatelessWidget {
  const ContadorEntero(
    this.valor, {
    super.key,
    this.style,
    this.duracion,
    this.sufijo,
  });

  final int valor;
  final TextStyle? style;
  final Duration? duracion;
  final String? sufijo;

  @override
  Widget build(BuildContext context) {
    final estilo = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: valor),
      duration: context.duracion(duracion ?? Motion.cifra),
      curve: Curves.easeOutExpo,
      builder: (context, n, _) => Text('$n${sufijo ?? ''}', style: estilo),
    );
  }
}

/// Variación porcentual con flecha y color, animada.
///
/// Devuelve un `SizedBox.shrink()` cuando no hay comparación posible: un
/// «+∞ %» porque ayer no hubo ventas no informa de nada y ensucia la tarjeta.
class VariacionAnimada extends StatelessWidget {
  const VariacionAnimada({
    super.key,
    required this.porcentaje,
    required this.colorSube,
    required this.colorBaja,
    this.style,
  });

  final double? porcentaje;
  final Color colorSube;
  final Color colorBaja;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final p = porcentaje;
    if (p == null) return const SizedBox.shrink();

    final sube = p >= 0;
    final color = sube ? colorSube : colorBaja;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: p),
      duration: context.duracion(Motion.cifra),
      curve: Curves.easeOutExpo,
      builder: (context, valor, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sube ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${valor.abs().toStringAsFixed(0)} %',
            style: (style ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
