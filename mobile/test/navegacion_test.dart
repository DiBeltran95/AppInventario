import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_pos/core/router/app_router.dart';
import 'package:inventario_pos/core/widgets/app_shell.dart';

/// Regresión de la barra inferior.
///
/// El hueco del botón central de escanear es, para `NavigationBar`, una pestaña
/// más. Durante un tiempo el código mezcló dos numeraciones —la de destinos y
/// la de pestañas pintadas—, con dos consecuencias en producción:
///
///  · al administrador, «Reportes» no le hacía nada (índice fuera de rango) y
///    «Ventas» lo llevaba a Reportes;
///  · al vendedor, «Ventas» tampoco respondía, y el botón de escanear se
///    montaba encima de «Productos» porque el hueco no quedaba centrado.
///
/// Nada de esto se nota leyendo el código, así que se fija aquí.
void main() {
  group('Ranuras de la barra inferior', () {
    test('el administrador tiene sus cuatro secciones y el hueco centrado', () {
      final ranuras = AppShell.ranurasDe(true);

      expect(ranuras.length, 5, reason: '4 destinos + el hueco del botón');
      expect(ranuras[2], isNull, reason: 'el hueco va justo en el centro');
      expect(ranuras.map((d) => d?.ruta).toList(), [
        Rutas.dashboard,
        Rutas.productos,
        null,
        Rutas.ventas,
        Rutas.reportes,
      ]);
    });

    test('el vendedor sólo tiene Inicio y Ventas, con el hueco en medio', () {
      final ranuras = AppShell.ranurasDe(false);

      expect(ranuras.length, 3);
      expect(ranuras[1], isNull);
      expect(ranuras.map((d) => d?.ruta).toList(), [
        Rutas.dashboard,
        null,
        Rutas.ventas,
      ]);
    });

    test('el vendedor no ve Reportes ni Productos en la barra', () {
      final rutas = AppShell.ranurasDe(false).map((d) => d?.ruta).toList();
      expect(rutas, isNot(contains(Rutas.reportes)));
      expect(rutas, isNot(contains(Rutas.productos)));
    });

    test('el hueco queda centrado en ambos roles', () {
      for (final esAdmin in [true, false]) {
        final ranuras = AppShell.ranurasDe(esAdmin);
        final hueco = ranuras.indexWhere((d) => d == null);
        // Mismo número de pestañas a cada lado: si no, el botón flotante
        // —anclado al centro— se monta encima de una de ellas.
        expect(
          hueco,
          ranuras.length - 1 - hueco,
          reason: 'hueco descentrado con esAdmin=$esAdmin',
        );
      }
    });
  });

  group('Pestaña activa', () {
    test('cada destino se enciende en su propia ranura', () {
      final ranuras = AppShell.ranurasDe(true);

      expect(AppShell.indiceDe(Rutas.dashboard, ranuras), 0);
      expect(AppShell.indiceDe(Rutas.productos, ranuras), 1);
      expect(AppShell.indiceDe(Rutas.ventas, ranuras), 3);
      expect(AppShell.indiceDe(Rutas.reportes, ranuras), 4);
    });

    test('nunca selecciona el hueco', () {
      for (final esAdmin in [true, false]) {
        final ranuras = AppShell.ranurasDe(esAdmin);
        for (final ubicacion in [
          Rutas.dashboard,
          Rutas.ventas,
          '/ventas/abc-123',
          '/desconocida',
        ]) {
          final i = AppShell.indiceDe(ubicacion, ranuras);
          expect(
            ranuras[i],
            isNotNull,
            reason: '«$ubicacion» seleccionó el hueco (esAdmin=$esAdmin)',
          );
        }
      }
    });

    test('una subruta mantiene encendida su sección, no Inicio', () {
      final ranuras = AppShell.ranurasDe(true);
      // '/' es prefijo de todo: buscar de izquierda a derecha dejaría siempre
      // «Inicio» encendido.
      expect(AppShell.indiceDe('/ventas/abc-123', ranuras), 3);
      expect(AppShell.indiceDe('/productos/abc-123', ranuras), 1);
    });

    test('una ruta desconocida cae en Inicio', () {
      final ranuras = AppShell.ranurasDe(true);
      expect(AppShell.indiceDe('/no-existe', ranuras), 0);
    });

    test('el vendedor en Ventas enciende la ranura correcta', () {
      final ranuras = AppShell.ranurasDe(false);
      expect(AppShell.indiceDe(Rutas.ventas, ranuras), 2);
      expect(ranuras[2]?.ruta, Rutas.ventas);
    });
  });
}
