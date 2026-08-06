import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ajustes/presentation/ajustes_page.dart';
import '../../features/ajustes/presentation/pendientes_page.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/usuarios_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/inventario/presentation/entrada_page.dart';
import '../../features/inventario/presentation/movimientos_page.dart';
import '../../features/productos/presentation/producto_detalle_page.dart';
import '../../features/productos/presentation/producto_form_page.dart';
import '../../features/productos/presentation/productos_page.dart';
import '../../features/reportes/presentation/empleados_page.dart';
import '../../features/reportes/presentation/reportes_page.dart';
import '../../features/scanner/domain/modo_escaner.dart';
import '../../features/scanner/presentation/scanner_page.dart';
import '../../features/ventas/presentation/carrito_page.dart';
import '../../features/ventas/presentation/venta_detalle_page.dart';
import '../../features/ventas/presentation/ventas_page.dart';
import '../widgets/app_shell.dart';

/// Rutas de la app.
///
/// La guarda de sesión se resuelve con datos LOCALES: no hay ninguna petición
/// de red entre abrir la app y ver el dashboard. Abrirla en modo avión debe
/// llevar directamente a la pantalla de trabajo.
class Rutas {
  const Rutas._();

  static const login = '/login';
  static const dashboard = '/';
  static const productos = '/productos';
  static const ventas = '/ventas';
  static const reportes = '/reportes';
  static const escanear = '/escanear';
  static const carrito = '/carrito';
  static const entrada = '/entrada';
  static const movimientos = '/movimientos';
  static const ajustes = '/ajustes';
  static const pendientes = '/pendientes';
  static const usuarios = '/usuarios';
  static const empleados = '/empleados';
  static const productoNuevo = '/productos/nuevo';

  static String productoDetalle(String uuid) => '/productos/$uuid';
  static String productoEditar(String uuid) => '/productos/$uuid/editar';
  static String ventaDetalle(String uuid) => '/ventas/$uuid';
}

final _navegadorRaiz = GlobalKey<NavigatorState>(debugLabel: 'raiz');
final _navegadorShell = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Observador de rutas.
///
/// Lo necesita el escáner para saber cuándo deja de estar en primer plano: la
/// cámara es un recurso exclusivo del sistema y no puede seguir encendida
/// mientras el usuario está en el carrito. Se declara con `ModalRoute<dynamic>`
/// —y no `PageRoute`— para que también avise cuando se abre una hoja inferior
/// encima, como la rejilla de venta rápida.
final observadorRutas = RouteObserver<ModalRoute<dynamic>>();

/// Rutas reservadas al administrador.
///
/// El criterio no es «funciones avanzadas», es **qué permite tapar un robo**:
/// cargar existencias, ajustar un conteo, cambiar precios o anular ventas. El
/// vendedor vende; nada más toca el inventario ni la caja.
const _prefijosSoloAdmin = [
  Rutas.entrada, // cargar mercancía
  Rutas.movimientos, // kardex completo
  Rutas.reportes, // márgenes y costos del negocio
  Rutas.usuarios, // gestión de empleados
  Rutas.empleados, // control de cajas
];

bool _esRutaSoloAdmin(String ubicacion) {
  if (_prefijosSoloAdmin.any((p) => ubicacion.startsWith(p))) return true;
  // Alta y edición de productos, en cualquiera de sus formas.
  return ubicacion.endsWith('/nuevo') || ubicacion.endsWith('/editar');
}

/// Vuelve al escáner **sin apilar otra pantalla de cámara**.
///
/// El camino normal es escáner → carrito, así que el escáner sigue vivo debajo
/// y basta con hacer `pop`. Empujar uno nuevo dejaba DOS `ScannerPage` montadas
/// y dos `MobileScannerController` peleando por la cámara; el segundo fallaba
/// con «already running. Stop it before starting again», y como la pantalla de
/// error no tenía forma de volver, el usuario quedaba atrapado.
void volverAlEscaner(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.pushReplacement('${Rutas.escanear}?modo=venta');
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final sesion = ref.watch(sesionProvider);

  return GoRouter(
    navigatorKey: _navegadorRaiz,
    initialLocation: Rutas.dashboard,
    debugLogDiagnostics: false,
    observers: [observadorRutas],
    redirect: (context, estado) {
      // Mientras se resuelve la sesión guardada no se redirige: mover al
      // usuario y devolverlo produce un parpadeo desagradable al arrancar.
      if (sesion.isLoading) return null;

      final autenticado = sesion.value != null;
      final enLogin = estado.matchedLocation == Rutas.login;

      if (!autenticado && !enLogin) return Rutas.login;
      if (autenticado && enLogin) return Rutas.dashboard;

      // Barrera de rol en el enrutador.
      //
      // Ocultar los botones no basta: la ruta se puede alcanzar por un enlace
      // profundo, por el historial o por un `push` que se cuele en otra
      // pantalla. El servidor ya rechaza estas operaciones (ver
      // ROL_MINIMO en backend/src/modules/sync/service.js), pero dejar entrar
      // al vendedor a un formulario que nunca podrá guardar es cruel.
      if (autenticado && !(sesion.value?.esAdmin ?? false)) {
        if (_esRutaSoloAdmin(estado.matchedLocation)) return Rutas.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Rutas.login,
        builder: (context, estado) => const LoginPage(),
      ),

      // Escáner y carrito van fuera del shell: ocupan la pantalla completa
      // porque son el flujo de trabajo, no una sección más.
      GoRoute(
        path: Rutas.escanear,
        parentNavigatorKey: _navegadorRaiz,
        pageBuilder: (context, estado) => CustomTransitionPage(
          key: estado.pageKey,
          child: ScannerPage(
            modo: ModoEscaner.desde(estado.uri.queryParameters['modo']),
          ),
          transitionsBuilder: (context, animacion, _, hijo) => FadeTransition(
            opacity: animacion,
            child: ScaleTransition(
              scale: Tween(begin: 1.04, end: 1.0).animate(
                CurvedAnimation(parent: animacion, curve: Curves.easeOutCubic),
              ),
              child: hijo,
            ),
          ),
        ),
      ),
      GoRoute(
        path: Rutas.carrito,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => const CarritoPage(),
      ),
      GoRoute(
        path: Rutas.entrada,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => EntradaPage(
          productoUuid: estado.uri.queryParameters['producto'],
        ),
      ),
      GoRoute(
        path: Rutas.productoNuevo,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => ProductoFormPage(
          codigoInicial: estado.uri.queryParameters['codigo'],
        ),
      ),
      GoRoute(
        path: Rutas.movimientos,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => MovimientosPage(
          productoUuid: estado.uri.queryParameters['producto'],
        ),
      ),
      GoRoute(
        path: Rutas.ajustes,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => const AjustesPage(),
      ),
      GoRoute(
        path: Rutas.pendientes,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => const PendientesPage(),
      ),
      GoRoute(
        path: Rutas.empleados,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => const EmpleadosPage(),
      ),
      GoRoute(
        path: Rutas.usuarios,
        parentNavigatorKey: _navegadorRaiz,
        builder: (context, estado) => const UsuariosPage(),
      ),

      ShellRoute(
        navigatorKey: _navegadorShell,
        builder: (context, estado, hijo) => AppShell(child: hijo),
        routes: [
          GoRoute(
            path: Rutas.dashboard,
            pageBuilder: (context, estado) =>
                NoTransitionPage(key: estado.pageKey, child: const DashboardPage()),
          ),
          GoRoute(
            path: Rutas.productos,
            pageBuilder: (context, estado) =>
                NoTransitionPage(key: estado.pageKey, child: const ProductosPage()),
            routes: [
              GoRoute(
                path: 'nuevo',
                parentNavigatorKey: _navegadorRaiz,
                builder: (context, estado) => const ProductoFormPage(),
              ),
              GoRoute(
                path: ':uuid',
                parentNavigatorKey: _navegadorRaiz,
                builder: (context, estado) =>
                    ProductoDetallePage(uuid: estado.pathParameters['uuid']!),
                routes: [
                  GoRoute(
                    path: 'editar',
                    parentNavigatorKey: _navegadorRaiz,
                    builder: (context, estado) =>
                        ProductoFormPage(uuid: estado.pathParameters['uuid']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Rutas.ventas,
            pageBuilder: (context, estado) =>
                NoTransitionPage(key: estado.pageKey, child: const VentasPage()),
            routes: [
              GoRoute(
                path: ':uuid',
                parentNavigatorKey: _navegadorRaiz,
                builder: (context, estado) =>
                    VentaDetallePage(uuid: estado.pathParameters['uuid']!),
              ),
            ],
          ),
          GoRoute(
            path: Rutas.reportes,
            pageBuilder: (context, estado) =>
                NoTransitionPage(key: estado.pageKey, child: const ReportesPage()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, estado) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text('No se encontró ${estado.uri}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Rutas.dashboard),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
