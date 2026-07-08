import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';
import 'stock_badge.dart';

class MaterialCard extends StatelessWidget {
  final Map<String, dynamic> materialData;
  final int? lowStockThreshold;
  final VoidCallback? onTap;
  final VoidCallback? onIssue;
  final VoidCallback? onReorder;

  const MaterialCard({
    super.key,
    required this.materialData,
    this.lowStockThreshold,
    this.onTap,
    this.onIssue,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final name = materialData['name'] ?? materialData['materialName'] ?? 'Unknown';
    final category = materialData['category'] ?? '';
    final unit = materialData['unit'] ?? 'pcs';
    final quantity = materialData['quantity'] ?? materialData['stock'] ?? materialData['availableQuantity'] ?? 0;
    final qty = quantity is int ? quantity : (quantity is num ? quantity.toInt() : int.tryParse(quantity.toString()) ?? 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kRailwayBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: kRailwayBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (category.isNotEmpty)
                        Text(category, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                    ],
                  ),
                ),
                StockBadge(qty, lowStockThreshold: lowStockThreshold),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statRow(Icons.inventory, '$qty $unit'),
                const Spacer(),
                Text(
                  'Min: ${materialData['minStock'] ?? materialData['reorderLevel'] ?? '-'}',
                  style: const TextStyle(fontSize: 11, color: kTextSecondary),
                ),
              ],
            ),
            if (qty > 0 && qty <= (lowStockThreshold ?? 10))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kWarningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: kWarningOrange),
                    SizedBox(width: 4),
                    Text('Low stock, reorder soon', style: TextStyle(fontSize: 10, color: kWarningOrange)),
                  ],
                ),
              ),
            if (qty <= 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kErrorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 14, color: kErrorRed),
                    SizedBox(width: 4),
                    Text('Out of stock', style: TextStyle(fontSize: 10, color: kErrorRed)),
                  ],
                ),
              ),
            if (onIssue != null || onReorder != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReorder != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _actionButton('Reorder', kWarningOrange, onReorder!),
                    ),
                  if (onIssue != null)
                    _actionButton('Issue', kRailwayBlue, onIssue!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kTextSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
