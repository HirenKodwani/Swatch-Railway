import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';
import 'status_badge.dart';

class WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final List<Map<String, dynamic>>? assignments;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onRemove;

  const WorkerCard({
    super.key,
    required this.worker,
    this.assignments,
    this.onTap,
    this.onAssign,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = worker['fullName'] ?? worker['name'] ?? 'Unknown';
    final role = worker['role'] ?? '';
    final designation = worker['designation'] ?? '';
    final contact = worker['contact'] ?? worker['phone'] ?? worker['mobile'] ?? '';
    final status = worker['status'] ?? 'active';
    final initial = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?';

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
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kRailwayBlue.withOpacity(0.1),
              child: Text(
                initial,
                style: const TextStyle(color: kRailwayBlue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      StatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (designation.isNotEmpty || role.isNotEmpty)
                    Text(
                      designation.isNotEmpty ? designation : role,
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  if (contact.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 12, color: kTextSecondary),
                        const SizedBox(width: 4),
                        Text(contact, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                      ],
                    ),
                  if (assignments != null && assignments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${assignments!.length} area(s) assigned',
                        style: const TextStyle(fontSize: 10, color: kRailwayBlue),
                      ),
                    ),
                ],
              ),
            ),
            if (onAssign != null || onRemove != null) ...[
              if (onAssign != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: kSuccessGreen, size: 20),
                  onPressed: onAssign,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: kErrorRed, size: 20),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
