import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_pos/core/router/app_router.dart';
import 'package:inventario_pos/features/auth/domain/sesion.dart';
import 'package:inventario_pos/features/auth/presentation/auth_providers.dart';

/// Sesión de prueba: sustituye a `SesionNotifier` sin tocar la base ni la red.
class _SesionFalsa extends SesionNotifier {
  _SesionFalsa(this._inicial);

  final Sesion? _inicial;

  @override
  Future<Sesion?> build() async => _inicial;

  void establecer(Sesion? sesion) => state = AsyncValue.data(sesion);
  void cargando() => state = const AsyncValue.loading();
}

Sesion _sesion({required RolUsuario rol, String nombre = 'Prueba'}) => Sesion(
  usuarioUuid: 'uuid-$nombre',
  nombre: nombre,
  email: '$nombre@local',
  rol: rol,
  enLinea: true,
);

void main() {
  group('routerProvider', () {
    /// Regresión del fallo que dejaba el inicio en blanco tras iniciar sesión y
    /// hacía que la pestaña «Reportes» no respondiera.
    ///
    /// La causa era `ref.watch(sesionProvider)` en el cuerpo del provider: cada
    /// cambio de sesión creaba un GoRouter NUEVO —y al entrar hay dos seguidos,
    /// `loading` y `data`—, lo que remontaba el Navigator entero y dejaba
    /// instancias viejas cuyo `redirect` había capturado una sesión obsoleta.
    ///
    /// Si alguien vuelve a poner un `watch` ahí, esta prueba falla.
    test('mantiene la MISMA instancia cuando cambia la sesión', () async {
      final falsa = _SesionFalsa(_sesion(rol: RolUsuario.admin));
      final contenedor = ProviderContainer(
        overrides: [sesionProvider.overrideWith(() => falsa)],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(sesionProvider.future);
      final primero = contenedor.read(routerProvider);

      // Los tres cambios que ocurren en un inicio de sesión real.
      // Se usa la instancia directamente: `sesionProvider.notifier` está tipado
      // como `SesionNotifier` y no expone los ayudantes de la doble.
      falsa.cargando();
      falsa.establecer(_sesion(rol: RolUsuario.vendedor, nombre: 'Otro'));
      falsa.establecer(null);

      expect(
        identical(primero, contenedor.read(routerProvider)),
        isTrue,
        reason: 'El GoRouter se reconstruyó; el Navigator se remontaría y el '
            'redirect volvería a capturar una sesión obsoleta.',
      );
    });

    test('se crea sin depender de la base de datos ni de la red', () {
      final contenedor = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith(
            () => _SesionFalsa(_sesion(rol: RolUsuario.admin)),
          ),
        ],
      );
      addTearDown(contenedor.dispose);

      // Si el router tocara `appDatabaseProvider` o `apiClientProvider` —que en
      // pruebas lanzan UnimplementedError— esto reventaría. Arrancar la
      // navegación no puede exigir ni disco ni red.
      expect(() => contenedor.read(routerProvider), returnsNormally);
    });
  });

  group('RolUsuario', () {
    test('el vendedor no puede tocar catálogo, anulaciones ni cuentas', () {
      const vendedor = RolUsuario.vendedor;
      expect(vendedor.puedeEditarCatalogo, isFalse);
      expect(vendedor.puedeAnularVentas, isFalse);
      expect(vendedor.puedeGestionarUsuarios, isFalse);
      expect(vendedor.veCostos, isFalse);
    });

    test('el administrador sí', () {
      const admin = RolUsuario.admin;
      expect(admin.puedeEditarCatalogo, isTrue);
      expect(admin.puedeAnularVentas, isTrue);
      expect(admin.puedeGestionarUsuarios, isTrue);
      expect(admin.veCostos, isTrue);
    });

    test('ante un rol desconocido se asume el MÁS restrictivo', () {
      // Un valor inesperado del servidor no puede conceder permisos.
      expect(RolUsuario.desde(null), RolUsuario.vendedor);
      expect(RolUsuario.desde('SUPERADMIN'), RolUsuario.vendedor);
      expect(RolUsuario.desde('admin'), RolUsuario.vendedor); // distingue mayúsculas
      expect(RolUsuario.desde('ADMIN'), RolUsuario.admin);
    });
  });
}
