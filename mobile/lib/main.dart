import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/database/app_database.dart';
import 'core/money/money.dart';
import 'core/network/api_client.dart';
import 'core/network/token_store.dart';
import 'core/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Formatos de fecha y número en español de Colombia. Sin esto, `intl` lanza
  // al formatear con un locale que no sea el de por defecto.
  await initializeDateFormatting('es_CO', null);
  Money.locale = 'es_CO';
  Money.simbolo = r'$';
  // El peso colombiano no maneja centavos en la práctica; internamente se
  // siguen guardando con dos decimales exactos.
  Money.decimalesVisibles = 0;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // La base y el almacén seguro se abren ANTES de arrancar la interfaz: son
  // asíncronos y la app no puede pintar nada útil sin ellos.
  final db = AppDatabase();
  final tokens = TokenStore();
  final urlGuardada = await tokens.urlServidor;
  final api = ApiClient(
    tokenStore: tokens,
    urlBase: urlGuardada ?? AppConfig.urlPorDefecto,
  );

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tokenStoreProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWithValue(api),
      ],
      child: const InventarioApp(),
    ),
  );
}
