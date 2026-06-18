import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

import 'obhs_coach_checklist_screen.dart';
import 'attendant_linen_screen.dart';

import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'obhs_attendance_screen.dart';

class AttendantHomeScreen extends StatefulWidget {
  final UserModel user;

  const AttendantHomeScreen({super.key, required this.user});

  @override
  State<AttendantHomeScreen> createState() => _AttendantHomeScreenState();
}

class _AttendantHomeScreenState extends State<AttendantHomeScreen> {
  // Placeholder dynamic coaches for Attendant (AC Coaches only)
  final List<Map<String, dynamic>> myAcCoaches = [
    {'coach': 'A1', 'tasks': 4, 'completed': 1, 'status': 'in_progress'},
    {'coach': 'A2', 'tasks': 4, 'completed': 0, 'status': 'pending'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Duty (Attendant)',
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
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderAndOverview(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'My Assigned AC Coaches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (myAcCoaches.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: myAcCoaches.length,
                itemBuilder: (context, index) {
                  return _buildCoachTile(myAcCoaches[index]);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Quick navigate to Linen module
          Navigator.push(context, MaterialPageRoute(builder: (_) => AttendantLinenScreen(user: widget.user)));
        },
        backgroundColor: kRailwayBlue,
        icon: const Icon(Icons.local_laundry_service, color: Colors.white),
        label: const Text('Manage Linen', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeaderAndOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: kRailwayBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${widget.user.fullName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Train: 12456 - ExpressB',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // Attendance Status Chip
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ObhsAttendanceScreen(user: widget.user)));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fingerprint, color: Colors.greenAccent, size: 14),
                      SizedBox(width: 4),
                      Text('PRESENT', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewCard('Linen Tasks', '2', Icons.local_laundry_service, Colors.orange),
              _buildOverviewCard('Completed', '0', Icons.check_circle, Colors.green),
              _buildOverviewCard('Requests', '1', Icons.person_pin_circle, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No AC coaches assigned.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wait for your supervisor to assign duties.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachTile(Map<String, dynamic> coach) {
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

    final progress = coach['completed'] / coach['tasks'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ObhsCoachChecklistScreen(user: widget.user, coachLabel: coach['coach'])));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.airline_seat_recline_extra, color: kRailwayBlue, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Coach ${coach['coach']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Safety/Linen Tasks: ${coach['completed']} / ${coach['tasks']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: statusColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ObhsCoachChecklistScreen(user: widget.user, coachLabel: coach['coach'])));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRailwayBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Coach Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
