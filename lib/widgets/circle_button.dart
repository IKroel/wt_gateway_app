import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';

/// Botón circular con borde, usado en headers y app bars.
class CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const CircleButton({super.key, required this.child, this.onTap});

  CircleButton.icon(IconData icon, {super.key, this.onTap})
      : child = Icon(icon, color: kPetrol, size: 20);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: wt.surface,
      shape: CircleBorder(side: BorderSide(color: wt.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration:
              const BoxDecoration(shape: BoxShape.circle, boxShadow: kShadowXs),
          child: child,
        ),
      ),
    );
  }
}
