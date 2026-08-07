import 'package:flutter/material.dart';

/// Ícono con fondo redondeado.
class IconChip extends StatelessWidget {
  final double size;
  final double radius;
  final Color bg;
  final IconData icon;
  final Color color;

  const IconChip({
    super.key,
    required this.size,
    required this.radius,
    required this.bg,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: size * .55),
    );
  }
}
