import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/ventas/presentation/carrito_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Armazón con la navegación principal.
///
/// El botón central de escanear es más grande y sobresale a propósito: escanear
/// es la acción que se repite cientos de veces al día, y debe ser alcanzable
/// con el pulgar sin mirar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// Destinos según el rol.
  ///
  /// El vendedor no ve «Reportes»: ahí viven los márgenes, los costos y la
  /// valorización del inventario, que son datos del negocio y no de su trabajo.
  /// Quitar la pestaña entera —en lugar de vaciarla— también le simplifica la
  /// vida: tres destinos en vez de cuatro para alguien que sólo despacha.
  static List<({String ruta, IconData icono, IconData activo, String etiqueta})> _destinosDe(
    bool esAdmin,
  ) =>
      [
        (ruta: Rutas.dashboard, icono: Icons.dashboard_outlined, activo: Icons.dashboard_rounded, etiqueta: 'Inicio'),
        (ruta: Rutas.productos, icono: Icons.inventory_2_outlined, activo: Icons.inventory_2_rounded, etiqueta: 'Productos'),
        (ruta: Rutas.ventas, icono: Icons.receipt_long_outlined, activo: Icons.receipt_long_rounded, etiqueta: 'Ventas'),
        if (esAdmin)
          (ruta: Rutas.reportes, icono: Icons.insights_outlined, activo: Icons.insights_rounded, etiqueta: 'Reportes'),
      ];

  int _indice(
    String ubicacion,
    List<({String ruta, IconData icono, IconData activo, String etiqueta})> destinos,
  ) {
    for (var i = destinos.length - 1; i >= 0; i--) {
      final ruta = destinos[i].ruta;
      if (ruta == Rutas.dashboard ? ubicacion == ruta : ubicacion.startsWith(ruta)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ubicacion = GoRouterState.of(context).matchedLocation;
    final destinos = _destinosDe(ref.watch(esAdminProvider));
    final indice = _indice(ubicacion, destinos);
    final articulos = ref.watch(carritoProvider).articulos;

    return Scaffold(
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _BotonEscanear(articulosEnCarrito: articulos),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (i) => context.go(destinos[i].ruta),
        destinations: [
          for (var i = 0; i < destinos.length; i++) ...[
            NavigationDestination(
              icon: Icon(destinos[i].icono),
              selectedIcon: Icon(destinos[i].activo),
              label: destinos[i].etiqueta,
            ),
            // Hueco central para que el FAB no tape ninguna pestaña.
            if (i == 1)
              const NavigationDestination(
                icon: SizedBox(width: 48),
                label: '',
                enabled: false,
              ),
          ],
        ],
      ),
    );
  }
}

class _BotonEscanear extends StatelessWidget {
  const _BotonEscanear({required this.articulosEnCarrito});

  final int articulosEnCarrito;

  @override
  Widget build(BuildContext context) {
    final boton = FloatingActionButton.large(
      heroTag: 'fab-escanear',
      onPressed: () => context.push('${Rutas.escanear}?modo=venta'),
      tooltip: 'Escanear producto',
      elevation: 4,
      child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
    );

    if (articulosEnCarrito == 0) return boton;

    return Badge.count(
      count: articulosEnCarrito,
      alignment: const AlignmentDirectional(0.9, -0.85),
      backgroundColor: context.dominio.advertencia,
      textColor: Colors.white,
      largeSize: 22,
      child: boton,
    );
  }
}
