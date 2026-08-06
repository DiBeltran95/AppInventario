import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/motion.dart';

class InventarioApp extends ConsumerWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.nombreApp,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, hijo) {
        // Si el usuario activó «Reducir movimiento» en Android, flutter_animate
        // pasa a duración cero en TODA la app. Es una línea aquí en lugar de una
        // comprobación en cada una de las animaciones.
        Animate.defaultDuration =
            MediaQuery.disableAnimationsOf(context) ? Duration.zero : Motion.media;

        // Se acota el escalado tipográfico: por encima de 1,3 la fila del
        // carrito deja de caber y la app se vuelve inusable justo para quien
        // más necesita el texto grande.
        final escala = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: escala),
          // Tocar fuera de un campo cierra el teclado, en TODA la app.
          //
          // Se usa `Listener` y no `GestureDetector`: un `ListView`/`ScrollView`
          // gana la arena de gestos ante un `onTap` del padre, y el teclado
          // nunca bajaba al tocar entre campos del formulario de producto.
          // `onPointerDown` no compite en esa arena.
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (evento) {
              final foco = FocusManager.instance.primaryFocus;
              if (foco == null || !foco.hasFocus) return;
              final caja = foco.context?.findRenderObject();
              if (caja is! RenderBox || !caja.hasSize) {
                foco.unfocus();
                return;
              }
              final local = caja.globalToLocal(evento.position);
              if (!caja.size.contains(local)) {
                foco.unfocus();
              }
            },
            child: hijo!,
          ),
        );
      },
    );
  }
}
