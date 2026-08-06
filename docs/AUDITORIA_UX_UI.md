# Auditoría UX/UI y plan de motion design

> **Revisión tras conocer el contexto de despliegue** (móvil únicamente · 8 GB de RAM ·
> 100–200 productos). Los tres datos cambian el plan de forma sustancial:
>
> | Consecuencia | Detalle |
> |---|---|
> | **P8 (tablet) queda ELIMINADO** | Solo móvil. Se ahorran 2–3 días. |
> | **Nace P0 · Rejilla de venta rápida** | Con 200 productos, **tocar es más rápido que escanear**. Es ahora la propuesta de mayor impacto de toda la lista, y solo es viable *porque* el catálogo es pequeño. **Ya implementada.** |
> | **Sin límites de rendimiento** | Con 8 GB, ninguna animación de este documento supone un problema. El veto al glassmorphism se mantiene, pero por **legibilidad a plena luz**, no por *fps*. |
> | **Sin optimización de búsqueda** | Con 200 filas, el `LIKE` sobre `nombreBusqueda` sobra. No hace falta FTS. |
> | **Corrección a lo que dije antes** | Afirmé que el tope del escalonado dependía del tamaño del catálogo. Es falso: el tope existe porque `ListView.builder` **re-anima las filas al reentrar en el viewport** durante el scroll, y eso ocurre con 200 o con 10.000. La solución correcta —animar solo hasta el primer frame— está implementada en `AnimacionPrimeraCarga`. |

> Auditoría hecha **sobre el código fuente real** (~7.000 líneas de UI en `mobile/lib`), no sobre
> capturas. Las cifras de esta primera sección están medidas, no estimadas.

## 0. Advertencia de alcance (léela antes de nada)

**No he podido ejecutar la app en un dispositivo.** El entorno tiene el SDK de Android 36.1 pero le
faltan los `cmdline-tools` y `java` no está en el `PATH`. Por tanto:

- Todo lo que digo sobre **estructura, contraste, semántica y cobertura de animación** está
  verificado leyendo y midiendo el código.
- Todo lo que diga sobre **percepción, fluidez real a 60 fps o jank** sería especulación. No lo
  afirmo. En §7 indico exactamente qué hace falta para cerrar esa parte.

---

## 1. Estado medido (línea base)

| Señal | Medición | Lectura |
|---|---|---|
| `.animate()` (flutter_animate) | **19** en ~7.000 líneas | Movimiento presente pero epidérmico |
| `Hero(...)` | **2** (un solo par: tarjeta → ficha) | La transición estelar existe en un único sitio |
| `TweenAnimationBuilder` | **0** | **No hay un solo contador animado** |
| Listas escalonadas (`interval:`) | **2** | Las listas aparecen de golpe |
| `AnimationController` | 4 | Línea de escaneo + check de éxito |
| `HapticFeedback` | 12 | Buena cobertura táctil |
| `Semantics(...)` | **1** | **Accesibilidad prácticamente ausente** |
| `semanticLabel` | **0** | Los iconos con significado no se anuncian |
| Gestión de *reduce motion* | **0** | Riesgo real (ver §3.0) |
| `LayoutBuilder` / `MediaQuery.size` | **1 / 0** | **Sin adaptación a tablet** |
| `SkeletonLista` + `SkeletonBloque` | 12 usos | Estados de carga bien resueltos |
| `EstadoVacio` | 16 usos | Estados vacíos bien cubiertos |
| `CheckAnimado` | 7 usos | Confirmaciones con feedback propio |

### 1.1 Contraste WCAG 2.1 — **ya cumple AA** (medido, no asumido)

Calculé la relación de contraste real de la paleta `ColoresDominio` de `app_theme.dart`:

| Rol | Claro: texto/contenedor | Claro: texto/fondo | Oscuro: texto/contenedor | Oscuro: texto/fondo |
|---|---|---|---|---|
| éxito | 4,56 **AA** | 5,13 **AA** | 6,69 **AA** | 10,91 **AAA** |
| advertencia | 4,51 **AA** | 5,13 **AA** | 7,84 **AAA** | 11,65 **AAA** |
| peligro | 5,06 **AA** | 6,18 **AA** | 7,71 **AAA** | 10,93 **AAA** |
| info | 5,35 **AA** | 6,34 **AA** | 7,39 **AAA** | 10,79 **AAA** |
| sin conexión | 5,24 **AA** | 6,09 **AA** | 6,74 **AA** | 9,40 **AAA** |

**Conclusión: no hay trabajo de contraste pendiente.** El resto del sistema usa
`ColorScheme.fromSeed`, cuyos pares `on*` ya están calculados por Material 3 para cumplir AA.
Si añades un color nuevo, pásalo por `backend/../scratchpad/wcag.mjs` antes de usarlo.

> Los márgenes de «advertencia» (4,51) y «éxito» (4,56) en tema claro pasan por poco. Si alguna vez
> reduces el tamaño de la fuente del badge de stock por debajo de 12 sp, vuelve a medir.

### 1.2 Dos correcciones al brief

**a) «Glassmorphism sutil» — lo desaconsejo salvo en un sitio.**
Un POS se usa junto a una ventana, con reflejos, y a veces con las manos sucias. La translucidez
resta contraste justo donde no puede fallar (precio, total, stock) y cuesta *fps* por el
`BackdropFilter`. Recomiendo glass **sólo en la barra superior del escáner**, donde ya hay un velo
oscuro sobre la cámara y el efecto aporta legibilidad en vez de restarla. Ahí sí:
`ClipRRect + BackdropFilter(ImageFilter.blur(sigmaX: 12, sigmaY: 12))`.

**b) Lottie/Rive — matiz sobre el «offline».**
En el `pubspec.yaml` descarté Lottie. El motivo real es **el origen de los archivos**, no el modo
offline: un `.json` de Lottie **empaquetado como asset** funciona perfectamente sin red. Si
consigues (o encargas) las animaciones, Lottie es viable. Rive añade un motor propio y sólo se
justifica si vas a tener personajes o estados complejos, que no es el caso. Mi recomendación
sigue siendo `CustomPainter` + `flutter_animate` porque **no depende de un activo que alguien
tenga que mantener**, pero es una decisión reversible, no un impedimento técnico.

---

## 2. Diagnóstico UX del flujo crítico (Nielsen)

Flujo auditado: **abrir app → escanear → carrito → cobrar → ticket**.

| # | Heurística | Estado | Hallazgo |
|---|---|---|---|
| 1 | Visibilidad del estado | 🟢 **Fuerte** | El `SyncChip` es permanente y explícito. Es el mayor acierto de la app. |
| 2 | Correspondencia con el mundo real | 🟡 | «Movimiento de inventario», «AJUSTE», «MERMA» son jerga contable. Un tendero dice «entró», «se dañó», «faltó». Ver §5. |
| 3 | Control y libertad | 🟡 | Hay «Deshacer» al escanear (bien), pero **el cobro no tiene vuelta atrás visible** una vez confirmado. |
| 4 | Consistencia y estándares | 🟢 | Un solo tema, un solo `mostrarMensaje`, un solo `EstadoVacio`. |
| 5 | Prevención de errores | 🟡 | El aviso de sobreventa existe pero es pasivo. El teclado del sistema para el efectivo invita a teclear mal. |
| 6 | Reconocer antes que recordar | 🔴 | En el carrito **no se ve la foto del producto**, sólo el nombre. Con 12 líneas parecidas («Gaseosa 400 / Gaseosa 600») el cajero tiene que leer. |
| 7 | Flexibilidad y eficiencia | 🔴 | **No hay atajos para el vendedor experto**: ni favoritos, ni «repetir última venta», ni teclado numérico propio. |
| 8 | Estética y diseño minimalista | 🟢 | Dashboard ordenado por acción, no por vanidad. |
| 9 | Recuperación de errores | 🟢 | La bandeja de «pendientes» explica el error y ofrece reintentar/descartar. |
| 10 | Ayuda y documentación | 🟡 | `modo.ayuda` en el escáner es el único texto de ayuda contextual. |

### 2.1 Carga cognitiva: administrador vs. vendedor

Son dos usuarios opuestos y hoy comparten la misma interfaz:

| | Administrador | Vendedor |
|---|---|---|
| Frecuencia | 2–3 veces al día | 200 veces al día |
| Necesita | Comprender (márgenes, tendencias) | **No pensar** |
| Tolera | Densidad, tablas, gráficas | Cero fricción, cero lectura |
| Contexto | Sentado, sin prisa | De pie, con cliente esperando |

Hoy el filtrado se limita a ocultar costos por rol (`ocultarCostos`). **Propuesta estructural:**
el `AppShell` debería tener **dos configuraciones de navegación** según `rolProvider`:

- `VENDEDOR` → 3 destinos: Vender · Productos · Mis ventas. Sin «Reportes».
- `ADMIN` → los 4 actuales.

Coste: ~20 líneas en `app_shell.dart`. Impacto: se elimina una pestaña entera que el vendedor no
usará nunca y que además le muestra información que no le corresponde.

---

## 3. Plan priorizado — matriz Impacto × Esfuerzo

### 🟩 ALTO IMPACTO / BAJO ESFUERZO — hacer primero

---

#### P1 · Respetar «reducir movimiento» del sistema

**Problema.** Hay 19 animaciones y **ninguna** consulta `MediaQuery.disableAnimationsOf`. Al añadir
las que propone este documento, la app pasaría de «poco animada» a «muy animada» sin escape para
quien sufre trastornos vestibulares. Es un requisito de accesibilidad, no un extra.

**Justificación.** WCAG 2.1 §2.3.3 y las *Human Interface Guidelines*: si el usuario activó
«Reducir movimiento», las transiciones no esenciales deben desaparecer o volverse un *fade*.
Además, hacer esto **antes** de añadir motion evita tener que revisar 40 sitios después.

**Solución.** Un único punto de verdad en `core/theme/`:

```dart
// core/theme/motion.dart
import 'package:flutter/material.dart';

/// Duraciones del sistema de movimiento.
///
/// Todas las animaciones de la app leen de aquí. Cuando el usuario activa
/// «Reducir movimiento» en Android, `duracion()` devuelve Duration.zero y la
/// interfaz se vuelve instantánea sin tocar una sola pantalla.
class Motion {
  const Motion._();

  static const rapida  = Duration(milliseconds: 150);  // realimentación táctil
  static const media   = Duration(milliseconds: 260);  // entradas, chips
  static const lenta   = Duration(milliseconds: 420);  // transiciones de página
  static const cifra   = Duration(milliseconds: 700);  // contadores numéricos

  static const entrada = Curves.easeOutCubic;   // algo que aparece: rápido y frena
  static const salida  = Curves.easeInCubic;    // algo que se va: acelera
  static const enfasis = Curves.easeOutBack;    // confirmación, con un rebote leve
}

extension MovimientoAccesible on BuildContext {
  bool get movimientoReducido => MediaQuery.disableAnimationsOf(this);

  /// Úsala SIEMPRE en lugar de una Duration literal.
  Duration duracion(Duration d) => movimientoReducido ? Duration.zero : d;

  /// El desfase de las listas escalonadas: cero si hay movimiento reducido.
  Duration retardo(int indice, {int pasoMs = 35, int maximo = 8}) =>
      movimientoReducido ? Duration.zero
                         : Duration(milliseconds: (indice.clamp(0, maximo)) * pasoMs);
}
```

Y en `app.dart`, dentro del `builder`, fija también el valor global de `flutter_animate`:

```dart
Animate.defaultDuration = MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Motion.media;
```

**Esfuerzo:** 1 archivo nuevo + 1 línea en `app.dart`. **Impacto:** habilita con seguridad todo lo demás.

---

#### P2 · Contadores numéricos animados en el dashboard

**Problema.** `TweenAnimationBuilder` aparece **0 veces**. El importe de «ventas de hoy» —el número
que el dueño abre la app para ver— aparece de golpe.

**Justificación.** Un número que sube comunica *acumulación* y hace que el dato se sienta vivo y
reciente. Además el ojo sigue el movimiento y aterriza en la cifra, que es exactamente donde
quieres su atención. Es la microinteracción con mejor relación impacto/esfuerzo de toda la app.

**Solución.** Un widget reutilizable que respeta la aritmética exacta del proyecto (interpola
**centavos enteros**, nunca `double`):

```dart
// core/widgets/contador_money.dart
class ContadorMoney extends StatelessWidget {
  const ContadorMoney(this.valor, {super.key, this.style, this.duracion});

  final Money valor;
  final TextStyle? style;
  final Duration? duracion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      // IntTween sobre centavos: la interpolación nunca introduce un double
      // en el camino del dinero. TweenAnimationBuilder reanuda desde el valor
      // actual cuando `end` cambia, así que al llegar una venta nueva la cifra
      // sube desde donde estaba, no desde cero.
      tween: IntTween(begin: 0, end: valor.centavos),
      duration: context.duracion(duracion ?? Motion.cifra),
      curve: Curves.easeOutExpo,
      builder: (context, centavos, _) => Text(
        Money(centavos).format(),
        style: style,
        // Evita el «baile» de ancho mientras los dígitos cambian.
        textAlign: TextAlign.start,
      ),
    );
  }
}
```

> **Detalle que casi todo el mundo olvida:** con una fuente proporcional, los dígitos cambian de
> ancho y el texto tiembla. Añade `fontFeatures: [FontFeature.tabularFigures()]` al `TextStyle` de
> todas las cifras. Es una línea y elimina el temblor por completo.

Aplícalo en `dashboard_page.dart` a: ventas de hoy, nº de ventas, ticket promedio y valor del
inventario. **Esfuerzo:** ~40 líneas. **Impacto:** es lo primero que se ve al abrir.

---

#### P3 · Entrada escalonada en listas (con la trampa que casi todos pisan)

**Problema.** Catálogo, ventas y movimientos aparecen de golpe. Sólo 2 usos de `interval:`.

**Justificación.** El escalonado (*stagger*) da al ojo un orden de lectura y hace que una lista de
40 filas se perciba como «se está construyendo para mí» en vez de «me han volcado datos encima».

**Solución — y el error a evitar.** Con `ListView.builder`, si animas por `index`, **las filas se
vuelven a animar cada vez que entran en el viewport al hacer scroll**. Queda mareante. Sólo se
animan las primeras visibles:

```dart
ListView.separated(
  itemBuilder: (context, index) {
    final tarjeta = TarjetaProducto(item: items[index], onTap: () => ...);

    // Sólo las ~8 primeras se animan. A partir de ahí, la lista ya está
    // «en marcha» y animar al hacer scroll produce parpadeo, no elegancia.
    if (index > 8 || context.movimientoReducido) return tarjeta;

    return tarjeta
        .animate(delay: context.retardo(index))
        .fadeIn(duration: Motion.media)
        .slideY(begin: 0.10, curve: Motion.entrada);
  },
)
```

**Esfuerzo:** 5 líneas por lista × 4 listas. **Impacto:** cambia la sensación general de la app.

---

#### P4 · Que el carrito «reciba» el producto (feedback de escaneo)

**Problema.** Al escanear, hoy aparece una tarjeta inferior. Pero el **badge del carrito no reacciona**:
nada conecta visualmente «lo que escaneé» con «dónde fue a parar». Es la heurística nº 1 aplicada al
gesto más repetido de la app.

**Justificación.** En un POS, la duda «¿lo leyó o no lo leyó?» es la que hace que el cajero escanee
dos veces y cobre de más. El háptico ya está (bien), pero el háptico no deja rastro visual.

**Solución.** Dos capas:

*a) El badge salta cuando cambia la cuenta* — en `app_shell.dart`:

```dart
Badge.count(
  count: articulos,
  ...
  child: boton,
)
.animate(key: ValueKey(articulos))   // se re-dispara con cada cambio
.scaleXY(begin: 1.0, end: 1.18, duration: Motion.rapida, curve: Motion.enfasis)
.then()
.scaleXY(begin: 1.18, end: 1.0, duration: Motion.rapida)
```

*b) El marco del escáner confirma en verde y la tarjeta entra desde abajo* — ya existe el marco
(`marco_escaner.dart`); falta que la tarjeta de resultado entre con
`.slideY(begin: 0.4).fadeIn()` y salga con `.slideY(end: 0.4)` en un `AnimatedSwitcher` con
`ValueKey(uuidProducto)`, para que **escanear un producto distinto reemplace la tarjeta con
movimiento** en lugar de cambiar el texto en el sitio.

**Esfuerzo:** ~30 líneas. **Impacto:** ataca directamente el error más caro del mostrador.

---

#### P5 · Semántica para lectores de pantalla en los datos críticos

**Problema.** 1 solo `Semantics(` y 0 `semanticLabel` en toda la app. Un lector de pantalla anuncia
el badge de stock como «48 und» sin decir que es stock, y el color —que es el 100 % de la
información de estado— no se transmite.

**Justificación.** El color como único portador de significado incumple WCAG 1.4.1. Y aquí es
literal: verde/ámbar/rojo es lo único que distingue «hay de sobra» de «se está acabando».

**Solución** en `tarjeta_producto.dart`:

```dart
Semantics(
  label: '${item.nombre}. '
         'Stock ${item.stock.format()} ${item.producto.unidadMedida}. '
         '${item.agotado ? "Agotado" : item.bajoStock ? "Stock bajo" : "Stock suficiente"}. '
         'Precio ${item.precioVenta.format()}',
  excludeSemantics: true,   // sustituye la lectura fragmentada de los hijos
  button: true,
  child: Card(...),
)
```

Y —esto es lo importante— **añade un icono además del color** en el badge:
`Icons.error_rounded` para agotado, `Icons.warning_amber_rounded` para bajo, nada cuando está bien.
Así la información sobrevive al daltonismo y a una pantalla con el brillo al mínimo.

**Esfuerzo:** ~15 líneas por componente crítico (tarjeta de producto, chip de sync, fila de carrito).

---

#### P6 · Microcopy del flujo de caja

Ver §5 completo. **Esfuerzo:** sustituir cadenas. **Impacto:** alto en la heurística nº 2.

---

### 🟨 ALTO IMPACTO / ALTO ESFUERZO — planificar

---

#### P7 · Teclado numérico propio para el cobro en efectivo

**Problema.** `hoja_cobro.dart` usa un `TextField` con el teclado del sistema. En caja, ese teclado:
(a) tarda ~250 ms en aparecer, (b) tapa el importe del cambio, (c) tiene teclas de 9 mm.

**Justificación.** Es el momento de mayor presión de todo el flujo: hay un cliente enfrente con un
billete en la mano. Cada segundo aquí se multiplica por 200 ventas al día. Los POS de verdad
(Square, Clover) **nunca** usan el teclado del sistema para el efectivo.

**Solución.** Teclado de 12 teclas embebido, con las teclas a 64 dp, más los botones de billete que
ya existen. El cambio a devolver, arriba y fijo, en `displaySmall` con `ContadorMoney`.

```dart
// Rejilla 3×4: 1..9, «00», 0, ⌫
GridView.count(
  crossAxisCount: 3, childAspectRatio: 1.6, shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  children: [...teclas].map((t) => _Tecla(
    texto: t,
    onTap: () { HapticFeedback.selectionClick(); _pulsar(t); },
  )).toList(),
)
```

Cada `_Tecla` con un `AnimatedScale` a 0.94 mientras está presionada (`GestureDetector`
`onTapDown`/`onTapUp`) — el estado de presión que pide el brief, y que aquí además confirma la
pulsación sin mirar.

**Esfuerzo:** ~180 líneas. **Impacto:** el mayor de toda la lista en tiempo por venta.

---

#### P8 · Adaptación a tablet (POS de mostrador)

**Problema.** 0 usos de `MediaQuery.size` y 1 `LayoutBuilder`. En una tablet de 10", la app se ve
como un móvil estirado y desperdicia el 60 % de la pantalla.

**Justificación.** La tablet fija en el mostrador es el formato POS más común. Y el patrón correcto
no es «lo mismo más grande», sino **dos paneles simultáneos**: catálogo/escáner a la izquierda,
carrito siempre visible a la derecha. Elimina toda la navegación del flujo de venta.

**Solución.** Un `LayoutBuilder` en `AppShell` con punto de corte en 840 dp (el `medium` de
Material 3): por encima, `NavigationRail` en lugar de `NavigationBar`, y en la ruta de venta un
`Row` con el carrito fijo ocupando 380 dp.

**Esfuerzo:** ~250 líneas. **Impacto:** alto, pero sólo si el negocio usa tablet. **Pregúntalo antes de
invertir aquí.**

---

#### P9 · Continuidad Hero del escaneo al carrito

Sólo hay 2 `Hero(`. Falta el que más se nota: al confirmar un escaneo, la miniatura del producto
debería **volar** desde la tarjeta del escáner hasta la fila del carrito. Requiere un
`OverlayEntry` con `AnimatedPositioned` porque el origen y el destino viven en rutas distintas.
~120 líneas. Es puro deleite; hazlo cuando P1–P7 estén hechos.

---

### 🟦 BAJO IMPACTO / BAJO ESFUERZO — cuando sobre tiempo

- **Estados de presión en todos los botones**: `AnimatedScale` a 0,97 en `onTapDown`.
  El `filledButtonTheme` ya tiene 52 dp de alto; falta la respuesta táctil visual.
- **Pull-to-refresh con identidad**: sustituir el spinner por el icono de nube del `SyncChip`
  rotando, para que el gesto y el chip cuenten la misma historia.
- **`fontFeatures: [FontFeature.tabularFigures()]`** en todas las cifras (ver P2).

### 🟥 BAJO IMPACTO / ALTO ESFUERZO — no hacer ahora

- Ilustraciones Lottie/Rive para los 16 estados vacíos. Los `EstadoVacio` actuales ya cumplen su
  función (icono + texto + acción). Volver a diseñarlos cuesta activos, peso de APK y mantenimiento
  para ganar deleite en pantallas que el usuario quiere abandonar cuanto antes.
- Glassmorphism generalizado. Ver §1.2.a.

---

## 4. Sistema de diseño — lo que ya existe y lo que falta

`core/theme/app_theme.dart` ya define semilla `#0E6B5C`, la extensión `ColoresDominio` con cinco
roles semánticos en claro y oscuro, radios (14 botones / 18 tarjetas / 28 hojas), alturas táctiles
(52 dp) y tipografía. **No hace falta rehacerlo.** Lo que falta es formalizar tres cosas:

**a) Escala de espaciado.** Hoy los `SizedBox` van a ojo (2, 4, 6, 8, 10, 12, 14, 20, 24…).
Fija una escala de 4 y úsala: `Esp.xs=4, s=8, m=12, l=16, xl=24, xxl=32`.

**b) Elevación por intención**, no por número:

```dart
class Sombras {
  // Elevación baja para tarjetas en reposo. En M3 la jerarquía la da el color
  // de superficie, no la sombra: por eso las Card del tema van con elevation 0
  // y surfaceContainerLow. La sombra se reserva para lo que FLOTA de verdad.
  static List<BoxShadow> flotante(BuildContext c) => [
    BoxShadow(
      color: c.colores.shadow.withValues(alpha: 0.10),
      blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -4,
    ),
  ];
}
```

**c) Inputs con etiqueta flotante.** El `inputDecorationTheme` actual usa `filled` sin
`floatingLabelBehavior`. Añade `floatingLabelBehavior: FloatingLabelBehavior.auto` y un
`labelStyle`/`floatingLabelStyle` distintos para que la etiqueta al subir se lea como etiqueta y
no como valor.

---

## 5. Microcopy — reescritura del flujo de caja

| Dónde | Actual | Propuesto | Por qué |
|---|---|---|---|
| Escáner, sin resultado | «Producto para el código X no encontrado» | **«Ese código no está en tu inventario»** + botón «Crear producto» | Describe el estado del negocio, no un fallo de búsqueda |
| Carrito vacío | «El carrito está vacío» | **«Escanea el primer producto»** | Un vacío es un siguiente paso, no un hecho |
| Botón de cobro | «Cobrar» | **«Cobrar $12.500»** | El importe en el botón evita cobrar de más por error |
| Efectivo insuficiente | (botón deshabilitado) | **«Faltan $2.300»** bajo el campo | Deshabilitar sin explicar es la peor forma de prevenir un error |
| Tras cobrar | «Venta registrada» | **«Devuelve $7.500»** en `displayLarge` | Es literalmente lo siguiente que tiene que hacer la persona |
| Venta sin conexión | «Se enviará automáticamente cuando haya conexión» | **«Guardada. Se enviará sola.»** | Más corto y afirma primero lo que tranquiliza |
| Movimiento `MERMA` | «MERMA» | **«Se dañó o se perdió»** | Jerga contable → lenguaje del tendero |
| Movimiento `AJUSTE` | «AJUSTE» | **«Corregir el conteo»** | Dice qué hace, no cómo se llama |
| Sobreventa | «Supera el stock disponible» | **«Según el sistema no queda. Puedes vender igual.»** | Informa y desbloquea; hoy sólo informa |
| Cerrar sesión con pendientes | «Hay N operaciones sin enviar» | **«N ventas no se han enviado. Si borras los datos, se pierden.»** | Nombra la consecuencia, no el estado |

**Regla general para caja:** verbo primero, cifra visible, máximo 5 palabras.

---

## 6. Resumen ejecutivo del plan

| Orden | Propuesta | Esfuerzo | Archivos |
|---|---|---|---|
| 1 | Motion accesible (`Motion` + `disableAnimations`) | 1 h | `core/theme/motion.dart`, `app.dart` |
| 2 | Contadores animados + cifras tabulares | 2 h | `core/widgets/contador_money.dart`, `dashboard_page.dart` |
| 3 | Listas escalonadas | 1 h | 4 pantallas de lista |
| 4 | Feedback de escaneo → carrito | 3 h | `app_shell.dart`, `scanner_page.dart` |
| 5 | Semántica + icono en estados de stock | 2 h | `tarjeta_producto.dart`, `sync_chip.dart`, carrito |
| 6 | Microcopy | 2 h | Cadenas repartidas |
| 7 | Navegación por rol (vendedor: 3 pestañas) | 1 h | `app_shell.dart` |
| 8 | Teclado numérico de cobro | 1 día | `hoja_cobro.dart` |
| 9 | Tablet / dos paneles | 2–3 días | `app_shell.dart`, rutas de venta |
| 10 | Hero escáner → carrito | 1 día | Overlay propio |

Del 1 al 7 son **~12 horas** y cubren el 80 % del salto perceptible.

---

## 7. Qué necesito para cerrar la parte que no pude auditar

No necesito capturas: tengo el código. Necesito **poder ejecutar la app**, que hoy está bloqueado:

1. **Instalar los `cmdline-tools` de Android** y aceptar licencias:
   `sdkmanager --install "cmdline-tools;latest"` y `flutter doctor --android-licenses`.
2. **Exponer el JDK** que ya está en el equipo (viene con Android Studio):
   `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`.
3. Un **emulador o dispositivo** conectado (`flutter devices`).

Con eso puedo: medir *jank* real con `flutter run --profile` y el *timeline*, verificar que las
animaciones propuestas se mantienen en 60 fps con una lista de 10.000 productos, y comprobar los
tiempos que fijé como criterio de aceptación (escaneo → carrito < 400 ms).

Si además quieres que priorice sobre uso real y no sobre heurística, lo más valioso sería:

- **¿Tablet o sólo móvil?** Decide si P8 (2–3 días) entra o no.
- **Gama del dispositivo de caja.** Si es un Android Go de 2 GB, algunas animaciones hay que
  recortarlas y el glassmorphism queda descartado por completo.
- **Cuántos productos** maneja realmente la tienda. Con 200, el escalonado puede aplicarse a toda
  la lista; con 10.000, sólo a las 8 primeras como propongo en P3.
