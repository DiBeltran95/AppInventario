import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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
        // Se acota el escalado tipográfico: por encima de 1,3 la fila del
        // carrito deja de caber y la app se vuelve inusable justo para quien
        // más necesita el texto grande.
        final escala = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: escala),
          child: hijo!,
        );
      },
    );
  }
}
