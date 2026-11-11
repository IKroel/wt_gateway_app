// Wizard de asignación (provisión) en 4 pasos:
// 1. Identificar (nombre + tipo + modo de operación)
// 2. Confirmar datos
// 3. Provisionando (progreso real)
// 4. Listo (éxito)

import 'package:flutter/material.dart';
import '../models/board_mode.dart';
import '../models/vehicle_type.dart';
import '../services/ble_service.dart';
import '../services/vehicle_store.dart';
import '../theme/wt_theme.dart';
import '../widgets/circle_button.dart';
import '../widgets/wt_button.dart';
import '../widgets/wt_toast.dart';

class ProvisionScreen extends StatefulWidget {
  final BleService ble;
  const ProvisionScreen({super.key, required this.ble});

  @override
  State<ProvisionScreen> createState() => _ProvisionScreenState();
}

class _ProvisionScreenState extends State<ProvisionScreen> {
  int _step = 0; // 0=identificar, 1=confirmar, 2=provisionando, 3=listo
  final _nameCtrl = TextEditingController();
  VehicleType _type = VehicleType.camioneta;
  String _mode = BoardMode.protect; // modo con que queda la placa
  String? _error;

  // Progreso de provisión (3 sub-pasos visuales)
  int _provStep = 0; // 0=escribir clave, 1=guardar nombre, 2=verificar

  String get _mac => widget.ble.deviceMac ?? '—';

  @override
  void initState() {
    super.initState();
    widget.ble.addListener(_onBleChange);
  }

  void _onBleChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.ble.removeListener(_onBleChange);
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _doProvision() async {
    setState(() {
      _step = 2;
      _provStep = 0;
      _error = null;
    });

    // Sub-paso visual: escribir clave
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _provStep = 1);

    // Sub-paso visual: guardar nombre
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _provStep = 2);

    // Ejecutar provisión real
    final name = _nameCtrl.text.trim();
    final result = await widget.ble.provision(name);

    if (!mounted) return;

    if (result.ok) {
      // Persistir alias y marcar asignado
      final mac = widget.ble.deviceMac;
      if (mac != null && name.isNotEmpty) {
        await VehicleStore.setAlias(mac, name);
        await VehicleStore.setIcon(mac, _type);
        await VehicleStore.markAssigned(mac);
      }
      // Modo de operación: la placa re-autentica tras <PROVISION_OK y >SET_MODE
      // exige sesión, así que se espera el AUTH (máx. 5 s) antes de enviarlo.
      for (var i = 0; i < 25 && !widget.ble.authed; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted) return;
      if (!widget.ble.state.supportsModes) {
        // Firmware sin modos: la placa solo hace Protect.
        if (_mode != BoardMode.protect) {
          showWtToast(context,
              'Asignado en Protect: el firmware de la placa no admite Sharing',
              error: true);
        }
      } else if (!widget.ble.authed) {
        showWtToast(context, 'Asignado, pero no se pudo fijar el modo (sin sesión)',
            error: true);
      } else {
        final err = await widget.ble.setMode(_mode);
        if (err != null && mounted) {
          showWtToast(context, 'Asignado, pero no se pudo fijar el modo ($err)',
              error: true);
        }
      }
      if (!mounted) return;
      setState(() => _step = 3);
    } else {
      setState(() {
        _step = 1; // volver a confirmar
        _error = _friendlyError(result.error ?? 'Error desconocido');
      });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already_provisioned')) {
      return 'El equipo ya está asignado. Desasígnalo antes de re-asignar.';
    }
    if (raw.contains('bad_master')) return 'Formato de clave inválido.';
    if (raw.contains('Sin respuesta')) {
      return 'Sin respuesta del equipo. Verifica la conexión.';
    }
    return 'Error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            // Indicador de paso
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? kTeal : wt.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: _stepContent()),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        child: Row(
          children: [
            if (_step < 2)
              CircleButton.icon(Icons.arrow_back, onTap: () {
                if (_step > 0) {
                  setState(() => _step = 0);
                } else {
                  Navigator.pop(context);
                }
              }),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  _step == 3 ? 'Equipo asignado' : 'Asignar equipo',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: wt.ink)),
            ),
          ],
        ),
      );

  Widget _stepContent() => switch (_step) {
        0 => _stepIdentify(),
        1 => _stepConfirm(),
        2 => _stepProvisioning(),
        3 => _stepDone(),
        _ => const SizedBox(),
      };

  /// Paso 1: identificar equipo (nombre + tipo).
  Widget _stepIdentify() => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(child: _identifyColumn()),
          ),
        ),
      );

  Widget _identifyColumn() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Identifica el vehículo',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: wt.ink)),
            const SizedBox(height: 4),
            Text('MAC: $_mac',
                style: TextStyle(
                    fontSize: 12, fontFamily: 'monospace', color: wt.gray)),
            const SizedBox(height: 20),
            _eyebrow('NOMBRE DEL VEHÍCULO'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 23,
              decoration: const InputDecoration(
                hintText: 'Patente / código / VIN',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            _eyebrow('TIPO DE VEHÍCULO'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final t in VehicleType.values) ...[
                  if (t != VehicleType.values.first) const SizedBox(width: 10),
                  _typeCard(t),
                ],
              ],
            ),
            const SizedBox(height: 20),
            _eyebrow('MODO DE OPERACIÓN'),
            const SizedBox(height: 8),
            for (final o in BoardMode.options)
              InkWell(
                onTap: () => setState(() => _mode = o.$1),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                          _mode == o.$1
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: kTeal,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(o.$2,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: wt.ink))),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            WtButton(
              label: 'Continuar',
              icon: Icons.arrow_forward,
              onTap: _nameCtrl.text.trim().isEmpty
                  ? null
                  : () => setState(() => _step = 1),
            ),
            const SizedBox(height: 24),
          ],
        );

  /// Paso 2: confirmar datos antes de provisionar.
  Widget _stepConfirm() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirma los datos',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: wt.ink)),
            const SizedBox(height: 20),
            _confirmRow('Nombre', _nameCtrl.text.trim()),
            _confirmRow('Tipo', _type.label),
            _confirmRow('Modo', BoardMode.label(_mode)),
            _confirmRow('MAC', _mac),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: wt.redSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kRed, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                fontSize: 13, color: wt.ink2))),
                  ],
                ),
              ),
            ],
            const Spacer(),
            WtButton(
              label: 'Asignar y provisionar',
              icon: Icons.vpn_key,
              onTap: widget.ble.state.connected ? _doProvision : null,
            ),
            const SizedBox(height: 8),
            WtButton.secondary(
              label: 'Volver',
              onTap: () => setState(() => _step = 0),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

  /// Paso 3: progreso de provisión (3 sub-pasos).
  Widget _stepProvisioning() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _provRow('Escribir clave', _provStep > 0),
              const SizedBox(height: 14),
              _provRow('Guardar nombre', _provStep > 1),
              const SizedBox(height: 14),
              _provRow('Verificar', _provStep > 2),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: kTeal),
            ],
          ),
        ),
      );

  /// Paso 4: éxito.
  Widget _stepDone() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: kGreen, size: 64),
              const SizedBox(height: 16),
              Text('Equipo asignado',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: wt.ink)),
              const SizedBox(height: 8),
              Text(_nameCtrl.text.trim(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: wt.ink2)),
              Text(_mac,
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: wt.gray)),
              const SizedBox(height: 32),
              WtButton(
                label: 'Ir al equipo',
                icon: Icons.arrow_forward,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

  Widget _provRow(String label, bool done) => Row(
        children: [
          done
              ? const Icon(Icons.check_circle, color: kGreen, size: 22)
              : SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: wt.grayLight)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: done ? wt.ink : wt.gray,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
        ],
      );

  Widget _confirmRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: wt.gray, fontSize: 14)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: wt.ink)),
          ],
        ),
      );

  Widget _eyebrow(String text) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: wt.gray));

  Widget _typeCard(VehicleType t) {
    final sel = t == _type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? wt.tealSoft : wt.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: sel ? kTeal : wt.line, width: sel ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(t.icon, size: 26, color: sel ? kTeal : wt.gray),
              const SizedBox(height: 6),
              Text(t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                      color: sel ? kTeal : wt.gray)),
            ],
          ),
        ),
      ),
    );
  }
}
