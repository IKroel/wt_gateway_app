// Pantalla de ajustes: tema y diagnóstico.

import 'package:flutter/material.dart';
import '../services/theme_store.dart';
import '../services/debug_log.dart';
import '../theme/wt_theme.dart';
import '../widgets/wt_switch.dart';
import 'debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text('Ajustes',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: wt.ink)),
            const SizedBox(height: 20),

            _sectionTitle('PREFERENCIAS'),
            _card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(
                        ThemeStore.isDark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: kTeal),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('Modo oscuro',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: wt.ink)),
                    ),
                    WtSwitch(
                      value: ThemeStore.isDark,
                      onChanged: (v) {
                        ThemeStore.setDark(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('DIAGNÓSTICO'),
            _card(
              child: ListTile(
                leading: const Icon(Icons.bug_report, color: kTeal),
                title: const Text('Log de depuración'),
                subtitle: Text(
                    '${DebugLog.instance.lines.length} registros',
                    style: TextStyle(fontSize: 12, color: wt.gray)),
                trailing: Icon(Icons.chevron_right, color: wt.grayLight),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DebugScreen())),
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text('v1.1.0',
                  style: TextStyle(color: wt.gray, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: wt.gray)),
      );

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: wt.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wt.line),
          boxShadow: kShadowXs,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
