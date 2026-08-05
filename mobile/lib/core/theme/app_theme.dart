import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tema Material 3.
///
/// La paleta parte de un verde profundo, no del morado por defecto de Flutter:
/// una app que se abre 200 veces al día en un mostrador debe parecer una
/// herramienta, no una demo. El verde se asocia con dinero y con «correcto», y
/// deja el ámbar y el rojo libres para lo único que debe gritar en pantalla:
/// el stock bajo y el stock agotado.

const _semilla = Color(0xFF0E6B5C);

/// Colores con significado de negocio. Van en una `ThemeExtension` en lugar de
/// como constantes sueltas para que cambien solos entre tema claro y oscuro.
@immutable
class ColoresDominio extends ThemeExtension<ColoresDominio> {
  const ColoresDominio({
    required this.exito,
    required this.exitoContenedor,
    required this.advertencia,
    required this.advertenciaContenedor,
    required this.peligro,
    required this.peligroContenedor,
    required this.info,
    required this.infoContenedor,
    required this.sinConexion,
    required this.sinConexionContenedor,
  });

  final Color exito;
  final Color exitoContenedor;
  final Color advertencia;
  final Color advertenciaContenedor;
  final Color peligro;
  final Color peligroContenedor;
  final Color info;
  final Color infoContenedor;
  final Color sinConexion;
  final Color sinConexionContenedor;

  static const claro = ColoresDominio(
    exito: Color(0xFF11794F),
    exitoContenedor: Color(0xFFD3F3E0),
    advertencia: Color(0xFF9A5B00),
    advertenciaContenedor: Color(0xFFFFE7C2),
    peligro: Color(0xFFB3261E),
    peligroContenedor: Color(0xFFFFDAD6),
    info: Color(0xFF1D4ED8),
    infoContenedor: Color(0xFFDBE6FF),
    sinConexion: Color(0xFF5A5F66),
    sinConexionContenedor: Color(0xFFE6E8EB),
  );

  static const oscuro = ColoresDominio(
    exito: Color(0xFF6FDBA4),
    exitoContenedor: Color(0xFF06432B),
    advertencia: Color(0xFFFFC26B),
    advertenciaContenedor: Color(0xFF4A2E00),
    peligro: Color(0xFFFFB4AB),
    peligroContenedor: Color(0xFF601410),
    info: Color(0xFFA9C6FF),
    infoContenedor: Color(0xFF0B2E73),
    sinConexion: Color(0xFFB4B9C0),
    sinConexionContenedor: Color(0xFF2C3034),
  );

  @override
  ColoresDominio copyWith({
    Color? exito,
    Color? exitoContenedor,
    Color? advertencia,
    Color? advertenciaContenedor,
    Color? peligro,
    Color? peligroContenedor,
    Color? info,
    Color? infoContenedor,
    Color? sinConexion,
    Color? sinConexionContenedor,
  }) =>
      ColoresDominio(
        exito: exito ?? this.exito,
        exitoContenedor: exitoContenedor ?? this.exitoContenedor,
        advertencia: advertencia ?? this.advertencia,
        advertenciaContenedor: advertenciaContenedor ?? this.advertenciaContenedor,
        peligro: peligro ?? this.peligro,
        peligroContenedor: peligroContenedor ?? this.peligroContenedor,
        info: info ?? this.info,
        infoContenedor: infoContenedor ?? this.infoContenedor,
        sinConexion: sinConexion ?? this.sinConexion,
        sinConexionContenedor: sinConexionContenedor ?? this.sinConexionContenedor,
      );

  @override
  ColoresDominio lerp(ThemeExtension<ColoresDominio>? otro, double t) {
    if (otro is! ColoresDominio) return this;
    return ColoresDominio(
      exito: Color.lerp(exito, otro.exito, t)!,
      exitoContenedor: Color.lerp(exitoContenedor, otro.exitoContenedor, t)!,
      advertencia: Color.lerp(advertencia, otro.advertencia, t)!,
      advertenciaContenedor: Color.lerp(advertenciaContenedor, otro.advertenciaContenedor, t)!,
      peligro: Color.lerp(peligro, otro.peligro, t)!,
      peligroContenedor: Color.lerp(peligroContenedor, otro.peligroContenedor, t)!,
      info: Color.lerp(info, otro.info, t)!,
      infoContenedor: Color.lerp(infoContenedor, otro.infoContenedor, t)!,
      sinConexion: Color.lerp(sinConexion, otro.sinConexion, t)!,
      sinConexionContenedor: Color.lerp(sinConexionContenedor, otro.sinConexionContenedor, t)!,
    );
  }
}

/// Atajo: `context.dominio.advertencia`.
extension TemaDominio on BuildContext {
  ColoresDominio get dominio =>
      Theme.of(this).extension<ColoresDominio>() ?? ColoresDominio.claro;
  ColorScheme get colores => Theme.of(this).colorScheme;
  TextTheme get textos => Theme.of(this).textTheme;
}

class AppTheme {
  const AppTheme._();

  static ThemeData claro() => _construir(Brightness.light);
  static ThemeData oscuro() => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(seedColor: _semilla, brightness: brillo);
    final oscuro = brillo == Brightness.dark;
    final base = ThemeData(colorScheme: esquema, useMaterial3: true);

    // Tipografía del sistema (Roboto en Android). No se usa google_fonts: baja
    // las fuentes por HTTP y esta app tiene que arrancar sin conexión.
    final textos = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return base.copyWith(
      textTheme: textos,
      scaffoldBackgroundColor: oscuro ? const Color(0xFF101413) : const Color(0xFFF7F9F8),
      extensions: [oscuro ? ColoresDominio.oscuro : ColoresDominio.claro],

      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        backgroundColor: oscuro ? const Color(0xFF101413) : const Color(0xFFF7F9F8),
        surfaceTintColor: esquema.surfaceTint,
        titleTextStyle: textos.titleLarge?.copyWith(color: esquema.onSurface),
        systemOverlayStyle:
            oscuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: esquema.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),

      // 52 px de alto: los botones se pulsan con el pulgar, a veces con guantes
      // y con prisa. El mínimo de 48 dp de Material es el suelo, no el objetivo.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textos.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textos.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHighest.withValues(alpha: oscuro ? 0.35 : 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: textos.labelMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 3,
        backgroundColor: esquema.surfaceContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(textos.labelMedium),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      dividerTheme: DividerThemeData(
        color: esquema.outlineVariant.withValues(alpha: 0.4),
        space: 1,
        thickness: 1,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
