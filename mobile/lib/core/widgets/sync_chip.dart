import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../router/app_router.dart';
import '../sync/estado_sync.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';

/// Indicador permanente de sincronización.
///
/// Es el widget más importante de la app. En un sistema offline-first, la
/// pregunta que el usuario se hace veinte veces al día es «¿mi venta ya se
/// guardó de verdad?». Si la respuesta no está siempre a la vista, la gente
/// deja de confiar en la app y empieza a apuntar las ventas en papel «por si
/// acaso».
class SyncChip extends ConsumerWidget {
  const SyncChip({super.key, this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoSyncProvider).value ?? const EstadoSync();
    final dominio = context.dominio;

    final (color, fondo, icono) = switch (estado.fase) {
      FaseSync.sinConexion => (
          dominio.sinConexion,
          dominio.sinConexionContenedor,
          Icons.cloud_off_rounded,
        ),
      FaseSync.alDia => (dominio.exito, dominio.exitoContenedor, Icons.cloud_done_rounded),
      FaseSync.pendiente => (
          dominio.advertencia,
          dominio.advertenciaContenedor,
          Icons.cloud_upload_rounded,
        ),
      FaseSync.sincronizando => (dominio.info, dominio.infoContenedor, Icons.sync_rounded),
      FaseSync.conError => (dominio.peligro, dominio.peligroContenedor, Icons.cloud_off_rounded),
    };

    final iconoWidget = estado.fase == FaseSync.sincronizando
        ? Icon(icono, size: 16, color: color)
            .animate(onPlay: (c) => c.repeat())
            .rotate(duration: 1400.ms, curve: Curves.linear)
        : Icon(icono, size: 16, color: color);

    return Semantics(
      label: 'Estado de sincronización: ${estado.etiqueta}',
      button: true,
      child: InkWell(
        onTap: () => _mostrarDetalle(context, ref, estado),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: 260.ms,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: compacto ? 8 : 12, vertical: 7),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconoWidget,
              if (!compacto) ...[
                const SizedBox(width: 6),
                Text(
                  estado.etiqueta,
                  style: context.textos.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (compacto && estado.pendientes > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${estado.pendientes}',
                  style: context.textos.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, WidgetRef ref, EstadoSync estado) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _HojaSync(estado: estado),
    );
  }
}

class _HojaSync extends ConsumerWidget {
  const _HojaSync({required this.estado});

  final EstadoSync estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominio = context.dominio;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sincronización', style: context.textos.headlineSmall),
            const SizedBox(height: 4),
            Text(
              estado.hayConexion
                  ? 'Hay conexión con el servidor.'
                  : 'Sin conexión. Puedes seguir vendiendo con normalidad; '
                      'todo se enviará solo cuando vuelva la red.',
              style: context.textos.bodyMedium?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _Fila(
              icono: Icons.upload_rounded,
              etiqueta: 'Pendientes de enviar',
              valor: '${estado.pendientes}',
              color: estado.pendientes > 0 ? dominio.advertencia : dominio.exito,
            ),
            _Fila(
              icono: Icons.schedule_rounded,
              etiqueta: 'Última sincronización',
              valor: Fechas.relativo(estado.ultimoSync),
            ),
            if (estado.rechazadas > 0)
              _Fila(
                icono: Icons.error_outline_rounded,
                etiqueta: 'Con problema',
                valor: '${estado.rechazadas}',
                color: dominio.peligro,
              ),
            if (estado.ultimoError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dominio.peligroContenedor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estado.ultimoError!,
                  style: context.textos.bodySmall?.copyWith(color: dominio.peligro),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (estado.rechazadas > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(Rutas.pendientes);
                      },
                      icon: const Icon(Icons.rule_rounded),
                      label: const Text('Revisar'),
                    ),
                  ),
                if (estado.rechazadas > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: estado.trabajando
                        ? null
                        : () {
                            ref.read(syncEngineProvider).sincronizar();
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(estado.trabajando ? 'Sincronizando…' : 'Sincronizar ahora'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.color,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: color ?? context.colores.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(etiqueta, style: context.textos.bodyMedium)),
          Text(
            valor,
            style: context.textos.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
