import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/ventas_dao.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/sync/estado_sync.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/widgets/estados.dart';
import '../../data/ticket_pdf.dart';
import '../ventas_providers.dart';

/// Confirmación de venta.
///
/// Lo más grande de la pantalla es el **cambio a devolver**, no el total: es lo
/// único que el vendedor necesita leer en ese instante, muchas veces con el
/// cliente esperando y el billete en la mano.
///
/// La venta ya está guardada cuando esta pantalla aparece. Si no hay red, se
/// dice explícitamente que saldrá sola: callarlo es lo que hace que la gente
/// desconfíe y apunte las ventas en papel «por si acaso».
class VentaExitosa extends ConsumerWidget {
  const VentaExitosa({super.key, required this.venta});

  final VentaCompleta venta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cambio = venta.cambio;
    final hayCambio = cambio.esPositivo;
    final negocio = ref.watch(nombreNegocioProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const CheckAnimado(tamano: 88),
              const SizedBox(height: 20),
              Text('Venta registrada', style: context.textos.headlineSmall)
                  .animate()
                  .fadeIn(delay: 260.ms),
              const SizedBox(height: 6),
              Text(
                '${venta.venta.numero} · ${venta.total.format()}',
                style: context.textos.bodyMedium?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 320.ms),

              if (hayCambio) ...[
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.dominio.exitoContenedor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Cambio a devolver',
                        style: context.textos.titleSmall
                            ?.copyWith(color: context.dominio.exito),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cambio.format(),
                        style: context.textos.displaySmall
                            ?.copyWith(color: context.dominio.exito),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 380.ms)
                    .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOutBack),
              ],

              const SizedBox(height: 24),
              _EstadoEnvio(ventaUuid: venta.venta.uuid),
              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _compartir(context, negocio),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Compartir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _imprimir(context, negocio),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Ticket'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Nueva venta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _imprimir(BuildContext context, String negocio) async {
    try {
      await TicketPdf.imprimir(venta, nombreNegocio: negocio);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo imprimir: $e', esError: true);
      }
    }
  }

  Future<void> _compartir(BuildContext context, String negocio) async {
    try {
      await TicketPdf.compartir(venta, nombreNegocio: negocio);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo compartir: $e', esError: true);
      }
    }
  }
}

/// Estado de envío de la venta, **en vivo**.
///
/// Antes esto era una foto fija de `venta.sincronizadaEn == null`, y ese valor
/// acaba de nacer nulo por definición: la venta se guarda en local y el envío
/// va con tres segundos de rebote. Resultado: con cobertura perfecta la
/// pantalla decía «se enviará cuando haya conexión», que es justo lo que hace
/// dudar al vendedor de si la venta salió o no.
///
/// Ahora se observan dos cosas —la fila real de la venta y el estado de la
/// red— y el aviso **cambia solo** delante del usuario cuando el envío termina.
/// Esa transición es la que construye la confianza en el modo offline.
class _EstadoEnvio extends ConsumerWidget {
  const _EstadoEnvio({required this.ventaUuid});

  final String ventaUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enviada = ref.watch(ventaProvider(ventaUuid)).value?.venta.sincronizadaEn != null;
    final sync = ref.watch(estadoSyncProvider).value ?? const EstadoSync();
    final hayRed = sync.hayConexion;

    final (color, fondo, icono, texto) = switch ((enviada, hayRed)) {
      (true, _) => (
          context.dominio.exito,
          context.dominio.exitoContenedor,
          Icons.cloud_done_rounded,
          'Guardada y enviada al servidor.',
        ),
      (false, true) => (
          context.dominio.info,
          context.dominio.infoContenedor,
          Icons.cloud_upload_rounded,
          'Guardada. Enviando al servidor…',
        ),
      (false, false) => (
          context.dominio.advertencia,
          context.dominio.advertenciaContenedor,
          Icons.cloud_off_rounded,
          'Guardada en el dispositivo. Se enviará sola cuando vuelva la conexión.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          // Un giro sólo mientras está enviando: un icono quieto no distingue
          // «en curso» de «atascado».
          if (!enviada && hayRed)
            Icon(icono, size: 20, color: color)
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 1400.ms, curve: Curves.linear)
          else
            Icon(icono, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.media,
              child: Text(
                texto,
                key: ValueKey(texto),
                style: context.textos.bodySmall?.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 440.ms);
  }
}
