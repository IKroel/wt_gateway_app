// Barra inferior custom (reemplaza NavigationBar de Material).
// Alto 66, borde superior hairline, píldora tealSoft detrás del ícono activo.

import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';

class WtNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const WtNavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class WtNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<WtNavItem> items;

  const WtNavBar(
      {super.key,
      required this.index,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: wt.surface,
        border: Border(top: BorderSide(color: wt.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(child: _item(i, items[i])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, WtNavItem it) {
    final active = i == index;
    return InkWell(
      onTap: () => onTap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: active ? wt.tealSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(active ? it.activeIcon : it.icon,
                color: active ? kTeal : wt.grayLight, size: 24),
          ),
          const SizedBox(height: 4),
          Text(it.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? kPetrol : wt.grayLight)),
        ],
      ),
    );
  }
}
