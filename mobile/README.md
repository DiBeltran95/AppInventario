# mobile — app Flutter

App Android de inventario y punto de venta **offline-first**. La puesta en marcha completa (backend
incluido) está en el [README raíz](../README.md); aquí sólo lo específico de la app.

```bash
flutter pub get
flutter run          # elige el emulador o el dispositivo
flutter analyze      # debe terminar sin avisos
flutter test
```

Tras tocar las tablas de Drift en `lib/core/database/app_database.dart` hay que regenerar el código:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## La regla que explica toda la estructura

**La interfaz nunca hace una petición HTTP para pintarse.** Lee SQLite (Drift) mediante streams; la
red sólo alimenta SQLite. De ahí se derivan las tres cosas que sorprenden al leer el código:

1. **No hay estados «cargando…» por red** en las pantallas de operación. Los `AsyncValue.loading`
   que verás son el primer fotograma de una consulta local, no una espera del servidor.
2. **Nadie llama a `invalidate()`** después de vender. Drift reemite los streams de las tablas que
   cambiaron y el dashboard, el catálogo y los reportes se repintan solos.
3. **Toda mutación escribe dominio + outbox en la misma transacción.** Si la app muere en medio, se
   revierten las dos: nunca queda una venta sin encolar ni un encolado sin venta.

## Mapa del código

```
lib/
├── core/
│   ├── database/    Drift: tablas, DAOs (única puerta a los datos), migraciones
│   ├── network/     Dio, interceptores, refresco de token, almacén seguro
│   ├── sync/        SyncEngine · outbox · cursores keyset · conectividad real
│   ├── money/       Money y Cantidad — enteros, jamás un double para dinero
│   ├── theme/       Material 3, paleta y ColoresDominio (éxito/aviso/peligro)
│   ├── router/      go_router y la guarda de sesión (que resuelve sin red)
│   └── widgets/     AppShell · SyncChip · estados vacíos, skeletons, check animado
└── features/        auth · dashboard · scanner · productos · inventario ·
                     ventas · reportes · ajustes
```

Cada *feature* sigue `domain / data / presentation`. `domain` no depende de Flutter, ni de Dio, ni
de Drift.

## Dónde mirar primero

| Si quieres entender… | Abre |
|---|---|
| Cómo se garantiza que no se duplica una venta | `core/database/daos/outbox_dao.dart` |
| Por qué el stock nunca se «escribe» | `core/database/daos/inventario_dao.dart` |
| Por qué no hay ni un `double` en los importes | `core/money/money.dart` |
| El flujo escanear → carrito sin cerrar la cámara | `features/scanner/presentation/scanner_page.dart` |
| El widget más importante de la app | `core/widgets/sync_chip.dart` |
