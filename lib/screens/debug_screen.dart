// Visor del log de depuración con búsqueda y exportación.

import 'package:flutter/material.dart';
import '../services/debug_log.dart';
import '../theme/wt_theme.dart';
import '../widgets/wt_dialog.dart';
import '../widgets/wt_toast.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});
  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    DebugLog.instance.addListener(_onChange);
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DebugLog.instance.removeListener(_onChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await DebugLog.instance.export();
    } catch (e) {
      if (mounted) {
        showWtToast(context, 'No se pudo exportar: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showWtConfirm(
      context,
      icon: Icons.delete_outline,
      title: 'Vaciar log',
      message: '¿Borrar todo el registro de depuración?',
      confirmLabel: 'Vaciar',
      accent: kRed,
    );
    if (ok) DebugLog.instance.clear();
  }

  Color _lineColor(String line) {
    if (line.contains('ERROR') || line.contains('FAIL')) {
      return Colors.red[300]!;
    }
    if (line.contains('AUDIT')) return Colors.amber[300]!;
    if (line.contains('→')) return Colors.blue[300]!;
    if (line.contains('←')) return Colors.green[300]!;
    return Colors.grey[400]!;
  }

  @override
  Widget build(BuildContext context) {
    final all = DebugLog.instance.lines;
    final lines = _query.isEmpty
        ? all
        : all.where((l) => l.toLowerCase().contains(_query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log de depuración'),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
            tooltip: 'Exportar',
            onPressed: (_exporting || all.isEmpty) ? null : _export,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Vaciar',
            onPressed: all.isEmpty ? null : _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Filtrar…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: Text('Sin registros todavía',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: lines.length,
                    itemBuilder: (_, i) {
                      final line = lines[lines.length - 1 - i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: SelectableText(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: _lineColor(line),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
