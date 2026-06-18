import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

import 'obhs_coach_checklist_screen.dart';
import 'package:crm_train/utills/app_colors.dart';

import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CsFieldExecutionScreen extends StatefulWidget {
  final UserModel user;

  const CsFieldExecutionScreen({super.key, required this.user});

  @override
  State<CsFieldExecutionScreen> createState() => _CsFieldExecutionScreenState();
}

class _CsFieldExecutionScreenState extends State<CsFieldExecutionScreen> {
  // Placeholder data for coaches assigned to this CS
  final List<Map<String, dynamic>> assignedCoaches = [
    {'coach': 'B1', 'worker': 'Amit Singh', 'tasks_done': 4, 'total_tasks': 5, 'pending_approvals': 2},
    {'coach': 'B2', 'worker': 'Amit Singh', 'tasks_done': 1, 'total_tasks': 5, 'pending_approvals': 0},
    {'coach': 'B3', 'worker': 'Suresh D', 'tasks_done': 5, 'total_tasks': 5, 'pending_approvals': 5},
    {'coach': 'B4', 'worker': 'Suresh D', 'tasks_done': 0, 'total_tasks': 5, 'pending_approvals': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Field Execution (CS)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kRailwayBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignedCoaches.length,
              itemBuilder: (context, index) {
                return _buildCoachExecutionCard(assignedCoaches[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: kRailwayBlue.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: kRailwayBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are supervising ${assignedCoaches.length} coaches on Train 12456.',
              style: const TextStyle(
                color: kRailwayBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachExecutionCard(Map<String, dynamic> coach) {
    final int pendingApprovals = coach['pending_approvals'];
    final double progress = coach['tasks_done'] / coach['total_tasks'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kRailwayBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coach['coach'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned to: ${coach['worker']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${coach['tasks_done']} of ${coach['total_tasks']} tasks completed',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: progress == 1.0 ? kSuccessGreen : kRailwayBlue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pendingApprovals > 0)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: kWarningOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          pendingApprovals.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          color: kWarningOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: kSuccessGreen, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'All clear',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ObhsCoachChecklistScreen(user: widget.user, coachLabel: coach['coach'])));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kRailwayBlue,
                    side: const BorderSide(color: kRailwayBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Review Coach'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
