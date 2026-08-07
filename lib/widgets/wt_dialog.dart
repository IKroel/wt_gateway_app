// Diálogo de confirmación custom (reemplaza AlertDialog).
// Tarjeta con ícono squircle 72px animado + acciones pill.

import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';
import 'motion.dart';
import 'wt_button.dart';

/// Muestra un confirmación custom. Retorna true si se confirma.
Future<bool> showWtConfirm(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  Color accent = kPetrol,
}) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'cerrar',
    barrierColor: kWtVeil,
    transitionDuration: kWtDurFast,
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Center(
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: .85, end: 1.0).animate(curved),
            child: _DialogCard(
              icon: icon,
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
              accent: accent,
            ),
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

class _DialogCard extends StatelessWidget {
  final IconData icon;
  final String title, message, confirmLabel, cancelLabel;
  final Color accent;
  const _DialogCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: wt.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: kShadowModal,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: accent, size: 34),
              ),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: wt.ink)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: wt.ink2, height: 1.4)),
              const SizedBox(height: 22),
              WtButton(
                label: confirmLabel,
                color: accent,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              WtButton.secondary(
                label: cancelLabel,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
