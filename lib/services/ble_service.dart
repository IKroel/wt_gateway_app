// Gestión BLE con el ESP32 (V2).
// Corte autónomo en el ESP (ignición + geocerca).
// La app autentica al conectar y solo puede deshabilitar el corte.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_state.dart';
import 'crypto_service.dart';
import 'debug_log.dart';
import 'master_key_store.dart';

/// Fase observable de la conexión (para la pantalla de 3 pasos).
enum ConnPhase { idle, connecting, authenticating, reading, ready, error }

/// Resultado tipado de provisión.
class ProvisionResult {
  final bool ok;
  final String? error;
  const ProvisionResult({required this.ok, this.error});
}

class BleService extends ChangeNotifier {
  DeviceState _state = DeviceState.initial();
  DeviceState get state => _state;

  final List<String> log = [];

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  BluetoothCharacteristic? _txChar;
  StreamSubscription? _notifySub;
  StreamSubscription? _connSub;
  String? _deviceMac;
  Uint8List? _deviceKey;
  bool _authed = false;

  bool _disposed = false;
  bool _userDisconnect = false;
  Timer? _authTimer;
  int _authAttempts = 0;
  bool _authInProgress = false;
  bool _authFailed = false;
  int _reconnectAttempts = 0;

  static const int _maxAuthAttempts = 3;
  static const int _maxReconnectAttempts = 3;

  String? _firmwareVersion;
  bool _versionAsked = false;

  /// Fase de conexión observable.
  ConnPhase _phase = ConnPhase.idle;
  String? _phaseError;
  ConnPhase _errorAtPhase = ConnPhase.idle;

  /// Completers para operaciones que esperan respuesta del ESP.
  Completer<ProvisionResult>? _provisionCompleter;
  Completer<bool>? _disableCutCompleter;

  String? get deviceMac => _deviceMac;
  bool get authed => _authed;
  bool get authInProgress => _authInProgress;
  bool get authFailed => _authFailed;
  String? get firmwareVersion => _firmwareVersion;
  ConnPhase get phase => _phase;
  String? get phaseError => _phaseError;

  /// Etapa (connecting/authenticating/reading) que estaba activa al fallar.
  ConnPhase get errorPhase => _errorAtPhase;

  // ── Conexión ────────────────────────────────────────────

  /// Conecta, autentica y lee estado. La fase se actualiza en cada tramo.
  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    _deviceMac = device.remoteId.str;
    _authed = false;
    _userDisconnect = false;
    _authFailed = false;
    _setPhase(ConnPhase.connecting);
    _setState(_state.copyWith(connected: false));

    _connSub?.cancel();
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) _onDisconnected();
    });

    // Paso 1: conectar GATT
    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      _addLog('ERROR conexión: $e');
      _setPhase(ConnPhase.error, error: 'Error de conexión: $e');
      rethrow;
    }
    try {
      await device.requestMtu(247);
    } catch (_) {}

    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } catch (e) {
      _addLog('ERROR discoverServices: $e');
      _setPhase(ConnPhase.error, error: 'No se encontraron servicios');
      try {
        await device.disconnect();
      } catch (_) {}
      rethrow;
    }

    for (final svc in services) {
      if (svc.uuid.toString().toUpperCase().contains('6E400001')) {
        for (final chr in svc.characteristics) {
          final u = chr.uuid.toString().toUpperCase();
          if (u.contains('6E400002')) _rxChar = chr;
          if (u.contains('6E400003')) _txChar = chr;
        }
      }
    }
    if (_rxChar == null || _txChar == null) {
      _addLog('ERROR: NUS no encontrado');
      _setPhase(ConnPhase.error, error: 'Servicio NUS no encontrado');
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }

    try {
      await _txChar!.setNotifyValue(true);
      _notifySub?.cancel();
      _notifySub = _txChar!.onValueReceived.listen(_onNotification);
    } catch (e) {
      _addLog('ERROR notify: $e');
      _setPhase(ConnPhase.error, error: 'Error al suscribir notificaciones');
      try {
        await device.disconnect();
      } catch (_) {}
      return;
    }

    _reconnectAttempts = 0;
    _setState(_state.copyWith(connected: true));
    _addLog('Conectado a ${device.advName}');

    // Paso 2: autenticar
    _setPhase(ConnPhase.authenticating);
    _firmwareVersion = null;
    _versionAsked = true;
    await sendCommand('>VERSION');
    await _authenticate();

    // Paso 3: leer estado
    if (_phase != ConnPhase.error) {
      _setPhase(ConnPhase.reading);
      await sendCommand('>STATUS');
    }
  }

  Future<void> disconnect() async {
    _userDisconnect = true;
    _authTimer?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _onDisconnected();
  }

  /// Reintento manual de autenticación.
  Future<void> retryAuth() async {
    if (!(_state.connected) || _disposed) return;
    _authAttempts = 0;
    _authFailed = false;
    _setPhase(ConnPhase.authenticating);
    await _authenticate();
  }

  /// Reintento completo de conexión.
  Future<void> retryConnect() async {
    if (_device == null || _disposed) return;
    _reconnectAttempts = 0;
    await connect(_device!);
  }

  void _onDisconnected() {
    if (_disposed) return;
    _authed = false;
    _authInProgress = false;
    _authTimer?.cancel();
    _notifySub?.cancel();
    _rxChar = null;
    _txChar = null;
    _setState(_state.copyWith(connected: false));
    _setPhase(ConnPhase.idle);
    _addLog('Desconectado');

    if (!_userDisconnect &&
        _device != null &&
        _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _addLog(
          'Reintentando conexión ($_reconnectAttempts/$_maxReconnectAttempts)…');
      Future.delayed(const Duration(seconds: 2), () async {
        if (_disposed || _userDisconnect) return;
        try {
          await connect(_device!);
        } catch (_) {}
      });
    }
  }

  // ── Comandos ────────────────────────────────────────────

  Future<void> sendCommand(String cmd, {bool silent = false}) async {
    if (_rxChar == null || _disposed) return;
    try {
      final data = utf8.encode(cmd.endsWith('\n') ? cmd : '$cmd\n');
      await _rxChar!.write(data, withoutResponse: false);
      if (!silent) _addLog('→ $cmd');
    } catch (e) {
      _addLog('ERROR write "$cmd": $e');
    }
  }

  Future<void> _authenticate() async {
    if (_deviceMac == null || _disposed) return;
    _authAttempts++;
    _authInProgress = true;
    _authFailed = false;
    try {
      _deviceKey ??= CryptoService.deriveDeviceKey(_deviceMac!);
    } catch (e) {
      _addLog('ERROR derivación key: $e');
      _authInProgress = false;
      _authFailed = true;
      _setPhase(ConnPhase.error, error: 'Error de derivación de clave');
      notifyListeners();
      return;
    }
    notifyListeners();
    await sendCommand('>CHALLENGE');
    _authTimer?.cancel();
    _authTimer = Timer(const Duration(seconds: 5), _onAuthTimeout);
  }

  void _onAuthTimeout() {
    if (_disposed || _authed || !_state.connected) return;
    if (_authAttempts < _maxAuthAttempts) {
      _addLog(
          'Auth sin respuesta, reintentando ($_authAttempts/$_maxAuthAttempts)…');
      _authenticate();
    } else {
      _authInProgress = false;
      _authFailed = true;
      _addLog('Autenticación fallida (timeout)');
      _setPhase(ConnPhase.error, error: 'Autenticación sin respuesta');
      notifyListeners();
    }
  }

  Future<void> _handleChallenge(String nonceHex) async {
    if (_deviceKey == null) return;
    try {
      final token = CryptoService.signNonce(_deviceKey!, nonceHex);
      await sendCommand('>AUTH $token');
    } catch (e) {
      _addLog('ERROR firma nonce: $e');
    }
  }

  /// Deshabilita el corte. Retorna true cuando el ESP confirma con <CUT_DISABLED.
  Future<bool> disableCut() async {
    DebugLog.instance.audit('DISABLECUT', mac: _deviceMac);
    _disableCutCompleter = Completer<bool>();
    await sendCommand('>DISABLECUT');
    final timer = Timer(const Duration(seconds: 5), () {
      if (!(_disableCutCompleter?.isCompleted ?? true)) {
        _disableCutCompleter?.complete(false);
      }
    });
    final ok = await _disableCutCompleter!.future;
    timer.cancel();
    _disableCutCompleter = null;
    if (ok) await sendCommand('>STATUS');
    return ok;
  }


  Future<void> setName(String name) async => sendCommand('>NAME $name');

  Future<void> reboot() async {
    DebugLog.instance.audit('REBOOT', mac: _deviceMac);
    await sendCommand('>REBOOT');
  }

  Future<void> unprovision({String? renameTo}) async {
    DebugLog.instance.audit('UNPROVISION', mac: _deviceMac);
    await sendCommand('>UNPROVISION');
    // Renombrar la placa al genérico para que el advertising vuelva a WT-xxxx.
    if (renameTo != null && renameTo.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      await sendCommand('>NAME $renameTo');
    }
  }

  /// Provisiona el equipo. Retorna resultado tipado al recibir <PROVISION_OK o error/timeout.
  Future<ProvisionResult> provision(String newName) async {
    _provisionCompleter = Completer<ProvisionResult>();
    await sendCommand('>MAC');
    await Future.delayed(const Duration(milliseconds: 300));
    if (newName.isNotEmpty) {
      await sendCommand('>NAME $newName');
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await sendCommand('>PROVISION ${MasterKeyStore.effective}');

    final timer = Timer(const Duration(seconds: 8), () {
      if (!(_provisionCompleter?.isCompleted ?? true)) {
        _provisionCompleter?.complete(const ProvisionResult(
            ok: false, error: 'Sin respuesta del equipo'));
      }
    });
    final result = await _provisionCompleter!.future;
    timer.cancel();
    _provisionCompleter = null;
    return result;
  }

  // ── Parser de notificaciones ─────────────────────────────

  void _onNotification(List<int> data) {
    final msg = utf8.decode(data).trim();
    if (msg.isEmpty) return;

    _addLog('← $msg');

    if (msg.startsWith('<STATUS')) {
      final cut = _extract(msg, 'cut=');
      _setState(_state.copyWith(
        name: _extract(msg, 'name=') ?? _state.name,
        ignOn: _parseBool(_extract(msg, 'ign=')),
        inGeo: _parseBool(_extract(msg, 'geo=')),
        relay: cut == null
            ? null
            : (cut == '1' ? RelayState.cutActive : RelayState.free),
        cutDisabled: _parseBool(_extract(msg, 'override=')),
      ));
      if (_phase == ConnPhase.reading) _setPhase(ConnPhase.ready);
      return;
    }

    if (msg.startsWith('<VERSION')) {
      _firmwareVersion = msg.replaceFirst('<VERSION', '').trim();
      _versionAsked = false;
      final prov = _extract(msg, 'prov=');
      if (prov != null) {
        _setState(
            _state.copyWith(provisioned: prov == '1', clearError: true));
      } else {
        notifyListeners();
      }
      return;
    }

    if (msg == '<AUTH_OK') {
      _authed = true;
      _authInProgress = false;
      _authFailed = false;
      _authAttempts = 0;
      _authTimer?.cancel();
      if (_phase == ConnPhase.authenticating) _setPhase(ConnPhase.reading);
      notifyListeners();
      sendCommand('>STATUS');
      return;
    }

    if (msg.startsWith('<CHALLENGE ')) {
      _handleChallenge(msg.replaceFirst('<CHALLENGE ', '').trim());
      return;
    }

    if (msg.startsWith('<AUTH_FAIL')) {
      final reason = msg.replaceFirst('<AUTH_FAIL', '').trim();
      _authTimer?.cancel();
      _authInProgress = false;
      _authFailed = reason != 'no_key';
      _setState(_state.copyWith(provisioned: reason != 'no_key'));
      if (reason == 'no_key') {
        // Sin provisionar → no es error de auth, continuar al wizard
        if (_phase == ConnPhase.authenticating) _setPhase(ConnPhase.ready);
      } else {
        _setPhase(ConnPhase.error, error: 'Autenticación rechazada');
      }
      return;
    }

    if (msg == '<CUT_DISABLED') {
      _setState(_state.copyWith(cutDisabled: true, clearError: true));
      if (!(_disableCutCompleter?.isCompleted ?? true)) {
        _disableCutCompleter?.complete(true);
      }
      return;
    }

    if (msg == '<CUT_ARMED') {
      _setState(_state.copyWith(cutDisabled: false));
      return;
    }

    if (msg.startsWith('<PROVISION_OK')) {
      _setState(_state.copyWith(provisioned: true, clearError: true));
      if (!(_provisionCompleter?.isCompleted ?? true)) {
        _provisionCompleter
            ?.complete(const ProvisionResult(ok: true));
      }
      _authenticate();
      return;
    }

    if (msg.startsWith('<UNPROVISION_OK')) {
      _authed = false;
      _deviceKey = null;
      _setState(_state.copyWith(provisioned: false, clearError: true));
      return;
    }

    if (msg.startsWith('<ERR unknown_cmd') && _versionAsked) {
      _firmwareVersion = 'antiguo (sin >VERSION)';
      _versionAsked = false;
      notifyListeners();
      return;
    }

    if (msg.startsWith('<ERR no_key_set')) {
      _authTimer?.cancel();
      _authInProgress = false;
      _setState(_state.copyWith(provisioned: false, clearError: true));
      if (_phase == ConnPhase.authenticating) _setPhase(ConnPhase.ready);
      return;
    }

    if (msg.startsWith('<ERR')) {
      _setState(_state.copyWith(lastError: msg));
      if (!(_provisionCompleter?.isCompleted ?? true)) {
        _provisionCompleter?.complete(
            ProvisionResult(ok: false, error: msg));
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  String? _extract(String msg, String key) {
    final idx = msg.indexOf(key);
    if (idx < 0) return null;
    final start = idx + key.length;
    final end = msg.indexOf(' ', start);
    return end < 0 ? msg.substring(start) : msg.substring(start, end);
  }

  bool? _parseBool(String? s) => s == null ? null : (s == '1');

  void _setState(DeviceState next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }

  void _setPhase(ConnPhase p, {String? error}) {
    if (p == ConnPhase.error && _phase != ConnPhase.error) {
      _errorAtPhase = _phase; // recuerda la etapa que fallaba
    }
    _phase = p;
    _phaseError = error;
    if (!_disposed) notifyListeners();
  }

  void _addLog(String msg) {
    final mac = _deviceMac ?? '?';
    log.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
    if (log.length > 200) log.removeAt(0);
    DebugLog.instance.add('[$mac] $msg');
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _userDisconnect = true;
    _authTimer?.cancel();
    _notifySub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
