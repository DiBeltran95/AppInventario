import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ventas_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/ticket_pdf.dart';
import 'ventas_providers.dart';

/// Detalle de una venta.
///
/// Una venta **no se edita ni se borra nunca**. Para corregir un error se emite
/// una anulación, que es un documento nuevo que referencia al original y
/// devuelve el stock. Es un requisito contable, no una preferencia: el ticket
/// ya se entregó impreso y el histórico tiene que cuadrar con él.
class VentaDetallePage extends ConsumerWidget {
  const VentaDetallePage({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asincrono = ref.watch(ventaProvider(uuid));
    final puedeAnular = ref.watch(rolProvider).puedeAnularVentas;
    final negocio = ref.watch(nombreNegocioProvider);

    return asincrono.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: EstadoError(mensaje: '$e')),
      data: (venta) {
        if (venta == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EstadoVacio(
              icono: Icons.receipt_long_outlined,
              titulo: 'Venta no encontrada',
            ),
          );
        }

        final v = venta.venta;
        final anulada = venta.anulada;

        return Scaffold(
          appBar: AppBar(
            title: Text(v.numero),
            actions: [
              IconButton(
                onPressed: () => _compartir(context, venta, negocio),
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartir ticket',
              ),
              IconButton(
                onPressed: () => _imprimir(context, venta, negocio),
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Imprimir ticket',
              ),
              if (puedeAnular && !anulada && v.anulaAVentaUuid == null)
                PopupMenuButton<String>(
                  onSelected: (_) => _anular(context, ref, venta),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'anular',
                      child: Text(
                        'Anular venta',
                        style: TextStyle(color: context.dominio.peligro),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (anulada) _BannerAnulada(motivo: v.motivoAnulacion),
              _Cabecera(venta: venta),
              const SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < venta.detalles.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _FilaDetalle(detalle: venta.detalles[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _fila(context, 'Base gravable', Money(v.subtotal).format()),
                      if (v.descuentoTotal != 0)
                        _fila(context, 'Descuentos', '-${Money(v.descuentoTotal).format()}'),
                      _fila(context, 'IVA', Money(v.impuestoTotal).format()),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Text('Total', style: context.textos.titleMedium),
                          const Spacer(),
                          Text(
                            Money(v.total).format(),
                            style: context.textos.headlineSmall
                                ?.copyWith(color: context.colores.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _fila(context, 'Método de pago', _metodo(v.metodoPago)),
                      if (v.montoRecibido != null)
                        _fila(context, 'Recibido', Money(v.montoRecibido!).format()),
                      if (v.cambio != null && v.cambio! > 0)
                        _fila(context, 'Cambio', Money(v.cambio!).format()),
                    ],
                  ),
                ),
              ),

              if (ref.watch(esAdminProvider) && v.costoTotal != 0) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _fila(context, 'Costo de la mercancía', Money(v.costoTotal).format()),
                        _fila(
                          context,
                          'Margen bruto',
                          Money(v.total - v.costoTotal).format(),
                          color: v.total - v.costoTotal >= 0
                              ? context.dominio.exito
                              : context.dominio.peligro,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _fila(BuildContext context, String etiqueta, String valor, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(
              etiqueta,
              style: context.textos.bodyMedium
                  ?.copyWith(color: context.colores.onSurfaceVariant),
            ),
            const Spacer(),
            Text(valor, style: context.textos.bodyMedium?.copyWith(color: color)),
          ],
        ),
      );

  Future<void> _imprimir(
    BuildContext context,
    VentaCompleta venta,
    String negocio,
  ) async {
    try {
      await TicketPdf.imprimir(venta, nombreNegocio: negocio);
    } catch (e) {
      if (context.mounted) mostrarMensaje(context, 'No se pudo imprimir: $e', esError: true);
    }
  }

  Future<void> _compartir(
    BuildContext context,
    VentaCompleta venta,
    String negocio,
  ) async {
    try {
      await TicketPdf.compartir(venta, nombreNegocio: negocio);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo compartir: $e', esError: true);
      }
    }
  }

  Future<void> _anular(BuildContext context, WidgetRef ref, VentaCompleta venta) async {
    final controlador = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Anular venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La venta no se borra: se emite un documento de reversa que la '
              'anula y devuelve el stock. Ambos quedan en el historial.',
              style: context.textos.bodySmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controlador,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Motivo *'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.dominio.peligro),
            onPressed: () {
              final texto = controlador.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(dialogo, texto);
            },
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    controlador.dispose();
    if (motivo == null || !context.mounted) return;

    try {
      await ref.read(ventasDaoProvider).anular(
            venta.venta.uuid,
            motivo,
            usuarioUuid: ref.read(sesionProvider).value?.usuarioUuid,
          );
      ref.read(syncEngineProvider).solicitar();
      if (context.mounted) mostrarMensaje(context, 'Venta anulada', esExito: true);
    } catch (e) {
      if (context.mounted) {
        mostrarMensaje(context, 'No se pudo anular: $e', esError: true);
      }
    }
  }

  static String _metodo(String codigo) => switch (codigo) {
        'EFECTIVO' => 'Efectivo',
        'TARJETA' => 'Tarjeta',
        'TRANSFERENCIA' => 'Transferencia',
        _ => codigo,
      };
}

// ─── Piezas ─────────────────────────────────────────────────────────────────

class _BannerAnulada extends StatelessWidget {
  const _BannerAnulada({this.motivo});

  final String? motivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dominio.peligroContenedor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.block_rounded, color: context.dominio.peligro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venta anulada',
                  style: context.textos.titleSmall
                      ?.copyWith(color: context.dominio.peligro),
                ),
                if (motivo != null)
                  Text(
                    motivo!,
                    style: context.textos.bodySmall
                        ?.copyWith(color: context.dominio.peligro),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.venta});

  final VentaCompleta venta;

  @override
  Widget build(BuildContext context) {
    final v = venta.venta;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: context.colores.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  Fechas.formatFechaHora(v.fecha),
                  style: context.textos.bodyMedium,
                ),
                const Spacer(),
                if (venta.pendienteDeSync)
                  Chip(
                    avatar: Icon(
                      Icons.cloud_upload_outlined,
                      size: 14,
                      color: context.dominio.advertencia,
                    ),
                    label: Text(
                      'Sin enviar',
                      style: context.textos.labelSmall
                          ?.copyWith(color: context.dominio.advertencia),
                    ),
                    backgroundColor: context.dominio.advertenciaContenedor,
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Chip(
                    avatar: Icon(
                      Icons.cloud_done_outlined,
                      size: 14,
                      color: context.dominio.exito,
                    ),
                    label: Text(
                      'Sincronizada',
                      style: context.textos.labelSmall
                          ?.copyWith(color: context.dominio.exito),
                    ),
                    backgroundColor: context.dominio.exitoContenedor,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (v.clienteNombre != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: context.colores.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(v.clienteNombre!, style: context.textos.bodyMedium),
                  if (v.clienteDocumento != null)
                    Text(
                      '  ·  ${v.clienteDocumento}',
                      style: context.textos.bodySmall?.copyWith(
                        color: context.colores.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
            if (v.creadaOffline) ...[
              const SizedBox(height: 10),
              Text(
                'Registrada sin conexión',
                style: context.textos.labelSmall?.copyWith(
                  color: context.colores.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  const _FilaDetalle({required this.detalle});

  final VentaDetalle detalle;

  @override
  Widget build(BuildContext context) {
    final cantidad = Cantidad(detalle.cantidad);
    final precio = Money(detalle.precioUnitario);

    return ListTile(
      title: Text(detalle.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${cantidad.format()} × ${precio.format()}'
        '${detalle.descuento != 0 ? '  ·  desc. ${Money(detalle.descuento).format()}' : ''}',
        style: context.textos.bodySmall,
      ),
      trailing: Text(
        Money(detalle.total).format(),
        style: context.textos.titleSmall,
      ),
    );
  }
}
