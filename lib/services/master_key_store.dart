// Master key efectiva con soporte de override local (modo pruebas).

import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class MasterKeyStore {
  static SharedPreferences? _p;
  static String? _override;

  static Future<void> init() async {
    _p ??= await SharedPreferences.getInstance();
    final v = _p!.getString('master_override');
    _override = (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  /// Master en uso: override local si existe, si no la compilada.
  static String get effective => _override ?? kMasterSecret;

  static bool get isOverridden => _override != null;

  static bool isValid(String key) =>
      RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(key.trim());

  static Future<bool> setOverride(String key) async {
    final k = key.trim().toLowerCase();
    if (!isValid(k)) return false;
    _override = k;
    await _p?.setString('master_override', k);
    return true;
  }

  static Future<void> clearOverride() async {
    _override = null;
    await _p?.remove('master_override');
  }
}
