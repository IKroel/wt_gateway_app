// Botón pill custom (reemplaza FilledButton/Outlined/Text de Material).
// Primario: relleno + sombra petrol. Secundario: borde. Press → scale .98.

import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';

class WtButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool secondary;
  final Color? color; // color primario (por defecto petrol; ej. kGreen)

  const WtButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.secondary = false,
    this.color,
  });

  const WtButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  })  : secondary = true,
        color = null;

  @override
  State<WtButton> createState() => _WtButtonState();
}

class _WtButtonState extends State<WtButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final primary = widget.color ?? kPetrol;

    final Color bg;
    final Color fg;
    final Border? border;
    final List<BoxShadow>? shadow;
    if (widget.secondary) {
      bg = Colors.transparent;
      fg = enabled ? kTeal : wt.grayLight;
      border = Border.all(color: enabled ? wt.lineStrong : wt.line, width: 1.5);
      shadow = null;
    } else {
      bg = enabled ? primary : wt.disabled;
      fg = enabled ? Colors.white : wt.grayLight;
      border = null;
      shadow = enabled ? kShadowBtn : null;
    }

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: widget.secondary ? 48 : 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border,
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 21),
                const SizedBox(width: 9),
              ],
              Text(widget.label,
                  style: TextStyle(
                      color: fg,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
