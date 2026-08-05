import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../data/auth_repository.dart';
import '../domain/sesion.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
  );
});

/// Sesión actual. `null` = no autenticado.
///
/// Se resuelve **sin red**: lee el usuario guardado en SQLite. Abrir la app en
/// modo avión debe llevar directamente al dashboard, no a una pantalla de carga
/// esperando un servidor que no está.
class SesionNotifier extends AsyncNotifier<Sesion?> {
  @override
  Future<Sesion?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final sesion = await repo.sesionGuardada();

    if (sesion != null) {
      // Arrancar el motor aquí y no en `main()` evita sincronizar cuando no hay
      // nadie autenticado.
      await ref.read(syncEngineProvider).iniciar();
    }
    return sesion;
  }

  Future<ResultadoLogin> iniciarSesion(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final resultado = await ref.read(authRepositoryProvider).iniciarSesion(email, password);

      if (!resultado.exito) {
        state = AsyncValue.data(null);
        return resultado;
      }

      state = AsyncValue.data(resultado.sesion);

      final motor = ref.read(syncEngineProvider);
      await motor.iniciar();
      if (resultado.necesitaDescargaInicial) {
        // Primera vez en este dispositivo: hay que traer el catálogo antes de
        // poder vender. Se deja en segundo plano; la UI muestra el progreso.
        unawaited(motor.descargaInicial());
      }

      return resultado;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> cerrarSesion({bool borrarDatos = false}) async {
    await ref.read(authRepositoryProvider).cerrarSesion(borrarDatos: borrarDatos);
    state = const AsyncValue.data(null);
  }
}

final sesionProvider =
    AsyncNotifierProvider<SesionNotifier, Sesion?>(SesionNotifier.new);

/// Rol efectivo. Ante la duda, el rol más restrictivo: si algo falla al leer la
/// sesión, es preferible ocultar los costos que enseñarlos por accidente.
final rolProvider = Provider<RolUsuario>((ref) {
  return ref.watch(sesionProvider).maybeWhen(
        data: (s) => s?.rol ?? RolUsuario.vendedor,
        orElse: () => RolUsuario.vendedor,
      );
});

final esAdminProvider = Provider<bool>((ref) => ref.watch(rolProvider) == RolUsuario.admin);
