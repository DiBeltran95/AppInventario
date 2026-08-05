import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import 'auth_providers.dart';

/// Inicio de sesión.
///
/// Dos cosas la separan de un login corriente:
///  · El primer login exige red (hay que traer el catálogo y el derivado de la
///    contraseña). Los siguientes funcionan sin ella, así que el mensaje de
///    error distingue «no hay red» de «credenciales incorrectas».
///  · La URL del servidor se edita desde aquí: en una tienda, quien instala la
///    app no siempre puede recompilarla para apuntar a otro host.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _focoPassword = FocusNode();

  bool _ocultar = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Se precarga el último correo: en un mostrador siempre entra la misma
    // persona y volver a teclearlo cada mañana es fricción pura.
    ref.read(authRepositoryProvider).ultimoEmail().then((email) {
      if (email != null && mounted) _email.text = email;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _focoPassword.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final resultado = await ref
          .read(sesionProvider.notifier)
          .iniciarSesion(_email.text, _password.text);

      if (!mounted) return;
      if (!resultado.exito) {
        setState(() => _error = resultado.mensajeError);
        return;
      }
      // El router redirige solo al ver la sesión: no se navega a mano desde
      // aquí para no competir con la guarda de rutas.
      if (!resultado.sesion!.enLinea) {
        mostrarMensaje(context, 'Sesión abierta sin conexión');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo iniciar sesión: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _configurarServidor() async {
    final api = ref.read(apiClientProvider);
    final controlador = TextEditingController(text: api.urlBase);

    final nueva = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dirección de la API. En el emulador de Android, el equipo donde '
              'corre el backend es 10.0.2.2, no localhost.',
              style: context.textos.bodySmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controlador,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'http://10.0.2.2:3100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controlador.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controlador.dispose();
    if (nueva == null || nueva.isEmpty) return;

    api.urlBase = nueva;
    await ref.read(tokenStoreProvider).guardarUrlServidor(nueva);
    if (mounted) mostrarMensaje(context, 'Servidor: $nueva', esExito: true);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Marca(),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enabled: !_enviando,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) {
                        final texto = v?.trim() ?? '';
                        if (texto.isEmpty) return 'Escribe tu correo';
                        if (!texto.contains('@')) return 'Correo no válido';
                        return null;
                      },
                      onFieldSubmitted: (_) => _focoPassword.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      focusNode: _focoPassword,
                      obscureText: _ocultar,
                      enabled: !_enviando,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                          icon: Icon(
                            _ocultar
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Escribe tu contraseña' : null,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.dominio.peligroContenedor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: context.dominio.peligro,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: context.textos.bodySmall
                                    ?.copyWith(color: context.dominio.peligro),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 220.ms).shake(hz: 3, offset: const Offset(3, 0)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _enviando ? null : _entrar,
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _enviando ? null : _configurarServidor,
                      icon: const Icon(Icons.dns_outlined, size: 18),
                      label: const Text('Configurar servidor'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'La primera vez necesitas conexión. Después podrás entrar '
                      'y vender sin internet.',
                      textAlign: TextAlign.center,
                      style: context.textos.bodySmall?.copyWith(
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: context.colores.primaryContainer,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            size: 42,
            color: context.colores.onPrimaryContainer,
          ),
        )
            .animate()
            .scale(duration: 420.ms, curve: Curves.easeOutBack, begin: const Offset(0.8, 0.8))
            .fadeIn(),
        const SizedBox(height: 20),
        Text(
          AppConfig.nombreApp,
          textAlign: TextAlign.center,
          style: context.textos.headlineMedium,
        ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
        const SizedBox(height: 6),
        Text(
          'Inventario y punto de venta',
          textAlign: TextAlign.center,
          style: context.textos.bodyMedium?.copyWith(
            color: context.colores.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}
