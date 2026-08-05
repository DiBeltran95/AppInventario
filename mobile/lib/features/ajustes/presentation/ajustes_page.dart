import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';

/// Ajustes.
///
/// Aquí vive todo lo que puede romper el dispositivo, así que las acciones
/// destructivas dicen exactamente **cuántas ventas se perderían** antes de
/// pedir confirmación. «¿Estás seguro?» sin una cifra al lado no informa de
/// nada.
class AjustesPage extends ConsumerWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final estado = ref.watch(estadoAppProvider).value;
    final sync = ref.watch(estadoSyncProvider).value;
    final api = ref.watch(apiClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (sesion != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.colores.primaryContainer,
                  child: Text(
                    sesion.iniciales,
                    style: context.textos.titleMedium
                        ?.copyWith(color: context.colores.onPrimaryContainer),
                  ),
                ),
                title: Text(sesion.nombre),
                subtitle: Text('${sesion.email} · ${sesion.rol.etiqueta}'),
              ),
            ),
          const SizedBox(height: 16),

          _Grupo(
            titulo: 'Sincronización',
            hijos: [
              ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: const Text('Sincronizar ahora'),
                subtitle: Text(
                  'Última vez: ${Fechas.relativo(sync?.ultimoSync)}',
                ),
                trailing: sync?.trabajando ?? false
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: (sync?.trabajando ?? false)
                    ? null
                    : () async {
                        final resultado =
                            await ref.read(syncEngineProvider).sincronizar();
                        if (!context.mounted) return;
                        mostrarMensaje(
                          context,
                          resultado.ok
                              ? 'Enviadas ${resultado.enviadas} · recibidas '
                                  '${resultado.recibidas}'
                              : 'No se pudo sincronizar: ${resultado.error}',
                          esExito: resultado.ok,
                          esError: !resultado.ok,
                        );
                      },
              ),
              ListTile(
                leading: Icon(
                  Icons.rule_rounded,
                  color: (sync?.rechazadas ?? 0) > 0 ? context.dominio.peligro : null,
                ),
                title: const Text('Elementos con problema'),
                subtitle: Text(
                  (sync?.rechazadas ?? 0) == 0
                      ? 'Nada pendiente de revisar'
                      : '${sync!.rechazadas} operación'
                          '${sync.rechazadas == 1 ? '' : 'es'} rechazada'
                          '${sync.rechazadas == 1 ? '' : 's'}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Rutas.pendientes),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Volver a descargar el catálogo'),
                subtitle: const Text(
                  'Reinicia los cursores y baja todo de nuevo. No afecta a las '
                  'ventas pendientes de enviar.',
                ),
                onTap: () => _descargaInicial(context, ref),
              ),
            ],
          ),

          _Grupo(
            titulo: 'Servidor',
            hijos: [
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Dirección de la API'),
                subtitle: Text(api.urlBase),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _cambiarUrl(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.wifi_tethering_rounded),
                title: const Text('Probar conexión'),
                onTap: () async {
                  final hay = await ref.read(connectivityServiceProvider).verificar();
                  if (!context.mounted) return;
                  mostrarMensaje(
                    context,
                    hay ? 'El servidor responde' : 'No se pudo contactar al servidor',
                    esExito: hay,
                    esError: !hay,
                  );
                },
              ),
            ],
          ),

          _Grupo(
            titulo: 'Dispositivo',
            hijos: [
              ListTile(
                leading: const Icon(Icons.numbers_rounded),
                title: const Text('Prefijo de folio'),
                subtitle: Text(
                  estado?.prefijoFolio ??
                      'Sin asignar (se usa LOC hasta la primera conexión)',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timelapse_rounded),
                title: const Text('Operación sin conexión'),
                subtitle: Text(
                  sesion?.validaHasta == null
                      ? 'Sin límite registrado'
                      : 'Válida hasta ${Fechas.formatFechaHora(sesion!.validaHasta!)}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calculate_outlined),
                title: const Text('Recalcular stock'),
                subtitle: const Text(
                  'Reconstruye el stock sumando el libro de movimientos local.',
                ),
                onTap: () async {
                  await ref.read(inventarioDaoProvider).recalcularStock();
                  if (context.mounted) {
                    mostrarMensaje(context, 'Stock recalculado', esExito: true);
                  }
                },
              ),
            ],
          ),

          _Grupo(
            titulo: 'Sesión',
            hijos: [
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Cerrar sesión'),
                subtitle: const Text('Los datos locales se conservan'),
                onTap: () => _cerrarSesion(context, ref, borrarDatos: false),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: context.dominio.peligro),
                title: Text(
                  'Cerrar sesión y borrar datos',
                  style: TextStyle(color: context.dominio.peligro),
                ),
                subtitle: const Text('Sólo al cambiar de negocio o de servidor'),
                onTap: () => _cerrarSesion(context, ref, borrarDatos: true),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const _VersionApp(),
        ],
      ),
    );
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _cambiarUrl(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final controlador = TextEditingController(text: api.urlBase);

    final nueva = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Dirección de la API'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'URL',
            helperText: 'Por defecto: ${AppConfig.urlPorDefecto}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, controlador.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controlador.dispose();
    if (nueva == null || nueva.isEmpty) return;

    api.urlBase = nueva;
    await ref.read(tokenStoreProvider).guardarUrlServidor(nueva);
    if (context.mounted) mostrarMensaje(context, 'Servidor actualizado', esExito: true);
  }

  Future<void> _descargaInicial(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Volver a descargar todo?'),
        content: const Text(
          'Se reinician los cursores de sincronización y se baja el catálogo '
          'completo. Puede tardar y consume datos. Las ventas pendientes de '
          'enviar no se tocan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    mostrarMensaje(context, 'Descargando catálogo…');
    try {
      final filas = await ref.read(syncEngineProvider).descargaInicial();
      if (context.mounted) {
        mostrarMensaje(context, 'Se recibieron $filas registros', esExito: true);
      }
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo descargar: $e', esError: true);
      }
    }
  }

  Future<void> _cerrarSesion(
    BuildContext context,
    WidgetRef ref, {
    required bool borrarDatos,
  }) async {
    // Se cuenta lo que se perdería ANTES de preguntar: es la diferencia entre
    // una confirmación informada y un formulismo.
    final sinEnviar =
        borrarDatos ? await ref.read(authRepositoryProvider).operacionesSinEnviar() : 0;

    if (!context.mounted) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(borrarDatos ? '¿Borrar todos los datos?' : '¿Cerrar sesión?'),
        content: Text(
          borrarDatos
              ? sinEnviar > 0
                  ? 'Hay $sinEnviar operación${sinEnviar == 1 ? '' : 'es'} sin '
                      'enviar al servidor. Si borras ahora, se pierde'
                      '${sinEnviar == 1 ? '' : 'n'} de forma definitiva.\n\n'
                      'Sincroniza primero si necesitas conservarla'
                      '${sinEnviar == 1 ? '' : 's'}.'
                  : 'Todo está sincronizado. Se borrará el catálogo y el '
                      'historial local del dispositivo.'
              : 'Podrás volver a entrar con tu correo y contraseña. Los datos '
                  'locales y las ventas pendientes se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: borrarDatos
                ? FilledButton.styleFrom(backgroundColor: context.dominio.peligro)
                : null,
            onPressed: () => Navigator.pop(dialogo, true),
            child: Text(borrarDatos ? 'Borrar y salir' : 'Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await ref.read(sesionProvider.notifier).cerrarSesion(borrarDatos: borrarDatos);
    // El router redirige solo al login al ver la sesión en null.
  }
}

// ─── Piezas ─────────────────────────────────────────────────────────────────

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              titulo,
              style: context.textos.labelLarge?.copyWith(
                color: context.colores.primary,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < hijos.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56, endIndent: 16),
                  hijos[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionApp extends StatelessWidget {
  const _VersionApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data == null
            ? ''
            : ' ${snapshot.data!.version} (${snapshot.data!.buildNumber})';
        return Center(
          child: Text(
            '${AppConfig.nombreApp}$version',
            style: context.textos.bodySmall?.copyWith(
              color: context.colores.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
