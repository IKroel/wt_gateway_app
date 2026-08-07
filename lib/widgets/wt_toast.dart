// Toast custom (reemplaza SnackBar). Píldora petrol abajo, autodismiss 2.6 s.

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';

void showWtToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (ctx) => _Toast(message: message, error: error),
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 2600), () {
    if (entry.mounted) entry.remove();
  });
}

class _Toast extends StatefulWidget {
  final String message;
  final bool error;
  const _Toast({required this.message, required this.error});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 90;
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottom,
      child: FadeTransition(
        opacity: _c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .3), end: Offset.zero)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: widget.error ? kRed : kPetrol,
                borderRadius: BorderRadius.circular(14),
                boxShadow: kShadowBtn,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.error ? Icons.error_outline : Icons.check_circle,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(widget.message,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
