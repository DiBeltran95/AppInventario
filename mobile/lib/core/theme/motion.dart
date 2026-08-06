import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Sistema de movimiento.
///
/// Un único punto de verdad para duraciones y curvas. Existe sobre todo por una
/// razón de accesibilidad: cuando el usuario activa «Reducir movimiento» en los
/// ajustes de Android, `context.duracion()` devuelve `Duration.zero` y toda la
/// interfaz se vuelve instantánea **sin tocar una sola pantalla**.
///
/// Sin esto, cada animación nueva sería una regresión de accesibilidad para
/// quien sufre trastornos vestibulares (WCAG 2.1 §2.3.3), y arreglarlo después
/// obligaría a revisar cuarenta sitios.
class Motion {
  const Motion._();

  /// Realimentación táctil inmediata: rebote de un badge, presión de un botón.
  static const rapida = Duration(milliseconds: 150);

  /// Entradas y cambios de estado: chips, tarjetas, hojas inferiores.
  static const media = Duration(milliseconds: 260);

  /// Transiciones de página.
  static const lenta = Duration(milliseconds: 420);

  /// Contadores numéricos. Más larga a propósito: el ojo tiene que poder seguir
  /// la cifra mientras sube.
  static const cifra = Duration(milliseconds: 700);

  /// Algo que aparece: entra rápido y frena.
  static const entrada = Curves.easeOutCubic;

  /// Algo que se va: acelera al salir.
  static const salida = Curves.easeInCubic;

  /// Confirmación, con un rebote leve. Sólo para éxitos; en un error, el rebote
  /// se lee como celebración.
  static const enfasis = Curves.easeOutBack;

  /// Desfase entre elementos de una lista escalonada.
  static const pasoEscalonado = Duration(milliseconds: 35);

  /// Cuántos elementos de una lista se animan al entrar.
  ///
  /// Con `ListView.builder`, animar por índice hace que las filas se vuelvan a
  /// animar cada vez que reentran en el viewport al hacer scroll, lo que produce
  /// parpadeo en lugar de elegancia. Sólo se animan las primeras visibles.
  static const maxEscalonados = 8;
}

extension MovimientoAccesible on BuildContext {
  /// ¿El usuario pidió reducir el movimiento en los ajustes del sistema?
  bool get movimientoReducido => MediaQuery.disableAnimationsOf(this);

  /// Úsala SIEMPRE en lugar de una `Duration` literal en una animación.
  Duration duracion(Duration d) => movimientoReducido ? Duration.zero : d;

  /// Retardo de un elemento dentro de una lista escalonada.
  Duration retardo(int indice) => movimientoReducido
      ? Duration.zero
      : Motion.pasoEscalonado * indice.clamp(0, Motion.maxEscalonados);

  /// `true` si este índice debe animarse al entrar en la lista.
  bool animaEnLista(int indice) =>
      !movimientoReducido && indice <= Motion.maxEscalonados;
}

/// Marca la primera pintada de una pantalla con listas animadas.
///
/// Resuelve el error clásico del escalonado en `ListView.builder`/`GridView.builder`:
/// si se anima por índice, cada fila **se vuelve a animar** al reentrar en el
/// viewport durante el scroll, y lo que debía ser elegante queda parpadeante.
///
/// Con esto la animación vive sólo hasta el primer frame; a partir de ahí,
/// desplazarse nunca vuelve a disparar nada.
mixin AnimacionPrimeraCarga<T extends StatefulWidget> on State<T> {
  bool _primeraCarga = true;

  bool get enPrimeraCarga => _primeraCarga;

  @override
  void initState() {
    super.initState();
    // Sin `setState`: no hace falta repintar, sólo dejar de animar lo que se
    // construya a partir de ahora.
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeraCarga = false);
  }
}

/// Entrada escalonada de un elemento de lista.
///
/// Devuelve el hijo intacto cuando no toca animar (movimiento reducido, índice
/// fuera del tramo inicial, o construcción posterior al primer frame), así que
/// se puede envolver todo sin condicionales en el punto de uso.
class EntradaEscalonada extends StatelessWidget {
  const EntradaEscalonada({
    super.key,
    required this.indice,
    required this.child,
    this.activo = true,
  });

  final int indice;
  final Widget child;

  /// Normalmente `enPrimeraCarga` del mixin [AnimacionPrimeraCarga].
  final bool activo;

  @override
  Widget build(BuildContext context) {
    if (!activo || !context.animaEnLista(indice)) return child;

    return child
        .animate(delay: context.retardo(indice))
        .fadeIn(duration: Motion.media)
        .slideY(begin: 0.10, curve: Motion.entrada);
  }
}
