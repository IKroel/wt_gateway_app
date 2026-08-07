// Persistencia local por MAC: alias, tipo de vehículo, estado de asignación.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_type.dart';

class VehicleStore {
  static SharedPreferences? _p;

  static Future<void> init() async {
    _p ??= await SharedPreferences.getInstance();
  }

  static String _aliasKey(String mac) => 'alias_$mac';
  static String _iconKey(String mac) => 'icon_$mac';

  static String? alias(String mac) => _p?.getString(_aliasKey(mac));

  static VehicleType iconType(String mac) {
    final i = _p?.getInt(_iconKey(mac)) ?? 0;
    return VehicleType.values[(i >= 0 && i < VehicleType.values.length) ? i : 0];
  }

  static Future<void> setAlias(String mac, String name) async {
    await _p?.setString(_aliasKey(mac), name);
  }

  static Future<void> clearAlias(String mac) async {
    await _p?.remove(_aliasKey(mac));
  }

  static Future<void> setIcon(String mac, VehicleType t) async {
    await _p?.setInt(_iconKey(mac), t.index);
  }

  // Equipos conocidos (se llena al escanear).
  static List<String> knownMacs() => _p?.getStringList('known_macs') ?? [];

  static Future<void> registerKnown(String mac) async {
    final list = knownMacs();
    if (!list.contains(mac)) {
      list.add(mac);
      await _p?.setStringList('known_macs', list);
    }
  }

  // Asignación = estado de provisión local.
  static List<String> assignedMacs() => _p?.getStringList('assigned_macs') ?? [];

  static bool isAssigned(String mac) => assignedMacs().contains(mac);

  static Future<void> markAssigned(String mac) async {
    final list = assignedMacs();
    if (!list.contains(mac)) {
      list.add(mac);
      await _p?.setStringList('assigned_macs', list);
    }
  }

  static Future<void> unmarkAssigned(String mac) async {
    final list = assignedMacs()..remove(mac);
    await _p?.setStringList('assigned_macs', list);
  }

  /// Nombre genérico del firmware: "WT-" + 2 últimos octetos de MAC.
  static String genericName(String mac) {
    final h = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    final tail = h.length >= 4 ? h.substring(h.length - 4) : h;
    return 'WT-$tail';
  }

  /// Nombre para UI: alias del instalador > genérico WT-xxxx.
  static String displayName(String mac) {
    final a = alias(mac);
    if (a != null && a.isNotEmpty) return a;
    return genericName(mac);
  }

  static int heartbeatSeconds() => _p?.getInt('hb_seconds') ?? 5;
  static Future<void> setHeartbeatSeconds(int s) async =>
      _p?.setInt('hb_seconds', s);

  static String userName() => _p?.getString('user_name') ?? 'Operador';
  static Future<void> setUserName(String n) async =>
      _p?.setString('user_name', n);
}
