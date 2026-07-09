import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final int priority;
  final double fontSize;

  const PriorityBadge(
    this.priority, {
    super.key,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final info = _priorityInfo(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info['color']!.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 10, color: info['color']),
          const SizedBox(width: 4),
          Text(
            info['label']!,
            style: TextStyle(
              color: info['color'],
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _priorityInfo(int p) {
    if (p >= 4) return {'label': 'Critical', 'color': kErrorRed};
    if (p == 3) return {'label': 'High', 'color': kWarningOrange};
    if (p == 2) return {'label': 'Medium', 'color': kRailwayBlue};
    return {'label': 'Low', 'color': kSuccessGreen};
  }
}
