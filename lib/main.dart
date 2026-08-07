// Entrada de la aplicación.

import 'package:flutter/material.dart';
import 'services/vehicle_store.dart';
import 'services/debug_log.dart';
import 'services/theme_store.dart';
import 'services/master_key_store.dart';
import 'theme/wt_theme.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    VehicleStore.init(),
    DebugLog.instance.init(),
    ThemeStore.init(),
    MasterKeyStore.init(),
  ]);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeStore.mode,
      builder: (_, mode, __) {
        final b = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        setWtBrightness(b);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: wtTheme(wt, b),
          // No-const a propósito: recrea el subárbol al cambiar de tema para
          // que los colores globales (`wt`) se repinten al instante.
          // ignore: prefer_const_constructors
          home: HomeShell(),
        );
      },
    );
  }
}
