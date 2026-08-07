import 'package:flutter/material.dart';
import '../theme/wt_theme.dart';

/// Barras de señal BLE (3 niveles).
class SignalBars extends StatelessWidget {
  final int level;
  const SignalBars({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    const heights = [7.0, 11.0, 15.0];
    final onColor =
        level >= 3 ? kTeal : (level == 2 ? kTeal600 : wt.grayLight);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final on = i < level;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
          child: Container(
            width: 4,
            height: heights[i],
            decoration: BoxDecoration(
              color: on ? onColor : wt.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
