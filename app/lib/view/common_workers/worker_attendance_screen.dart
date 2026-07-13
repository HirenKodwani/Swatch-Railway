import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/worker_controller.dart';

class WorkerAttendanceScreen extends StatelessWidget {
  const WorkerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkerController>();

    return Obx(() {
      return Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text(
                'Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              backgroundColor: kRailwayBlue,
              elevation: 0.5,
            ),
            body: RefreshIndicator(
              color: kRailwayBlue,
              onRefresh: () async {
                await controller.refreshAttendanceStatus();
                await controller.refreshData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(controller),
                    const SizedBox(height: 16),
                    _buildProgressCard(controller),
                    const SizedBox(height: 16),
                    _buildAttendanceItem(
                      controller: controller,
                      title: 'Start Attendance',
                      subtitle: 'Capture selfie and GPS location',
                      icon: Icons.login,
                      type: 'start',
                    ),
                    Obx(() {
                      if (controller.startAttendance.value) {
                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildAttendanceItem(
                              controller: controller,
                              title: 'Mid Check-in',
                              subtitle: 'Unlocks after 3 completed tasks',
                              icon: Icons.schedule,
                              type: 'mid',
                            ),
                            const SizedBox(height: 12),
                            _buildAttendanceItem(
                              controller: controller,
                              title: 'End Attendance',
                              subtitle: 'Unlocks after all assigned tasks',
                              icon: Icons.logout,
                              type: 'end',
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(WorkerController controller) {
    final completed = [
      controller.startAttendance.value,
      controller.midCheckin.value,
      controller.endAttendance.value,
    ].where((marked) => marked).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Progress',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: completed / 3,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(kRailwayBlue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed of 3 attendance checkpoints completed',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(WorkerController controller) {
    final completed = controller.completedTasks.value;
    final total = controller.totalAssignedTasks;
    final allTasksCompleted = total > 0 && completed >= total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: kRailwayBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Count: $completed${total > 0 ? ' / $total' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  allTasksCompleted
                      ? 'End attendance is unlocked'
                      : completed >= 3
                      ? 'Mid check-in is unlocked. Complete all assigned tasks for end attendance'
                      : 'Complete 3 tasks to unlock mid check-in',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem({
    required WorkerController controller,
    required String title,
    required String subtitle,
    required IconData icon,
    required String type,
  }) {
    final isCompleted = type == 'start'
        ? controller.startAttendance.value
        : type == 'mid'
        ? controller.midCheckin.value
        : controller.endAttendance.value;
    final canMark = controller.canMarkAttendance(type);
    final isBusy = type == 'start'
        ? controller.isStartLoading.value
        : type == 'mid'
        ? controller.isMidLoading.value
        : controller.isEndLoading.value;
    final effectiveSubtitle = isCompleted || type == 'start'
        ? subtitle
        : controller.attendanceLockReason(type);
    final accentColor = isCompleted
        ? Colors.green.shade700
        : canMark
        ? kRailwayBlue
        : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade300
              : canMark
              ? Colors.grey.shade300
              : Colors.grey.shade400,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : canMark
                  ? Colors.blue.shade50
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  effectiveSubtitle,
                  style: TextStyle(fontSize: 12, color: accentColor),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24)
          else
            ElevatedButton(
              onPressed: canMark && !isBusy
                  ? () => controller.markAttendanceAction(type)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRailwayBlue,
                disabledBackgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBusy) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Wait'),
                  ] else ...[
                    if (!canMark) ...[
                      const Icon(Icons.lock, size: 13),
                      const SizedBox(width: 4),
                    ],
                    Text(canMark ? 'Mark' : 'Locked'),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
