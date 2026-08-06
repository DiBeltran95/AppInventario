import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';
import '../domain/sesion.dart';
import 'auth_providers.dart';

/// Cuentas de acceso (sólo ADMIN).
///
/// **Es la única pantalla de la app que exige conexión.** Aquí no vale el
/// patrón offline-first del resto: si dos administradores crearan sin red la
/// misma cuenta en dos dispositivos, quedarían dos usuarios con el mismo correo
/// y contraseñas distintas, y no hay forma razonable de resolver ese conflicto
/// al sincronizar. Las credenciales las emite el servidor, siempre.
class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosProvider);
    final sesion = ref.watch(sesionProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas de acceso')),
      body: usuarios.when(
        loading: () => const SkeletonLista(),
        error: (e, _) => _Error(error: e, onReintentar: () => ref.invalidate(usuariosProvider)),
        data: (lista) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(usuariosProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              const _AvisoEnLinea(),
              const SizedBox(height: 16),
              for (final usuario in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FilaUsuario(
                    usuario: usuario,
                    esUsuarioActual: usuario.uuid == sesion?.usuarioUuid,
                    onEditar: () => _formulario(context, ref, usuario: usuario),
                    onEliminar: () => _confirmarEliminar(context, ref, usuario),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nueva cuenta'),
      ),
    );
  }

  Future<void> _formulario(
    BuildContext context,
    WidgetRef ref, {
    UsuarioAdmin? usuario,
  }) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FormularioUsuario(usuario: usuario),
    );
    if (guardado == true) ref.invalidate(usuariosProvider);
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdmin usuario,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Dar de baja la cuenta?'),
        content: Text(
          '${usuario.nombre} no podrá volver a iniciar sesión. Las ventas y '
          'movimientos que registró se conservan intactos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.dominio.peligro),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref.read(authRepositoryProvider).eliminarUsuario(usuario.uuid);
      ref.invalidate(usuariosProvider);
      if (context.mounted) mostrarMensaje(context, 'Cuenta dada de baja');
    } on ApiException catch (e) {
      // El servidor protege al último administrador: sin admins, nadie podría
      // volver a administrar nada.
      if (context.mounted) mostrarMensaje(context, e.mensajeUsuario, esError: true);
    }
  }
}

/// Lista de cuentas. Es un `FutureProvider` y no un stream de Drift porque
/// estos datos viven en el servidor, no en la base local.
final usuariosProvider = FutureProvider.autoDispose<List<UsuarioAdmin>>(
  (ref) => ref.watch(authRepositoryProvider).listarUsuarios(),
);

// ─── Piezas ─────────────────────────────────────────────────────────────────

class _AvisoEnLinea extends StatelessWidget {
  const _AvisoEnLinea();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dominio.infoContenedor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_rounded, size: 20, color: context.dominio.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Crear o modificar cuentas requiere conexión. El resto de la app '
              'sigue funcionando sin ella.',
              style: context.textos.bodySmall?.copyWith(color: context.dominio.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final sinRed = error is ApiException && (error as ApiException).esDeRed;

    return EstadoVacio(
      icono: sinRed ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
      titulo: sinRed ? 'Sin conexión' : 'No se pudieron cargar las cuentas',
      descripcion: sinRed
          ? 'La gestión de cuentas necesita conexión con el servidor. '
              'Vuelve a intentarlo cuando tengas red.'
          : error is ApiException
              ? (error as ApiException).mensajeUsuario
              : '$error',
      textoAccion: 'Reintentar',
      onAccion: onReintentar,
    );
  }
}

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({
    required this.usuario,
    required this.esUsuarioActual,
    required this.onEditar,
    required this.onEliminar,
  });

  final UsuarioAdmin usuario;
  final bool esUsuarioActual;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final esAdmin = usuario.rol == RolUsuario.admin;

    return Card(
      child: ListTile(
        onTap: onEditar,
        leading: CircleAvatar(
          backgroundColor: usuario.activo
              ? (esAdmin ? context.colores.primaryContainer : context.colores.secondaryContainer)
              : context.colores.surfaceContainerHighest,
          child: Text(
            usuario.iniciales,
            style: context.textos.titleSmall?.copyWith(
              color: usuario.activo
                  ? (esAdmin
                      ? context.colores.onPrimaryContainer
                      : context.colores.onSecondaryContainer)
                  : context.colores.onSurfaceVariant,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                usuario.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textos.titleSmall,
              ),
            ),
            if (esUsuarioActual) ...[
              const SizedBox(width: 8),
              Text(
                '(tú)',
                style: context.textos.labelSmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                _Etiqueta(
                  texto: usuario.rol.etiqueta,
                  color: esAdmin ? context.dominio.info : context.colores.onSurfaceVariant,
                  fondo: esAdmin
                      ? context.dominio.infoContenedor
                      : context.colores.surfaceContainerHighest,
                ),
                if (!usuario.activo) ...[
                  const SizedBox(width: 6),
                  _Etiqueta(
                    texto: 'Inactiva',
                    color: context.dominio.peligro,
                    fondo: context.dominio.peligroContenedor,
                  ),
                ],
                if (usuario.ultimoAcceso != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'entró ${Fechas.relativo(usuario.ultimoAcceso)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textos.labelSmall?.copyWith(
                        color: context.colores.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: esUsuarioActual
            // Darse de baja a uno mismo deja la sesión en un estado absurdo:
            // autenticado con una cuenta que ya no existe.
            ? null
            : IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.person_off_outlined),
                tooltip: 'Dar de baja',
              ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color, required this.fondo});

  final String texto;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(6)),
      child: Text(
        texto,
        style: context.textos.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Formulario ─────────────────────────────────────────────────────────────

class _FormularioUsuario extends ConsumerStatefulWidget {
  const _FormularioUsuario({this.usuario});

  final UsuarioAdmin? usuario;

  @override
  ConsumerState<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends ConsumerState<_FormularioUsuario> {
  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario?.nombre ?? '');
  late final _email = TextEditingController(text: widget.usuario?.email ?? '');
  final _password = TextEditingController();

  late RolUsuario _rol = widget.usuario?.rol ?? RolUsuario.vendedor;
  late bool _activo = widget.usuario?.activo ?? true;
  bool _ocultar = true;
  bool _guardando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_esEdicion) {
        await repo.actualizarUsuario(
          widget.usuario!.uuid,
          nombre: _nombre.text.trim(),
          email: _email.text.trim(),
          rol: _rol,
          activo: _activo,
          // Vacío = no se toca la contraseña actual.
          password: _password.text.isEmpty ? null : _password.text,
        );
      } else {
        await repo.crearUsuario(
          nombre: _nombre.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          rol: _rol,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarMensaje(context, e.mensajeUsuario, esError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarMensaje(context, 'No se pudo guardar: $e', esError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Form(
            key: _formulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _esEdicion ? 'Editar cuenta' : 'Nueva cuenta',
                  style: context.textos.headlineSmall,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 2 ? 'Escribe el nombre completo' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo *',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (v) {
                    final texto = v?.trim() ?? '';
                    if (texto.isEmpty) return 'El correo es obligatorio';
                    if (!texto.contains('@') || !texto.contains('.')) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _password,
                  obscureText: _ocultar,
                  decoration: InputDecoration(
                    labelText: _esEdicion ? 'Nueva contraseña' : 'Contraseña *',
                    helperText: _esEdicion
                        ? 'Déjala vacía para no cambiarla'
                        : 'Mínimo 8 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                      icon: Icon(
                        _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) {
                    final texto = v ?? '';
                    if (_esEdicion && texto.isEmpty) return null;
                    return texto.length < 8 ? 'Mínimo 8 caracteres' : null;
                  },
                ),
                const SizedBox(height: 20),

                Text('Rol', style: context.textos.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<RolUsuario>(
                  segments: const [
                    ButtonSegment(
                      value: RolUsuario.vendedor,
                      label: Text('Vendedor'),
                      icon: Icon(Icons.point_of_sale_rounded),
                    ),
                    ButtonSegment(
                      value: RolUsuario.admin,
                      label: Text('Administrador'),
                      icon: Icon(Icons.shield_outlined),
                    ),
                  ],
                  selected: {_rol},
                  onSelectionChanged: (s) => setState(() => _rol = s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _rol == RolUsuario.admin
                      ? 'Acceso total: edita el catálogo, ve costos y márgenes y '
                          'puede anular ventas.'
                      : 'Puede vender y consultar, pero no ve costos ni márgenes '
                          'ni edita el catálogo.',
                  style: context.textos.bodySmall?.copyWith(
                    color: context.colores.onSurfaceVariant,
                  ),
                ),

                if (_esEdicion) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    title: const Text('Cuenta activa'),
                    subtitle: Text(
                      _activo ? 'Puede iniciar sesión' : 'No puede iniciar sesión',
                      style: context.textos.bodySmall,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],

                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_esEdicion ? 'Guardar cambios' : 'Crear cuenta'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
