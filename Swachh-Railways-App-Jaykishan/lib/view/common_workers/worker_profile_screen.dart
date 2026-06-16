import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/worker_controller.dart';
import '../../model/worker_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../utills/app_colors.dart';
import '../onboarding_screens/login_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkerController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Obx(() => controller.isProfileLoading.value
              ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadWorkerProfile,
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isProfileLoading.value &&
            controller.workerProfile.value == null &&
            controller.currentUser.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadWorkerProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(controller),

                const SizedBox(height: 20),

                if (controller.assignedRuns.isNotEmpty) ...[
                  const Text(
                    'Assigned Train Runs',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  ...controller.assignedRuns
                      .map((run) => _buildRunCard(run))
                      .toList(),
                  const SizedBox(height: 20),
                ],

                const Text(
                  'Work Statistics',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                        controller.tasksCompleted.value.toString(),
                        'Tasks Completed',
                        Icons.task_alt,
                        Colors.blue),
                    _buildStatCard(
                        '${controller.attendancePercentage.value}%',
                        'Attendance',
                        Icons.calendar_today,
                        kSuccessGreen),
                    _buildStatCard(
                        controller.complaintsRaised.value.toString(),
                        'Complaints Raised',
                        Icons.report_problem,
                        kWarningOrange),
                    _buildStatCard(
                        '${controller.averageRating.value}/5',
                        'Average Rating',
                        Icons.star,
                        Colors.amber),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDecor(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'Assignment Details',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile('Zone', controller.assignedZone,
                          Colors.purple.shade50),
                      const SizedBox(height: 8),
                      _buildInfoTile('Division', controller.assignedDivision,
                          Colors.blue.shade50),
                      const SizedBox(height: 8),
                      _buildInfoTile(
                          'Depot',
                          controller.assignedDepot.isEmpty
                              ? 'Not Assigned'
                              : controller.assignedDepot,
                          Colors.green.shade50),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDecor(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                          Icons.person_outline, 'Full Name', controller.workerName),
                      _buildDetailRow(
                          Icons.email, 'Email', controller.workerEmail),
                      _buildDetailRow(
                          Icons.phone, 'Mobile', controller.workerPhone),
                      _buildDetailRow(
                          Icons.assignment_ind,
                          'Designation',
                          controller.designation.isEmpty
                              ? 'Not Specified'
                              : controller.designation),
                      _buildDetailRow(
                          Icons.shield, 'Role', controller.workerRole),
                      _buildDetailRow(
                          Icons.done_all, 'Status', controller.workerStatus),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                _buildActionTile(
                  Icons.logout_outlined,
                  'Logout',
                  Colors.red.shade50,
                  Colors.red,
                      () => _showLogoutDialog(context, controller),
                ),

                const SizedBox(height: 30),

                const Center(
                  child: Text(
                    'Swachh Railways – Worker Portal\n© 2024 Indian Railways. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }


  Widget _buildProfileHeader(WorkerController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecor(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kRailwayBlue, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: kRailwayBlue,
                  radius: 36,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.check_circle,
                      color: kSuccessGreen, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.workerName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (controller.workerRole.isNotEmpty)
                      _statusChip(controller.workerRole, Colors.blue.shade100,
                          Colors.blue),
                    if (controller.workerStatus.isNotEmpty)
                      _statusChip(controller.workerStatus,
                          Colors.green.shade100, kSuccessGreen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRunCard(AssignedRun run) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kRailwayBlue.withOpacity(0.25), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.train, color: kRailwayBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${run.trainNo}  –  ${run.trainName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _runStatusColor(run.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  run.status,
                  style: TextStyle(
                      color: _runStatusColor(run.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Instance ID
          _infoRow('Instance ID', run.instanceId),
          const SizedBox(height: 4),
          _infoRow('Departure', run.departureDate),
          const SizedBox(height: 4),
          _infoRow('Outbound / Inbound',
              '${run.outboundTrainNo} / ${run.inboundTrainNo}'),
          if (run.myCoach != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.airline_seat_recline_extra,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Coach: ${run.myCoach!.coachType}  (Position ${run.myCoach!.coachPosition})',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
                const Spacer(),
                // Container(
                //   padding:
                //   const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                //   decoration: BoxDecoration(
                //     color: run.myCoach!.attendanceStatus == 'Pending'
                //         ? Colors.orange.shade50
                //         : Colors.green.shade50,
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Text(
                //     run.myCoach!.attendanceStatus,
                //     style: TextStyle(
                //         fontSize: 11,
                //         fontWeight: FontWeight.w600,
                //         color: run.myCoach!.attendanceStatus == 'Pending'
                //             ? Colors.orange
                //             : Colors.green),
                //   ),
                // ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _runStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  static BoxDecoration _boxDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
    ],
  );

  static Widget _statusChip(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration:
    BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text,
        style: TextStyle(
            color: fg, fontSize: 13, fontWeight: FontWeight.w500)),
  );

  static Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _boxDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  static Widget _buildInfoTile(String title, String value, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration:
      BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500))),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  static Widget _buildActionTile(IconData icon, String label, Color bgColor,
      Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context, WorkerController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout? Your unsaved data may be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Clear all cached worker data
              await controller.clearCache();

              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const LoginScreen()),
                    (route) => false,
              );

              Get.snackbar(
                'Success',
                'Logged out successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: kSuccessGreen,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}