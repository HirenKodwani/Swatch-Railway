import 'package:flutter/material.dart';
import '../../../../model/area_cleaning_models.dart';
import '../../../../utills/app_colors.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final CleaningTask task;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.onStart,
    this.onComplete,
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
                  child: const Icon(Icons.task, color: kRailwayBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.activityType ?? 'Task',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${task.areaName} | ${task.scheduledDate}',
                        style: const TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge(task.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(Icons.person, task.workerName ?? 'Unassigned'),
                const SizedBox(width: 8),
                _infoChip(Icons.access_time, task.shift),
                const SizedBox(width: 8),
                PriorityBadge(task.priority),
              ],
            ),
            if (task.beforePhoto != null || task.afterPhoto != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (task.beforePhoto != null)
                    Expanded(
                      child: _photoPreview(task.beforePhoto!, 'Before'),
                    ),
                  if (task.beforePhoto != null && task.afterPhoto != null)
                    const SizedBox(width: 6),
                  if (task.afterPhoto != null)
                    Expanded(
                      child: _photoPreview(task.afterPhoto!, 'After'),
                    ),
                ],
              ),
            ],
            if (task.remarks != null && task.remarks!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.remarks!,
                style: const TextStyle(fontSize: 11, color: kTextSecondary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onApprove != null || onReject != null || onStart != null || onComplete != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _actionButton('Reject', kErrorRed, Icons.close, onReject!),
                    ),
                  if (onStart != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _actionButton('Start', kRailwayBlue, Icons.play_arrow, onStart!),
                    ),
                  if (onComplete != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _actionButton('Complete', kSuccessGreen, Icons.check, onComplete!),
                    ),
                  if (onApprove != null)
                    _actionButton('Approve', kSuccessGreen, Icons.verified, onApprove!),
                ],
              ),
            ],
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

  Widget _photoPreview(String url, String label) {
    return Column(
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: kTextSecondary)),
      ],
    );
  }

  Widget _actionButton(String label, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
