import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';
import 'status_badge.dart';

class MachineCard extends StatelessWidget {
  final Map<String, dynamic> machine;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;

  const MachineCard({
    super.key,
    required this.machine,
    this.onTap,
    this.onEdit,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final name = machine['name'] ?? machine['machineName'] ?? 'Unknown';
    final type = machine['type'] ?? machine['machineType'] ?? '';
    final model = machine['model'] ?? machine['machineModel'] ?? '';
    final status = machine['status'] ?? 'active';
    final hours = machine['hours'] ?? machine['runningHours'] ?? machine['totalHours'];
    final fuel = machine['fuel'] ?? machine['fuelLevel'] ?? machine['fuelPercentage'];

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
                  child: const Icon(Icons.precision_manufacturing, color: kRailwayBlue, size: 18),
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
                      if (type.isNotEmpty && model.isNotEmpty)
                        Text(
                          '$type | $model',
                          style: const TextStyle(fontSize: 11, color: kTextSecondary),
                        )
                      else if (type.isNotEmpty)
                        Text(type, style: const TextStyle(fontSize: 11, color: kTextSecondary))
                      else if (model.isNotEmpty)
                        Text(model, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                    ],
                  ),
                ),
                StatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (hours != null)
                  _statChip(Icons.timer, '${hours}h'),
                if (hours != null && fuel != null) const SizedBox(width: 12),
                if (fuel != null)
                  _statChip(Icons.local_gas_station, '$fuel%'),
              ],
            ),
            if (onEdit != null || onAssign != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _actionButton('Edit', kRailwayBlue, onEdit!),
                    ),
                  if (onAssign != null)
                    _actionButton('Assign', kSuccessGreen, onAssign!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
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
