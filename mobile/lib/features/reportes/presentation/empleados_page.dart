import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/reportes_dao.dart';
import '../../../core/money/money.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/contador_animado.dart';
import '../../../core/widgets/estados.dart';

/// Control de cajas: qué ha vendido cada empleado.
///
/// Es la pantalla que pidió el negocio para vigilar varios turnos. Dos criterios
/// la gobiernan:
///
/// 1. **Se calcula en local**, como el resto de los reportes: el dueño puede
///    revisar los turnos del día aunque el local se quede sin internet.
/// 2. **Sólo la ve el administrador.** El enrutador bloquea la ruta
///    (`_prefijosSoloAdmin`), no basta con esconder el botón: comparar
///    rendimientos entre compañeros no le corresponde a un vendedor.
class EmpleadosPage extends ConsumerStatefulWidget {
  const EmpleadosPage({super.key});

  @override
  ConsumerState<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends ConsumerState<EmpleadosPage>
    with AnimacionPrimeraCarga {
  String _periodo = 'hoy';

  ({String desde, String hasta}) get _rango {
    final hoy = Fechas.hoy();
    return switch (_periodo) {
      'hoy' => (desde: hoy, hasta: hoy),
      'semana' => (desde: Fechas.sumarDias(hoy, -6), hasta: hoy),
      _ => (desde: Fechas.sumarDias(hoy, -29), hasta: hoy),
    };
  }

  @override
  Widget build(BuildContext context) {
    final rango = _rango;
    final datos = ref.watch(rendimientoEmpleadosProvider(rango));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de cajas'),
        actions: [
          IconButton(
            onPressed: () => context.push(Rutas.usuarios),
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Gestionar empleados',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'hoy', label: Text('Hoy')),
                ButtonSegment(value: 'semana', label: Text('7 días')),
                ButtonSegment(value: 'mes', label: Text('30 días')),
              ],
              selected: {_periodo},
              onSelectionChanged: (s) => setState(() => _periodo = s.first),
            ),
          ),
          Expanded(
            child: datos.when(
              loading: () => const SkeletonLista(alturaFila: 108),
              error: (e, _) => EstadoError(mensaje: '$e'),
              data: (empleados) {
                if (empleados.isEmpty) {
                  return EstadoVacio(
                    icono: Icons.group_outlined,
                    titulo: 'Aún no hay empleados',
                    descripcion:
                        'Crea una cuenta de vendedor para que pueda registrar ventas '
                        'sin tocar el inventario.',
                    textoAccion: 'Crear empleado',
                    onAccion: () => context.push(Rutas.usuarios),
                  );
                }

                final totalPeriodo =
                    Money.sumar(empleados.map((e) => e.total));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: empleados.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) return _Encabezado(total: totalPeriodo, rango: rango);
                    final e = empleados[i - 1];
                    return EntradaEscalonada(
                      indice: i,
                      activo: enPrimeraCarga,
                      child: _TarjetaEmpleado(
                        empleado: e,
                        maximo: empleados.first.total,
                        rango: rango,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.total, required this.rango});

  final Money total;
  final ({String desde, String hasta}) rango;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendido en el periodo',
            style: context.textos.labelLarge
                ?.copyWith(color: context.colores.onSurfaceVariant),
          ),
          ContadorMoney(total, style: context.textos.headlineMedium),
          Text(
            rango.desde == rango.hasta
                ? Fechas.formatDiaIso(rango.desde)
                : '${Fechas.formatDiaCorto(rango.desde)} — ${Fechas.formatDiaCorto(rango.hasta)}',
            style: context.textos.bodySmall
                ?.copyWith(color: context.colores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TarjetaEmpleado extends ConsumerWidget {
  const _TarjetaEmpleado({
    required this.empleado,
    required this.maximo,
    required this.rango,
  });

  final RendimientoEmpleado empleado;
  final Money maximo;
  final ({String desde, String hasta}) rango;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proporcion = maximo.esCero
        ? 0.0
        : (empleado.total.centavos / maximo.centavos).clamp(0.0, 1.0);

    return Card(
      child: InkWell(
        onTap: () => _verHistorial(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: empleado.esAdmin
                        ? context.colores.primaryContainer
                        : context.colores.secondaryContainer,
                    child: Text(
                      _iniciales(empleado.nombre),
                      style: context.textos.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empleado.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textos.titleSmall,
                        ),
                        Text(
                          empleado.esAdmin ? 'Administrador' : 'Vendedor',
                          style: context.textos.bodySmall
                              ?.copyWith(color: context.colores.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(empleado.total.format(), style: context.textos.titleMedium),
                      Text(
                        '${empleado.numVentas} venta${empleado.numVentas == 1 ? '' : 's'}',
                        style: context.textos.bodySmall
                            ?.copyWith(color: context.colores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Barra proporcional al que más vendió: comparar turnos con
              // cifras sueltas obliga a hacer la división mentalmente.
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: proporcion,
                  minHeight: 6,
                  backgroundColor: context.colores.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (!empleado.sinActividad)
                    _Etiqueta(
                      icono: Icons.receipt_outlined,
                      texto: 'Ticket ${empleado.ticketPromedio.format()}',
                    ),
                  if (empleado.anuladas > 0)
                    _Etiqueta(
                      icono: Icons.block_rounded,
                      texto: '${empleado.anuladas} anulada'
                          '${empleado.anuladas == 1 ? '' : 's'}',
                      color: context.dominio.peligro,
                      fondo: context.dominio.peligroContenedor,
                    ),
                  if (empleado.creadasOffline > 0)
                    _Etiqueta(
                      icono: Icons.cloud_off_rounded,
                      texto: '${empleado.creadasOffline} sin conexión',
                      color: context.dominio.sinConexion,
                      fondo: context.dominio.sinConexionContenedor,
                    ),
                  if (empleado.sinActividad)
                    _Etiqueta(
                      icono: Icons.remove_circle_outline_rounded,
                      texto: 'Sin ventas',
                      color: context.dominio.advertencia,
                      fondo: context.dominio.advertenciaContenedor,
                    ),
                  if (empleado.ultimaVenta != null)
                    _Etiqueta(
                      icono: Icons.schedule_rounded,
                      texto: 'Última ${Fechas.relativo(empleado.ultimaVenta)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verHistorial(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _HistorialEmpleado(empleado: empleado, rango: rango),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

/// Historial de ventas de un empleado concreto.
class _HistorialEmpleado extends ConsumerWidget {
  const _HistorialEmpleado({required this.empleado, required this.rango});

  final RendimientoEmpleado empleado;
  final ({String desde, String hasta}) rango;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventas = ref.watch(
      ventasDeEmpleadoProvider((uuid: empleado.uuid, desde: rango.desde, hasta: rango.hasta)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(empleado.nombre, style: context.textos.titleLarge),
                      Text(
                        empleado.email,
                        style: context.textos.bodySmall
                            ?.copyWith(color: context.colores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(empleado.total.format(), style: context.textos.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ventas.when(
              loading: () => const SkeletonLista(alturaFila: 64),
              error: (e, _) => EstadoError(mensaje: '$e'),
              data: (lista) => lista.isEmpty
                  ? const EstadoVacio(
                      icono: Icons.receipt_long_outlined,
                      titulo: 'Sin ventas en el periodo',
                      compacto: true,
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: lista.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final v = lista[i];
                        final anulada = v.estado == 'ANULADA';
                        return ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            context.push(Rutas.ventaDetalle(v.uuid));
                          },
                          leading: Icon(
                            anulada ? Icons.block_rounded : Icons.receipt_outlined,
                            color: anulada ? context.dominio.peligro : null,
                          ),
                          title: Text(
                            v.numero,
                            style: anulada
                                ? const TextStyle(decoration: TextDecoration.lineThrough)
                                : null,
                          ),
                          subtitle: Text(
                            '${Fechas.formatFechaHora(v.fecha)} · ${v.metodoPago.toLowerCase()}'
                            '${v.sincronizadaEn == null ? ' · sin enviar' : ''}',
                          ),
                          trailing: Text(
                            Money(v.total).format(),
                            style: context.textos.titleSmall,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto, this.color, this.fondo});

  final IconData icono;
  final String texto;
  final Color? color;
  final Color? fondo;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colores.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fondo ?? context.colores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: c),
          const SizedBox(width: 5),
          Text(texto, style: context.textos.labelSmall?.copyWith(color: c)),
        ],
      ),
    );
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

typedef _Rango = ({String desde, String hasta});
typedef _FiltroEmpleado = ({String uuid, String desde, String hasta});

final rendimientoEmpleadosProvider = StreamProvider.autoDispose
    .family<List<RendimientoEmpleado>, _Rango>((ref, rango) {
  return ref
      .watch(reportesDaoProvider)
      .observarPorEmpleado(desde: rango.desde, hasta: rango.hasta);
});

final ventasDeEmpleadoProvider =
    StreamProvider.autoDispose.family<List<Venta>, _FiltroEmpleado>((ref, f) {
  return ref.watch(ventasDaoProvider).observarVentas(
        usuarioUuid: f.uuid,
        desde: f.desde,
        hasta: f.hasta,
        estado: null,
        limite: 300,
      );
});
