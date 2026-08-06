import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/reportes_dao.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/widgets/contador_animado.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/sync_chip.dart';
import '../../auth/presentation/auth_providers.dart';
import 'dashboard_providers.dart';

/// Pantalla de inicio.
///
/// Es un dashboard **de acciones**, no de vanidad: lo primero que se ve son
/// Vender y Entrada, después las alertas de stock, y sólo al final los números.
/// Quien abre esta app en un mostrador quiere despachar, no contemplar gráficas.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final resumen = ref.watch(resumenDashboardProvider);
    final esAdmin = ref.watch(esAdminProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncEngineProvider).sincronizar(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              titleSpacing: 20,
              toolbarHeight: 72,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _saludo(),
                    style: context.textos.bodySmall?.copyWith(
                      color: context.colores.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    sesion?.nombre ?? ref.watch(nombreNegocioProvider),
                    style: context.textos.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                const SyncChip(compacto: true),
                IconButton(
                  onPressed: () => context.push(Rutas.ajustes),
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Ajustes',
                ),
                const SizedBox(width: 8),
              ],
            ),

            const SliverToBoxAdapter(child: _AvisoCaducidad()),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _AccionPrincipal(
                        icono: Icons.point_of_sale_rounded,
                        titulo: 'Vender',
                        subtitulo: 'Escanear y cobrar',
                        color: context.colores.primary,
                        alFrente: context.colores.onPrimary,
                        onTap: () => context.push('${Rutas.escanear}?modo=venta'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AccionPrincipal(
                        icono: Icons.move_to_inbox_rounded,
                        titulo: 'Entrada',
                        subtitulo: 'Recibir mercancía',
                        color: context.colores.secondaryContainer,
                        alFrente: context.colores.onSecondaryContainer,
                        onTap: () => context.push('${Rutas.escanear}?modo=entrada'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: resumen.when(
                  loading: () => const SkeletonBloque(alto: 150),
                  error: (e, _) => EstadoError(mensaje: '$e'),
                  data: (r) => _TarjetaHoy(resumen: r),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: _SeccionAlertas()),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: resumen.maybeWhen(
                  data: (r) => _RejillaIndicadores(resumen: r, verCostos: esAdmin),
                  orElse: () => const SkeletonBloque(alto: 180),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _AccesosRapidos(esAdmin: esAdmin),
              ),
            ),

            // Espacio para que la barra de navegación y el FAB no tapen la
            // última tarjeta.
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  static String _saludo() {
    final hora = Fechas.aHoraNegocio(DateTime.now().toUtc()).hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

// ─── Aviso de caducidad de la sesión offline ────────────────────────────────

class _AvisoCaducidad extends ConsumerWidget {
  const _AvisoCaducidad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    if (sesion == null || !sesion.avisarCaducidad) return const SizedBox.shrink();

    final dias = sesion.diasRestantes ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.dominio.advertenciaContenedor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: context.dominio.advertencia, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dias == 0
                    ? 'Tu sesión sin conexión caduca hoy. Conéctate a internet.'
                    : 'Te quedan $dias día${dias == 1 ? '' : 's'} para operar sin '
                        'conexión. Conéctate para renovar.',
                style: context.textos.bodySmall
                    ?.copyWith(color: context.dominio.advertencia),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Acciones principales ───────────────────────────────────────────────────

class _AccionPrincipal extends StatelessWidget {
  const _AccionPrincipal({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.alFrente,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color alFrente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 30, color: alFrente),
              const SizedBox(height: 14),
              Text(
                titulo,
                style: context.textos.titleMedium?.copyWith(color: alFrente),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: context.textos.bodySmall
                    ?.copyWith(color: alFrente.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Venta del día ──────────────────────────────────────────────────────────

class _TarjetaHoy extends StatelessWidget {
  const _TarjetaHoy({required this.resumen});

  final ResumenDashboard resumen;

  @override
  Widget build(BuildContext context) {
    final variacion = resumen.variacionVsAyer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Vendido hoy',
                  style: context.textos.labelLarge?.copyWith(
                    color: context.colores.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (variacion != null) _Variacion(porcentaje: variacion),
              ],
            ),
            const SizedBox(height: 8),
            // La cifra sube en lugar de aparecer: es el dato que el dueño abre
            // la app para ver, y el movimiento lleva el ojo hasta él.
            ContadorMoney(
              resumen.ventasHoy,
              style: context.textos.displaySmall?.copyWith(
                color: context.colores.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${resumen.numVentasHoy} venta${resumen.numVentasHoy == 1 ? '' : 's'}'
              '${resumen.numVentasHoy > 0 ? ' · ticket promedio ${resumen.ticketPromedio.format()}' : ''}',
              style: context.textos.bodySmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
            if (resumen.ventasPendientesSync > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.dominio.advertenciaContenedor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: context.dominio.advertencia,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${resumen.ventasPendientesSync} venta'
                      '${resumen.ventasPendientesSync == 1 ? '' : 's'} sin enviar',
                      style: context.textos.labelMedium
                          ?.copyWith(color: context.dominio.advertencia),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _MiniGrafica(),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 300.ms);
  }
}

class _Variacion extends StatelessWidget {
  const _Variacion({required this.porcentaje});

  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final sube = porcentaje >= 0;
    final color = sube ? context.dominio.exito : context.dominio.peligro;
    final fondo = sube ? context.dominio.exitoContenedor : context.dominio.peligroContenedor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sube ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${porcentaje.abs().toStringAsFixed(0)} % vs ayer',
            style: context.textos.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Serie de 14 días dibujada a mano.
///
/// No se usa `fl_chart` aquí: para catorce barras sin ejes ni tooltips, un
/// `Row` de contenedores es más barato de pintar y no arrastra un layout que
/// haya que domar. `fl_chart` sí se usa en la pantalla de reportes.
class _MiniGrafica extends ConsumerWidget {
  const _MiniGrafica();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serie = ref.watch(serieVentasProvider).value ?? const <PuntoSerie>[];
    if (serie.isEmpty) return const SizedBox(height: 48);

    final maximo = serie.fold<int>(0, (m, p) => p.total.centavos > m ? p.total.centavos : m);
    if (maximo == 0) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Sin ventas en los últimos 14 días',
            style: context.textos.bodySmall?.copyWith(
              color: context.colores.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < serie.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Tooltip(
                message: '${Fechas.formatDiaCorto(serie[i].dia)}: '
                    '${serie[i].total.format()}',
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 260 + i * 18),
                  curve: Curves.easeOutCubic,
                  height: 6 + 42 * (serie[i].total.centavos / maximo),
                  decoration: BoxDecoration(
                    color: i == serie.length - 1
                        ? context.colores.primary
                        : context.colores.primary.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Alertas de stock ───────────────────────────────────────────────────────

class _SeccionAlertas extends ConsumerWidget {
  const _SeccionAlertas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bajos = ref.watch(stockBajoProvider).value ?? const [];
    if (bajos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: context.dominio.advertencia),
              const SizedBox(width: 8),
              Text('Necesita reposición', style: context.textos.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('${Rutas.productos}?stock=bajo'),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < bajos.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    onTap: () => context.push(Rutas.productoDetalle(bajos[i].uuid)),
                    leading: CircleAvatar(
                      backgroundColor: bajos[i].agotado
                          ? context.dominio.peligroContenedor
                          : context.dominio.advertenciaContenedor,
                      child: Icon(
                        bajos[i].agotado
                            ? Icons.remove_shopping_cart_outlined
                            : Icons.inventory_outlined,
                        size: 20,
                        color: bajos[i].agotado
                            ? context.dominio.peligro
                            : context.dominio.advertencia,
                      ),
                    ),
                    title: Text(bajos[i].nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'Quedan ${bajos[i].stock.formatConUnidad(bajos[i].producto.unidadMedida)}'
                      ' · mínimo ${bajos[i].stockMinimo.format()}',
                      style: context.textos.bodySmall,
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          context.push('${Rutas.entrada}?producto=${bajos[i].uuid}'),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      tooltip: 'Registrar entrada',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 140.ms, duration: 300.ms),
    );
  }
}

// ─── Indicadores ────────────────────────────────────────────────────────────

class _RejillaIndicadores extends StatelessWidget {
  const _RejillaIndicadores({required this.resumen, required this.verCostos});

  final ResumenDashboard resumen;
  final bool verCostos;

  @override
  Widget build(BuildContext context) {
    final tarjetas = <Widget>[
      _Indicador(
        icono: Icons.calendar_view_week_rounded,
        etiqueta: 'Últimos 7 días',
        valor: resumen.ventasSemana.format(),
      ),
      _Indicador(
        icono: Icons.calendar_month_rounded,
        etiqueta: 'Últimos 30 días',
        valor: resumen.ventasMes.format(),
      ),
      _Indicador(
        icono: Icons.inventory_2_outlined,
        etiqueta: 'Productos activos',
        valor: '${resumen.productosActivos}',
      ),
      _Indicador(
        icono: Icons.error_outline_rounded,
        etiqueta: 'Agotados',
        valor: '${resumen.productosAgotados}',
        color: resumen.productosAgotados > 0 ? context.dominio.peligro : null,
      ),
      // El vendedor no ve costos ni márgenes: es información sensible del
      // negocio y no la necesita para despachar.
      if (verCostos)
        _Indicador(
          icono: Icons.savings_outlined,
          etiqueta: 'Margen 30 días',
          valor: resumen.margenMes.format(),
          color: context.dominio.exito,
        ),
      if (verCostos)
        _Indicador(
          icono: Icons.account_balance_wallet_outlined,
          etiqueta: 'Inventario a costo',
          valor: resumen.valorInventario.format(),
        ),
    ];

    return LayoutBuilder(
      builder: (context, restricciones) {
        // Dos columnas en teléfono, tres en tableta. La app se usa sobre todo
        // en vertical, pero un mostrador con tableta no es raro.
        final columnas = restricciones.maxWidth > 620 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: tarjetas,
        );
      },
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icono, size: 20, color: color ?? context.colores.onSurfaceVariant),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: context.textos.titleLarge?.copyWith(color: color),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textos.bodySmall?.copyWith(
                color: context.colores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Accesos rápidos ────────────────────────────────────────────────────────

class _AccesosRapidos extends StatelessWidget {
  const _AccesosRapidos({required this.esAdmin});

  final bool esAdmin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.swap_vert_rounded),
            title: const Text('Movimientos de inventario'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Rutas.movimientos),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded),
            title: const Text('Consultar un producto'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('${Rutas.escanear}?modo=consulta'),
          ),
          if (esAdmin) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Nuevo producto'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Rutas.productoNuevo),
            ),
          ],
        ],
      ),
    );
  }
}
