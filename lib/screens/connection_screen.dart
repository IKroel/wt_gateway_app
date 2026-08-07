// Conexión en 3 pasos (Conectar → Autenticar → Leer estado) como bottom sheet.
// Muestra progreso real por etapa y reintento en caso de error.

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../theme/wt_theme.dart';
import '../widgets/motion.dart';
import '../widgets/wt_button.dart';

/// Abre el sheet de conexión. Retorna `true` cuando la conexión llega a
/// `ready` (autenticada y con estado leído); `null`/`false` si se cancela.
Future<bool?> showConnectionSheet(
  BuildContext context, {
  required BluetoothDevice device,
  required BleService ble,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: kWtVeil,
    builder: (_) => ConnectionSheet(device: device, ble: ble),
  );
}

class ConnectionSheet extends StatefulWidget {
  final BluetoothDevice device;
  final BleService ble;
  const ConnectionSheet({super.key, required this.device, required this.ble});

  @override
  State<ConnectionSheet> createState() => _ConnectionSheetState();
}

class _ConnectionSheetState extends State<ConnectionSheet> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    widget.ble.addListener(_onUpdate);
    _startConnection();
  }

  Future<void> _startConnection() async {
    try {
      await widget.ble.connect(widget.device);
    } catch (_) {
      // El error queda en ble.phase / ble.phaseError
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    if (widget.ble.phase == ConnPhase.ready && !_done) {
      _done = true;
      Navigator.pop(context, true); // el escáner abre el detalle
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.ble.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _retry() => widget.ble.retryConnect();

  @override
  Widget build(BuildContext context) {
    final phase = widget.ble.phase;
    final error = widget.ble.phaseError;
    final h = MediaQuery.sizeOf(context).height;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      // Se ajusta al contenido; tope 85% con scroll si el estado de error crece.
      constraints: BoxConstraints(maxHeight: h * 0.85),
      padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: wt.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: kShadowModal,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: wt.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Conectando…',
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: wt.ink)),
          Text(widget.device.remoteId.str,
              style: TextStyle(
                  fontSize: 12, fontFamily: 'monospace', color: wt.gray)),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _stepRow('Conectar', _stepState(phase, ConnPhase.connecting)),
                  const SizedBox(height: 16),
                  _stepRow('Autenticar',
                      _stepState(phase, ConnPhase.authenticating)),
                  const SizedBox(height: 16),
                  _stepRow(
                      'Leer estado', _stepState(phase, ConnPhase.reading)),
                  if (phase == ConnPhase.error && error != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: wt.redSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: kRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(error,
                                style:
                                    TextStyle(fontSize: 13, color: wt.ink2)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WtButton(
                      label: 'Reintentar',
                      icon: Icons.refresh,
                      onTap: _retry,
                    ),
                    const SizedBox(height: 8),
                    WtButton.secondary(
                      label: 'Cancelar',
                      onTap: () {
                        widget.ble.disconnect();
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StepState _stepState(ConnPhase current, ConnPhase step) {
    const order = [
      ConnPhase.connecting,
      ConnPhase.authenticating,
      ConnPhase.reading,
    ];
    if (current == ConnPhase.error) {
      // La etapa que falló la reporta el servicio explícitamente.
      final ci = order.indexOf(widget.ble.errorPhase);
      final si = order.indexOf(step);
      if (si < ci) return _StepState.ok;
      if (si == ci) return _StepState.error;
      return _StepState.pending;
    }
    final full = [...order, ConnPhase.ready];
    final ci = full.indexOf(current);
    final si = full.indexOf(step);
    if (ci > si) return _StepState.ok;
    if (ci == si) return _StepState.inProgress;
    return _StepState.pending;
  }

  Widget _stepRow(String label, _StepState state) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: kWtDurFast,
          child: _stepIcon(state),
        ),
        const SizedBox(width: 14),
        Text(label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: state == _StepState.pending ? wt.grayLight : wt.ink,
            )),
      ],
    );
  }

  Widget _stepIcon(_StepState state) => switch (state) {
        _StepState.pending => Container(
            key: const ValueKey('pending'),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: wt.line, width: 2),
            ),
          ),
        _StepState.inProgress => const SizedBox(
            key: ValueKey('inProgress'),
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: kTeal)),
        _StepState.ok => Container(
            key: const ValueKey('ok'),
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: kGreen),
            child: const Icon(Icons.check, color: Colors.white, size: 18)),
        _StepState.error => Container(
            key: const ValueKey('error'),
            width: 28,
            height: 28,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: kRed),
            child: const Icon(Icons.close, color: Colors.white, size: 18)),
      };
}

enum _StepState { pending, inProgress, ok, error }
