// Bottom sheet para renombrar/tipificar un equipo conectado.

import 'package:flutter/material.dart';
import '../models/vehicle_type.dart';
import '../services/vehicle_store.dart';
import '../services/ble_service.dart';
import '../theme/wt_theme.dart';
import '../widgets/wt_button.dart';

/// Muestra el diálogo y retorna true si se guardó.
Future<bool> showEditVehicleDialog(
  BuildContext context, {
  required String mac,
  required String currentName,
  BleService? ble,
}) async {
  final result = await showModalBottomSheet<(String, VehicleType)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C05282C),
    builder: (_) => _AssignSheet(mac: mac, currentName: currentName),
  );
  if (result == null) return false;

  final (name, type) = result;
  if (name.isNotEmpty) {
    await VehicleStore.setAlias(mac, name);
    if (ble != null && ble.state.connected) {
      await ble.setName(name);
    }
  }
  await VehicleStore.setIcon(mac, type);
  return true;
}

class _AssignSheet extends StatefulWidget {
  final String mac;
  final String currentName;
  const _AssignSheet({required this.mac, required this.currentName});

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: VehicleStore.alias(widget.mac) ??
        (widget.currentName == VehicleStore.genericName(widget.mac)
            ? ''
            : widget.currentName),
  );
  late VehicleType _selected = VehicleStore.iconType(widget.mac);
  int _format = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generic = VehicleStore.genericName(widget.mac);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
        decoration: BoxDecoration(
          color: wt.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: kShadowModal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asa
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
            // Encabezado
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: wt.orangeSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.memory, color: kOrange, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Editar equipo',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: wt.ink)),
                      const SizedBox(height: 2),
                      Text('$generic · ${widget.mac}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: wt.gray)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _eyebrow('NOMBRE DEL VEHÍCULO'),
            const SizedBox(height: 8),
            // Campo de texto
            Container(
              decoration: BoxDecoration(
                color: wt.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kTeal, width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33008896),
                      blurRadius: 0,
                      spreadRadius: 4),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(_selected.icon, color: kTeal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 23,
                      cursorColor: kTeal,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: wt.ink),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                        hintText: 'Patente / código / VIN',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Chips de formato
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _formatChip(0, Icons.badge, 'Patente'),
                _formatChip(1, Icons.tag, 'Código interno'),
                _formatChip(2, Icons.pin, 'VIN'),
              ],
            ),
            const SizedBox(height: 20),
            _eyebrow('TIPO DE VEHÍCULO'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final t in VehicleType.values) ...[
                  if (t != VehicleType.values.first)
                    const SizedBox(width: 10),
                  _typeCard(t),
                ],
              ],
            ),
            const SizedBox(height: 24),
            WtButton(
              label: 'Guardar',
              icon: Icons.check,
              onTap: _ctrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      context, (_ctrl.text.trim(), _selected)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eyebrow(String text) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: wt.gray));

  Widget _formatChip(int id, IconData icon, String label) {
    final sel = _format == id;
    return GestureDetector(
      onTap: () => setState(() => _format = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? wt.tealSoft : wt.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? kTeal : wt.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: kTeal),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: wt.ink2)),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(VehicleType t) {
    final sel = t == _selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selected = t),
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
