// Listado de equipos BLE detectados.
// Filtra por manufacturer data WT, agrupa por cercanía y muestra
// un chip de estado único por tarjeta.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';
import '../models/device_state.dart';
import '../models/vehicle_type.dart';
import '../services/ble_service.dart';
import '../services/vehicle_store.dart';
import '../theme/wt_theme.dart';
import '../widgets/signal_bars.dart';
import '../widgets/status_chip.dart';
import '../widgets/icon_chip.dart';
import '../widgets/motion.dart';
import '../widgets/wt_dialog.dart';
import '../widgets/wt_toast.dart';
import 'connection_screen.dart';
import 'device_screen.dart';
import 'edit_vehicle_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final List<ScanResult> _results = [];
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _scanning = false;
  late final TabController _tabs = TabController(length: 2, vsync: this);
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  bool _btOn = true;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _scanning = scanning);
    });
    _adapterSub = FlutterBluePlus.adapterState.listen((st) {
      final on = st == BluetoothAdapterState.on;
      if (!mounted) return;
      final wasOn = _btOn;
      setState(() => _btOn = on);
      if (!on) {
        _showBtOffDialog();
      } else if (!wasOn && on) {
        _startScan();
      }
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied =
        statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    if (denied) {
      if (mounted) {
        showWtToast(
            context, 'Se requieren permisos de Bluetooth y ubicación',
            error: true);
      }
      return;
    }
    try {
      final st = await FlutterBluePlus.adapterState.first;
      if (st != BluetoothAdapterState.on) {
        _btOn = false;
        if (mounted) {
          setState(() {});
          _showBtOffDialog();
        }
        return;
      }
    } catch (_) {}
    _startScan();
  }

  bool _btDialogOpen = false;
  Future<void> _showBtOffDialog() async {
    if (_btDialogOpen || !mounted) return;
    _btDialogOpen = true;
    final ok = await showWtConfirm(
      context,
      icon: Icons.bluetooth_disabled,
      title: 'Bluetooth apagado',
      message: 'Activa el Bluetooth para buscar y conectarte a los equipos.',
      confirmLabel: 'Activar',
      cancelLabel: 'Entendido',
      accent: kOrange,
    );
    if (ok) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
    }
    _btDialogOpen = false;
  }

  bool _isWtDevice(ScanResult r) {
    final mfg = r.advertisementData.manufacturerData[kWtMfgId];
    return mfg != null &&
        mfg.length >= 3 &&
        mfg[0] == kWtMfgPrefix[0] &&
        mfg[1] == kWtMfgPrefix[1] &&
        mfg[2] == kWtMfgPrefix[2];
  }

  Future<void> _startScan() async {
    setState(() => _results.clear());
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final wt_ = results.where(_isWtDevice).toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      for (final r in wt_) {
        VehicleStore.registerKnown(r.device.remoteId.str);
      }
      if (mounted) {
        setState(() {
          _results
            ..clear()
            ..addAll(wt_);
        });
      }
    });
    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: kScanTimeoutSec));
  }

  Future<void> _connectTo(ScanResult result) async {
    await FlutterBluePlus.stopScan();
    final ble = BleService();
    if (!mounted) return;
    // Conexión como bottom sheet; al llegar a ready abre el detalle (slide-over).
    final ok = await showConnectionSheet(context, device: result.device, ble: ble);
    if (ok == true && mounted) {
      await Navigator.push(
        context,
        slideOverRoute(DeviceScreen(device: result.device, ble: ble)),
      );
    } else {
      // Cancelado: liberar la conexión (el detalle es quien la posee si sigue).
      ble.disconnect();
      ble.dispose();
    }
    if (mounted) setState(() {});
  }

  Future<void> _edit(ScanResult r) async {
    final ok = await showEditVehicleDialog(context,
        mac: r.device.remoteId.str, currentName: _displayName(r));
    if (ok && mounted) {
      await VehicleStore.markAssigned(r.device.remoteId.str);
      setState(() {});
    }
  }

  String _displayName(ScanResult r) =>
      VehicleStore.displayName(r.device.remoteId.str);

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  int _signalLevel(int rssi) {
    if (rssi > -60) return 3;
    if (rssi > -80) return 2;
    return 1;
  }

  bool _isNear(ScanResult r) => r.rssi > -80;

  List<ScanResult> _sortList(List<ScanResult> l) {
    final out = [...l];
    out.sort((a, b) => b.rssi.compareTo(a.rssi)); // por señal (RSSI)
    return out;
  }

  List<ScanResult> get _filtered {
    final wantAssigned = _tabs.index == 1;
    Iterable<ScanResult> r = _results.where(
        (x) => VehicleStore.isAssigned(x.device.remoteId.str) == wantAssigned);
    if (_query.isNotEmpty) {
      final q = _norm(_query);
      r = r.where((x) =>
          _norm(_displayName(x)).contains(q) ||
          _norm(x.device.remoteId.str).contains(q));
    }
    return _sortList(r.toList());
  }

  int get _countUnassigned => _results
      .where((x) => !VehicleStore.isAssigned(x.device.remoteId.str))
      .length;
  int get _countAssigned => _results
      .where((x) => VehicleStore.isAssigned(x.device.remoteId.str))
      .length;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabs.dispose();
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _adapterSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final near = list.where(_isNear).toList();
    final far = list.where((r) => !_isNear(r)).toList();
    final assignedTab = _tabs.index == 1;

    return SafeArea(
      child: Column(
        children: [
          _header(),
          _searchBar(),
          _tabsRow(),
          if (!_btOn) _btBanner(),
          Expanded(
            child: list.isEmpty
                ? _emptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (near.isNotEmpty) ...[
                        _eyebrow('CERCA DE TI', Icons.near_me, kTeal),
                        ...near.map(
                            (r) => _card(r, assignedTab, near: true)),
                      ],
                      if (far.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _eyebrow('MÁS LEJOS', Icons.location_searching,
                            wt.grayLight),
                        ...far.map(
                            (r) => _card(r, assignedTab, near: false)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _btBanner() => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: wt.orangeSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth_disabled, color: kOrange, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Bluetooth apagado. Actívalo para buscar equipos.',
                  style: TextStyle(fontSize: 12.5, color: wt.ink2)),
            ),
            GestureDetector(
              onTap: () async {
                try {
                  await FlutterBluePlus.turnOn();
                } catch (_) {}
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('Activar',
                    style: TextStyle(
                        color: kTeal, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Row(
          children: [
            Text('Equipos',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: wt.ink)),
            const Spacer(),
            Material(
              color: wt.surface,
              shape: CircleBorder(side: BorderSide(color: wt.line)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _scanning ? null : _startScan,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, boxShadow: kShadowXs),
                  child: _scanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPetrol))
                      : const Icon(Icons.refresh, color: kPetrol, size: 22),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          decoration: const BoxDecoration(boxShadow: kShadowXs),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(fontSize: 15, color: wt.ink),
            decoration: InputDecoration(
              hintText: 'Buscar patente o MAC…',
              prefixIcon: Icon(Icons.search, color: wt.gray, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear, color: wt.gray, size: 20),
                      onPressed: () => _searchCtrl.clear(),
                    ),
              isDense: true,
            ),
          ),
        ),
      );

  Widget _tabsRow() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Row(
          children: [
            Expanded(
                child: _tabPill('Sin asignar · $_countUnassigned', 0)),
            const SizedBox(width: 8),
            Expanded(child: _tabPill('Asignados · $_countAssigned', 1)),
          ],
        ),
      );

  Widget _tabPill(String label, int index) {
    final active = _tabs.index == index;
    return GestureDetector(
      onTap: () => _tabs.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? kPetrol : wt.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? kPetrol : wt.line),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : wt.ink2,
            )),
      ),
    );
  }

  Widget _eyebrow(String text, IconData icon, Color color) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: color == kTeal ? wt.ink2 : wt.gray)),
          ],
        ),
      );

  /// Tarjeta de equipo con chip de estado único.
  Widget _card(ScanResult r, bool assignedTab, {required bool near}) {
    final mac = r.device.remoteId.str;
    final type = VehicleStore.iconType(mac);

    if (!near) return _farRow(r, assignedTab, type, mac);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: wt.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: wt.line),
        boxShadow: kShadowXs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _connectTo(r),
        onLongPress: () => _edit(r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconChip(
                  size: 44,
                  radius: 13,
                  bg: assignedTab ? wt.tealSoft : wt.orangeSoft,
                  icon: assignedTab ? type.icon : Icons.memory,
                  color: assignedTab ? kTeal : kOrange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(_displayName(r),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: wt.ink)),
                          ),
                          if (!assignedTab) ...[
                            const SizedBox(width: 8),
                            _newBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assignedTab ? '${type.label} · $mac' : mac,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: wt.gray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SignalBars(level: _signalLevel(r.rssi)),
              ],
            ),
            if (assignedTab) ...[
              const SizedBox(height: 10),
              // Chip de estado único (sin conexión = sin leer)
              StatusChip(
                  chip: VehicleStore.isAssigned(mac)
                      ? AccessoryChip.unread
                      : AccessoryChip.unassigned),
            ],
          ],
        ),
      ),
    );
  }

  Widget _farRow(
      ScanResult r, bool assignedTab, VehicleType type, String mac) {
    return Opacity(
      opacity: .9,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: wt.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wt.line),
          boxShadow: kShadowXs,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _connectTo(r),
          onLongPress: () => _edit(r),
          child: Row(
            children: [
              IconChip(
                size: 40,
                radius: 12,
                bg: assignedTab ? wt.tealSoft : wt.orangeSoft,
                icon: assignedTab ? type.icon : Icons.memory,
                color: assignedTab ? kTeal : kOrange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayName(r),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: wt.ink)),
                    const SizedBox(height: 2),
                    Text(assignedTab ? type.label : mac,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: wt.gray)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Débil',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: wt.grayLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: wt.orangeSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text('NUEVO',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: kOrange)),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                _scanning ? Icons.bluetooth_searching : Icons.search_off,
                size: 56,
                color: wt.grayLight),
            const SizedBox(height: 16),
            Text(
              _scanning
                  ? 'Buscando equipos…'
                  : (_query.isNotEmpty
                      ? 'Sin coincidencias'
                      : (_tabs.index == 1
                          ? 'No hay equipos asignados en rango'
                          : 'No hay equipos sin asignar en rango')),
              textAlign: TextAlign.center,
              style: TextStyle(color: wt.gray, fontSize: 14),
            ),
          ],
        ),
      );
}

