// Detalle del equipo conectado.
// Muestra estado, permite liberar corte (con confirmación) y gestionar el equipo.

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_state.dart';
import '../models/vehicle_type.dart';
import '../services/ble_service.dart';
import '../services/vehicle_store.dart';
import '../theme/wt_theme.dart';
import '../widgets/circle_button.dart';
import '../widgets/motion.dart';
import '../widgets/wt_button.dart';
import '../widgets/wt_dialog.dart';
import '../widgets/wt_toast.dart';
import 'provision_screen.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BleService ble;
  const DeviceScreen({super.key, required this.device, required this.ble});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  String get _mac => widget.device.remoteId.str;

  @override
  void initState() {
    super.initState();
    widget.ble.addListener(_onStateChange);
  }

  String? _lastShownError;

  void _onStateChange() {
    final s = widget.ble.state;
    if (s.provisioned &&
        s.name.isNotEmpty &&
        s.name != 'Desconocido' &&
        s.name != VehicleStore.genericName(_mac)) {
      VehicleStore.markAssigned(_mac);
      VehicleStore.setAlias(_mac, s.name);
    }
    if (s.lastError != null && s.lastError != _lastShownError && mounted) {
      _lastShownError = s.lastError;
      showWtToast(context, 'Error del equipo: ${s.lastError}', error: true);
    }
    if (s.lastError == null) _lastShownError = null;
    if (mounted) setState(() {});
  }

  String get _title {
    final s = widget.ble.state;
    if (s.connected && s.name.isNotEmpty && s.name != 'Desconocido') {
      return s.name;
    }
    final alias = VehicleStore.alias(_mac);
    if (alias != null && alias.isNotEmpty) return alias;
    return s.name;
  }

  String get _subtitle => '${VehicleStore.iconType(_mac).label} · $_mac';

  /// Modal de confirmación antes de liberar.
  Future<void> _confirmRelease() async {
    final ok = await showWtConfirm(
      context,
      icon: Icons.lock_open,
      title: 'Liberar corte',
      message: 'El vehículo $_title quedará operativo. '
          'Confirma que deseas liberar el corte.',
      confirmLabel: 'Liberar',
      accent: kGreen,
    );
    if (ok) {
      final success = await widget.ble.disableCut();
      if (mounted && !success) {
        showWtToast(context, 'No se pudo confirmar la liberación',
            error: true);
      }
    }
  }

  Future<void> _confirmReboot() async {
    final ok = await showWtConfirm(
      context,
      icon: Icons.restart_alt,
      title: 'Reiniciar equipo',
      message: 'El equipo $_title se reiniciará. La conexión se cortará '
          'unos segundos; el estado del corte se mantiene.',
      confirmLabel: 'Reiniciar',
    );
    if (ok) await widget.ble.reboot();
  }

  Future<void> _confirmReset() async {
    final ok = await showWtConfirm(
      context,
      icon: Icons.link_off,
      title: 'Desasignar equipo',
      message: 'Se borrará la clave del equipo y quedará sin provisionar.',
      confirmLabel: 'Desasignar',
      accent: kRed,
    );
    if (ok) {
      // Al desprovisionar, renombrar la placa al genérico WT-xxxx (por detrás).
      final generic = VehicleStore.genericName(_mac);
      await widget.ble.unprovision(renameTo: generic);
      await VehicleStore.clearAlias(_mac);
      await VehicleStore.unmarkAssigned(_mac);
    }
  }

  @override
  void dispose() {
    widget.ble.removeListener(_onStateChange);
    widget.ble.disconnect();
    widget.ble.dispose();
    super.dispose();
  }

  Widget _appBar(DeviceState s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        child: Row(
          children: [
            CircleButton.icon(Icons.arrow_back,
                onTap: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: wt.ink)),
                  Text(_subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: wt.gray)),
                ],
              ),
            ),
            Icon(
                s.connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: s.connected ? kTeal : wt.grayLight,
                size: 20),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'status' && s.connected) {
                  widget.ble.sendCommand('>STATUS');
                }
                if (v == 'reboot' && s.connected) _confirmReboot();
                if (v == 'reset' && s.connected) _confirmReset();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'status', child: Text('Actualizar estado')),
                const PopupMenuItem(
                    value: 'reboot', child: Text('Reiniciar equipo')),
                const PopupMenuItem(
                    value: 'reset', child: Text('Desasignar equipo')),
              ],
            ),
          ],
        ),
      );

  Widget _statusPanel(DeviceState s) {
    // Estado del corte → colores/ícono del cuadro héroe (hex exactos del mockup).
    final Color boxBg, fg;
    final IconData icon;
    final String label;
    if (s.relay == RelayState.cutActive) {
      boxBg = const Color(0x29F34235); // rgba(243,66,53,.16)
      fg = const Color(0xFFFF8A80);
      icon = Icons.block;
      label = 'Corte activo';
    } else if (s.cutDisabled == true || s.relay == RelayState.free) {
      boxBg = const Color(0x2951B05A); // rgba(81,176,90,.16)
      fg = const Color(0xFF9FE0A6);
      icon = Icons.lock_open;
      label = 'Corte liberado';
    } else {
      boxBg = const Color(0x14FFFFFF); // rgba(255,255,255,.08)
      fg = const Color(0xFFB9C9C9);
      icon = Icons.help;
      label = 'Estado sin leer';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: wt.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: boxBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: fg, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CORTE DE COMBUSTIBLE',
                        style: TextStyle(
                            color: Color(0xFF9DB3B3),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(label,
                        style: TextStyle(
                            color: fg,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.white.withValues(alpha: .10), height: 28),
          _panelRow('Asignación', s.provisioned ? 'Asignado' : 'Desasignado'),
          const SizedBox(height: 12),
          _panelRow(
              'Ignición',
              s.ignOn == null
                  ? '—'
                  : (s.ignOn! ? 'Encendida' : 'Apagada')),
          if (s.connected && widget.ble.authed) ...[
            const SizedBox(height: 14),
            _liveTag(),
          ],
          if (s.lastError != null) ...[
            const SizedBox(height: 14),
            Text(s.lastError!,
                style:
                    const TextStyle(color: Color(0xFFFF8A80), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _liveTag() => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingDot(color: Color(0xFF0AB4B0), size: 7),
          SizedBox(width: 6),
          Text('Estado leído en vivo',
              style: TextStyle(
                  color: Color(0xFF9DB3B3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _panelRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9DB3B3), fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.ble.state;

    // Sin provisionar → ir a wizard
    if (!s.provisioned) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _appBar(s),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.memory, size: 56, color: kOrange),
                      const SizedBox(height: 16),
                      Text('Dispositivo sin configurar',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: wt.ink)),
                      const SizedBox(height: 24),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40),
                        child: WtButton(
                          label: 'Asignar equipo',
                          icon: Icons.settings,
                          onTap: () => Navigator.push(
                            context,
                            slideUpRoute(ProvisionScreen(ble: widget.ble)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canRelease = s.connected &&
        widget.ble.authed &&
        s.relay == RelayState.cutActive;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _appBar(s),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _statusPanel(s),
                    // Aviso contextual
                    if (s.cutDisabled == true)
                      _infoBanner(
                          'El corte está liberado. El vehículo puede operar normalmente.'),
                    if (s.relay == RelayState.cutActive)
                      _infoBanner(
                          'El corte está activo. Libéralo para dejar el vehículo operativo.'),
                    if (!widget.ble.authed &&
                        s.connected &&
                        !widget.ble.authFailed)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Autenticando…',
                            style:
                                TextStyle(color: wt.gray, fontSize: 12)),
                      ),
                    if (widget.ble.authFailed && s.connected)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Column(
                          children: [
                            const Text(
                                'No se pudo autenticar con el equipo',
                                style: TextStyle(
                                    color: kOrange, fontSize: 12)),
                            const SizedBox(height: 8),
                            WtButton.secondary(
                              label: 'Reintentar autenticación',
                              icon: Icons.refresh,
                              onTap: () => widget.ble.retryAuth(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Botón fijo: solo "Liberar corte"
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: WtButton(
            label: 'Liberar corte',
            icon: Icons.lock_open,
            color: kGreen,
            onTap: canRelease ? _confirmRelease : null,
          ),
        ),
      ),
    );
  }

  Widget _infoBanner(String text) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: wt.orangeSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, color: kOrange, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12.5, color: wt.ink2)),
            ),
          ],
        ),
      );
}
