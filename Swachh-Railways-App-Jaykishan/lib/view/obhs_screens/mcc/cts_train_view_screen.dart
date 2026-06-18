import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

import 'obhs_coach_checklist_screen.dart';
import 'package:crm_train/utills/app_colors.dart';

import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CtsTrainViewScreen extends StatefulWidget {
  final UserModel user;

  const CtsTrainViewScreen({super.key, required this.user});

  @override
  State<CtsTrainViewScreen> createState() => _CtsTrainViewScreenState();
}

class _CtsTrainViewScreenState extends State<CtsTrainViewScreen> {
  // Placeholder data
  final String trainNo = "12456";
  final String trainName = "ExpressB";
  final int totalCoaches = 14;
  final int completedCoaches = 8;

  final List<Map<String, dynamic>> coaches = [
    {'coach': 'A1', 'worker': 'Ravi Kumar', 'status': 'completed', 'progress': 1.0},
    {'coach': 'A2', 'worker': 'Ravi Kumar', 'status': 'completed', 'progress': 1.0},
    {'coach': 'B1', 'worker': 'Amit Singh', 'status': 'in_progress', 'progress': 0.6},
    {'coach': 'B2', 'worker': 'Amit Singh', 'status': 'pending', 'progress': 0.0},
    {'coach': 'B3', 'worker': 'Suresh D', 'status': 'completed', 'progress': 1.0},
    {'coach': 'S1', 'worker': 'Manoj V', 'status': 'in_progress', 'progress': 0.4},
    {'coach': 'S2', 'worker': 'Manoj V', 'status': 'pending', 'progress': 0.0},
    {'coach': 'S3', 'worker': 'Karan P', 'status': 'completed', 'progress': 1.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Train Run Supervision',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '$trainNo - $trainName',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
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
          _buildSummaryBar(),
          _buildFilterBar(),
          Expanded(
            child: _buildCoachGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kRailwayBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat('Total', totalCoaches.toString()),
          _buildSummaryStat('Completed', completedCoaches.toString(), color: kSuccessGreen),
          _buildSummaryStat('Pending', (totalCoaches - completedCoaches).toString(), color: kWarningOrange),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Coach Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'All Coaches',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: coaches.length,
      itemBuilder: (context, index) {
        final coach = coaches[index];
        return _buildCoachCard(coach);
      },
    );
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    Color statusColor;
    String statusText;

    switch (coach['status']) {
      case 'completed':
        statusColor = kSuccessGreen;
        statusText = 'Completed';
        break;
      case 'in_progress':
        statusColor = kWarningOrange;
        statusText = 'In Progress';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Pending';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ObhsCoachChecklistScreen(user: widget.user, coachLabel: coach['coach'])));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kRailwayBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      coach['coach'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kRailwayBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      coach['worker'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '${(coach['progress'] * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: coach['progress'],
                    backgroundColor: Colors.grey[200],
                    color: statusColor,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
