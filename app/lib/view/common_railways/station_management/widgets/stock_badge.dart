import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';

class StockBadge extends StatelessWidget {
  final int quantity;
  final int? lowStockThreshold;

  const StockBadge(
    this.quantity, {
    super.key,
    this.lowStockThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final level = _stockLevel();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level['color']!.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level['label']!,
        style: TextStyle(
          color: level['color'],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _stockLevel() {
    final threshold = lowStockThreshold ?? 10;
    if (quantity <= 0) {
      return {'label': 'Out of Stock', 'color': kErrorRed};
    } else if (quantity <= threshold) {
      return {'label': 'Low Stock', 'color': kWarningOrange};
    }
    return {'label': 'In Stock', 'color': kSuccessGreen};
  }
}
