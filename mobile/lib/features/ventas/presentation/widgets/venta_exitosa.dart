import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/ventas_dao.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/estados.dart';
import '../../data/ticket_pdf.dart';

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
              _EstadoEnvio(pendiente: venta.pendienteDeSync),
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

class _EstadoEnvio extends StatelessWidget {
  const _EstadoEnvio({required this.pendiente});

  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    final (color, fondo, icono, texto) = pendiente
        ? (
            context.dominio.advertencia,
            context.dominio.advertenciaContenedor,
            Icons.cloud_upload_outlined,
            'Guardada en el dispositivo. Se enviará sola cuando haya conexión.',
          )
        : (
            context.dominio.exito,
            context.dominio.exitoContenedor,
            Icons.cloud_done_outlined,
            'Guardada en el dispositivo y en camino al servidor.',
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: context.textos.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 440.ms);
  }
}
