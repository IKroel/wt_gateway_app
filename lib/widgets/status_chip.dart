import 'package:flutter/material.dart';
import '../models/device_state.dart';
import '../theme/wt_theme.dart';

/// Chip de estado para la tarjeta del escáner.
/// Fondo = token soft (mode-aware); ícono/texto = color de marca oscurecido.
class StatusChip extends StatelessWidget {
  final AccessoryChip chip;
  const StatusChip({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    final d = _data(chip);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
      decoration: BoxDecoration(
        color: d.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(d.icon, size: 15, color: d.fg),
          const SizedBox(width: 6),
          Text(d.label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: d.fg)),
        ],
      ),
    );
  }

  _ChipData _data(AccessoryChip c) => switch (c) {
        AccessoryChip.unassigned => _ChipData(
            'Sin asignar', wt.orangeSoft, const Color(0xFFC96A20),
            Icons.link_off),
        AccessoryChip.cutActive => _ChipData(
            'Corte activo', wt.redSoft, const Color(0xFFD3352A), Icons.block),
        AccessoryChip.released => _ChipData('Liberado', wt.greenSoft,
            const Color(0xFF3E9247), Icons.check_circle),
        AccessoryChip.unread => _ChipData('Estado sin leer', wt.neutral,
            const Color(0xFF6B7B7C), Icons.help),
      };
}

class _ChipData {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _ChipData(this.label, this.bg, this.fg, this.icon);
}
