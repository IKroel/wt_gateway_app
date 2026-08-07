// Contenedor con barra inferior (Equipos / Ajustes).

import 'package:flutter/material.dart';
import '../widgets/motion.dart';
import '../widgets/wt_nav_bar.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Instancias no-const: al cambiar el tema, el subárbol repinta al instante
    // (los colores se leen del global `wt`). El estado de cada tab se preserva.
    // ignore: prefer_const_constructors
    final tabs = <Widget>[ScannerScreen(), SettingsScreen()];
    return Scaffold(
      // Cross-fade entre pestañas (mismo nivel, sin push); ambas vivas.
      body: Stack(
        children: [
          for (int i = 0; i < tabs.length; i++)
            AnimatedOpacity(
              opacity: _index == i ? 1 : 0,
              duration: kWtDurFast,
              child: IgnorePointer(ignoring: _index != i, child: tabs[i]),
            ),
        ],
      ),
      bottomNavigationBar: WtNavBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          WtNavItem(
              icon: Icons.sensors_outlined,
              activeIcon: Icons.sensors,
              label: 'Equipos'),
          WtNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Ajustes'),
        ],
      ),
    );
  }
}
