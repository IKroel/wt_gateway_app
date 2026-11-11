// Derivación de clave HMAC-SHA256 y firma de nonce para AUTH.
//
// device_key = HMAC(master, MAC[6])
// token      = HMAC(device_key, nonce)[0:16]

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'master_key_store.dart';

class CryptoService {
  /// Deriva device_key a partir del master y la MAC BLE ("AA:BB:CC:DD:EE:FF").
  static Uint8List deriveDeviceKey(String macStr) {
    if (!MasterKeyStore.isConfigured) {
      throw StateError('master key no configurada (compilar con WT_MASTER_SECRET)');
    }
    final master = Uint8List.fromList(hex.decode(MasterKeyStore.effective));
    final macBytes = Uint8List.fromList(
      macStr.toUpperCase().split(':').map((s) => int.parse(s, radix: 16)).toList(),
    );
    final hmac = Hmac(sha256, master);
    return Uint8List.fromList(hmac.convert(macBytes).bytes);
  }

  /// Firma el nonce del ESP32 con la device_key. Retorna 32 hex (16 bytes).
  static String signNonce(Uint8List deviceKey, String nonceHex) {
    final nonce = Uint8List.fromList(hex.decode(nonceHex));
    final hmac = Hmac(sha256, deviceKey);
    return hex.encode(hmac.convert(nonce).bytes.sublist(0, 16));
  }
}
