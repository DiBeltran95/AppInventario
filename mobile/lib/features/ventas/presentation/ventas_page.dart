import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/sync_chip.dart';
import 'ventas_providers.dart';

/// Historial de ventas.
///
/// Cada fila indica si la venta **ya salió del dispositivo**. Es el mismo
/// principio que el chip de sincronización: en una app offline-first, ocultar
/// ese estado es lo que hace que el dueño deje de confiar en los números.
class VentasPage extends ConsumerWidget {
  const VentasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroVentasProvider);
    final ventas = ref.watch(ventasProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Ventas', style: context.textos.headlineSmall)),
                  const SyncChip(compacto: true),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final rango in RangoVentas.values) ...[
                    ChoiceChip(
                      label: Text(rango.etiqueta),
                      selected: filtro.rango == rango,
                      onSelected: (_) =>
                          ref.read(filtroVentasProvider.notifier).porRango(rango),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ventas.when(
                loading: () => const SkeletonLista(),
                error: (e, _) => EstadoError(mensaje: '$e'),
                data: (lista) {
                  if (lista.isEmpty) {
                    return EstadoVacio(
                      icono: Icons.receipt_long_outlined,
                      titulo: filtro.rango == RangoVentas.hoy
                          ? 'Aún no hay ventas hoy'
                          : 'Sin ventas en este periodo',
                      descripcion: 'Escanea un producto para registrar la primera.',
                      textoAccion: 'Vender',
                      onAccion: () => context.push('${Rutas.escanear}?modo=venta'),
                    );
                  }

                  final total = Money.sumar(
                    lista.where((v) => v.estado == 'COMPLETADA').map((v) => Money(v.total)),
                  );

                  return Column(
                    children: [
                      _Resumen(
                        total: total,
                        cantidad: lista.where((v) => v.estado == 'COMPLETADA').length,
                        etiqueta: filtro.rango.etiqueta.toLowerCase(),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          itemCount: lista.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _FilaVenta(venta: lista[i]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends ConsumerWidget {
  const _Resumen({
    required this.total,
    required this.cantidad,
    required this.etiqueta,
  });

  final Money total;
  final int cantidad;
  final String etiqueta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(estadoSyncProvider).value?.pendientes ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total $etiqueta',
                style: context.textos.labelMedium?.copyWith(
                  color: context.colores.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total.format(),
                style: context.textos.headlineSmall
                    ?.copyWith(color: context.colores.onPrimaryContainer),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$cantidad venta${cantidad == 1 ? '' : 's'}',
                style: context.textos.bodyMedium
                    ?.copyWith(color: context.colores.onPrimaryContainer),
              ),
              if (pendientes > 0)
                Text(
                  '$pendientes por enviar',
                  style: context.textos.labelSmall?.copyWith(
                    color: context.colores.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaVenta extends StatelessWidget {
  const _FilaVenta({required this.venta});

  final Venta venta;

  @override
  Widget build(BuildContext context) {
    final anulada = venta.estado == 'ANULADA';
    final pendiente = venta.sincronizadaEn == null;

    return Card(
      child: ListTile(
        onTap: () => context.push(Rutas.ventaDetalle(venta.uuid)),
        leading: CircleAvatar(
          backgroundColor: anulada
              ? context.dominio.peligroContenedor
              : context.colores.secondaryContainer,
          child: Icon(
            anulada ? Icons.block_rounded : Icons.receipt_long_rounded,
            size: 20,
            color: anulada
                ? context.dominio.peligro
                : context.colores.onSecondaryContainer,
          ),
        ),
        title: Row(
          children: [
            Text(venta.numero, style: context.textos.titleSmall),
            if (anulada) ...[
              const SizedBox(width: 8),
              Text(
                'ANULADA',
                style: context.textos.labelSmall?.copyWith(
                  color: context.dominio.peligro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          [
            Fechas.formatHora(venta.fecha),
            if (venta.clienteNombre != null) venta.clienteNombre!,
            _metodo(venta.metodoPago),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Money(venta.total).format(),
              style: context.textos.titleSmall?.copyWith(
                decoration: anulada ? TextDecoration.lineThrough : null,
                color: anulada ? context.colores.onSurfaceVariant : null,
              ),
            ),
            if (pendiente)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 12,
                    color: context.dominio.advertencia,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'sin enviar',
                    style: context.textos.labelSmall
                        ?.copyWith(color: context.dominio.advertencia),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _metodo(String codigo) => switch (codigo) {
        'EFECTIVO' => 'Efectivo',
        'TARJETA' => 'Tarjeta',
        'TRANSFERENCIA' => 'Transferencia',
        _ => codigo,
      };
}
