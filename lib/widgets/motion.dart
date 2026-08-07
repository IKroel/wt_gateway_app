// Movimiento del sistema (sección 07 del handoff): rutas, velo y microanimaciones.

import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';

const Duration kWtDur = Duration(milliseconds: 280);
const Duration kWtDurFast = Duration(milliseconds: 200);
const Duration kWtDurSlide = Duration(milliseconds: 260);
const Cubic kWtCurve = Cubic(.4, 0, .2, 1);

/// Velo de los modales: rgba(5,40,44,.55).
const Color kWtVeil = Color(0x8C05282C);

/// wtpush — entra deslizando desde abajo (wizard de asignación).
Route<T> slideUpRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: kWtDur,
      reverseTransitionDuration: kWtDur,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: kWtCurve)),
        child: child,
      ),
    );

/// Slide-over horizontal desde la derecha (detalle del equipo).
Route<T> slideOverRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: kWtDurSlide,
      reverseTransitionDuration: kWtDurSlide,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: kWtCurve)),
        child: child,
      ),
    );

/// wtpulse — punto que late (indicador "estado leído en vivo").
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, this.color = kGreen, this.size = 8});
  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: .35, end: 1.0).animate(_c),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}
