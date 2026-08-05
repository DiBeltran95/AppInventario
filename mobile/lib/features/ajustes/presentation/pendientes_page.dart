import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';

/// Operaciones que el servidor rechazó de forma definitiva.
///
/// Un 400 o un 409 no se reintentan eternamente: reintentar algo que nunca va a
/// pasar la validación bloquea la cola FIFO y con ella todas las ventas que
/// vengan detrás. Esas operaciones se apartan aquí, donde una persona puede
/// decidir: reintentar (si ya corrigió la causa) o descartar.
///
/// Descartar **pierde** la operación. Por eso la pantalla muestra el payload
/// completo: antes de tirar una venta hay que poder ver qué contenía.
class PendientesPage extends ConsumerWidget {
  const PendientesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rechazadas = ref.watch(operacionesRechazadasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Elementos con problema')),
      body: rechazadas.when(
        loading: () => const SkeletonLista(),
        error: (e, _) => EstadoError(mensaje: '$e'),
        data: (lista) {
          if (lista.isEmpty) {
            return const EstadoVacio(
              icono: Icons.check_circle_outline_rounded,
              titulo: 'Todo en orden',
              descripcion:
                  'No hay operaciones rechazadas. Lo que esté pendiente se '
                  'enviará solo cuando haya conexión.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.dominio.advertenciaContenedor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: context.dominio.advertencia,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El servidor rechazó estas operaciones. No se reintentan '
                        'solas para no bloquear el envío del resto.',
                        style: context.textos.bodySmall
                            ?.copyWith(color: context.dominio.advertencia),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final operacion in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TarjetaRechazada(operacion: operacion),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaRechazada extends ConsumerWidget {
  const _TarjetaRechazada({required this.operacion});

  final SyncOutboxData operacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Theme(
        // Se quita la línea divisoria del ExpansionTile: dentro de una Card ya
        // hay borde, y dos marcos anidados ensucian la lista.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: context.dominio.peligroContenedor,
            child: Icon(
              _icono(operacion.tipo),
              size: 20,
              color: context.dominio.peligro,
            ),
          ),
          title: Text(_etiqueta(operacion.tipo), style: context.textos.titleSmall),
          subtitle: Text(
            '${Fechas.relativo(operacion.creadoEn)} · '
            '${operacion.intentos} intento${operacion.intentos == 1 ? '' : 's'}',
            style: context.textos.bodySmall,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            if (operacion.ultimoError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.dominio.peligroContenedor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (operacion.codigoError != null)
                      Text(
                        operacion.codigoError!,
                        style: context.textos.labelSmall?.copyWith(
                          color: context.dominio.peligro,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      operacion.ultimoError!,
                      style: context.textos.bodySmall
                          ?.copyWith(color: context.dominio.peligro),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _Payload(json: operacion.payload),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _descartar(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Descartar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.dominio.peligro,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(outboxDaoProvider)
                          .reintentarRechazada(operacion.id);
                      ref.read(syncEngineProvider).solicitar();
                      if (context.mounted) {
                        mostrarMensaje(context, 'Se reintentará el envío');
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descartar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Descartar la operación?'),
        content: const Text(
          'Se elimina de la cola y no llegará nunca al servidor. Los datos '
          'locales de esta operación quedan como están, pero el servidor no se '
          'enterará de ella. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.dominio.peligro),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await ref.read(outboxDaoProvider).descartar(operacion.id);
    if (context.mounted) mostrarMensaje(context, 'Operación descartada');
  }

  static IconData _icono(String tipo) {
    if (tipo.startsWith('VENTA')) return Icons.receipt_long_rounded;
    if (tipo.startsWith('PRODUCTO')) return Icons.inventory_2_rounded;
    if (tipo.startsWith('MOVIMIENTO') || tipo.startsWith('CONTEO')) {
      return Icons.swap_vert_rounded;
    }
    if (tipo.startsWith('CODIGO')) return Icons.qr_code_rounded;
    return Icons.sync_problem_rounded;
  }

  static String _etiqueta(String tipo) => switch (tipo) {
        'VENTA_CREAR' => 'Venta',
        'VENTA_ANULAR' => 'Anulación de venta',
        'PRODUCTO_CREAR' => 'Alta de producto',
        'PRODUCTO_ACTUALIZAR' => 'Cambio de producto',
        'PRODUCTO_ELIMINAR' => 'Baja de producto',
        'MOVIMIENTO_CREAR' => 'Movimiento de inventario',
        'CONTEO_AJUSTAR' => 'Ajuste por conteo',
        'CODIGO_CREAR' => 'Alta de código',
        'CODIGO_ELIMINAR' => 'Baja de código',
        _ => tipo,
      };
}

class _Payload extends StatelessWidget {
  const _Payload({required this.json});

  final String json;

  @override
  Widget build(BuildContext context) {
    // Se reindenta para que sea legible: el payload va guardado compacto y en
    // una sola línea no hay forma de revisar una venta de doce líneas.
    String bonito;
    try {
      bonito = const JsonEncoder.withIndent('  ').convert(jsonDecode(json));
    } catch (_) {
      bonito = json;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Contenido', style: context.textos.labelSmall),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: bonito));
                  mostrarMensaje(context, 'Copiado');
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: context.colores.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: SelectableText(
                bonito,
                style: context.textos.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
