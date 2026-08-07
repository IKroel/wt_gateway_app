// Registro global de depuración BLE. Singleton persistido en SharedPreferences.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class DebugLog extends ChangeNotifier {
  DebugLog._();
  static final DebugLog instance = DebugLog._();

  static const int _maxLines = 500;
  static const String _prefsKey = 'debug_log';

  final List<String> _lines = [];
  SharedPreferences? _p;
  Timer? _saveDebounce;

  List<String> get lines => List.unmodifiable(_lines);

  Future<void> init() async {
    _p ??= await SharedPreferences.getInstance();
    _lines
      ..clear()
      ..addAll(_p?.getStringList(_prefsKey) ?? const []);
  }

  void add(String entry) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    _lines.add('[$ts] $entry');
    if (_lines.length > _maxLines) {
      _lines.removeRange(0, _lines.length - _maxLines);
    }
    _scheduleSave();
    notifyListeners();
  }

  /// Evento de auditoría: acción sobre un equipo.
  void audit(String action, {String? mac}) {
    add('AUDIT $action mac=${mac ?? '?'}');
  }

  void clear() {
    _lines.clear();
    _p?.remove(_prefsKey);
    notifyListeners();
  }

  String asText() => _lines.join('\n');

  /// Exporta el log a .txt y abre diálogo de compartir.
  Future<String> export() async {
    final dir = await getTemporaryDirectory();
    final stamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/debug_$stamp.txt');
    await file.writeAsString(
      'Log de depuración\nGenerado: ${DateTime.now()}\n'
      '${'=' * 40}\n${asText()}\n',
    );
    await Share.shareXFiles([XFile(file.path)], subject: 'Debug log');
    return file.path;
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 1), () {
      _p?.setStringList(_prefsKey, _lines);
    });
  }
}
