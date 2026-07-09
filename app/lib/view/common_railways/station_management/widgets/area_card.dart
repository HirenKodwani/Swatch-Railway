import 'package:flutter/material.dart';
import '../../../../model/area_cleaning_models.dart';
import '../../../../utills/app_colors.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class AreaCard extends StatelessWidget {
  final AreaConfig area;
  final int? workerCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const AreaCard({
    super.key,
    required this.area,
    this.workerCount,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.map, color: kRailwayBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.areaName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (area.areaCode.isNotEmpty)
                        Text(
                          area.areaCode,
                          style: const TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                    ],
                  ),
                ),
                StatusBadge(area.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(Icons.repeat, area.cleaningFrequency),
                const SizedBox(width: 8),
                _infoChip(Icons.access_time, area.defaultShift),
                const SizedBox(width: 8),
                _infoChip(Icons.people, '${workerCount ?? area.defaultWorkers} workers'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                PriorityBadge(area.priority),
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: kTextSecondary),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (area.qrCode != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.qr_code, size: 16, color: Colors.grey[400]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kRailwayBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kTextSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }
}
