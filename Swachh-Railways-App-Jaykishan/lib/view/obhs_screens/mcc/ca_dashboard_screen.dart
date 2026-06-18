import 'package:flutter/material.dart';
import 'package:crm_train/model/user_model.dart';
import 'package:crm_train/utills/app_colors.dart';

import 'cs_field_execution_screen.dart';
import 'obhs_supervisor_approval_screen.dart';
import 'ca_manage_assignments_screen.dart';
import 'package:crm_train/utills/app_colors.dart';

import 'cs_field_execution_screen.dart';
import 'obhs_supervisor_approval_screen.dart';
import 'package:crm_train/utills/app_colors.dart';

import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CaDashboardScreen extends StatefulWidget {
  final UserModel user;

  const CaDashboardScreen({super.key, required this.user});

  @override
  State<CaDashboardScreen> createState() => _CaDashboardScreenState();
}

class _CaDashboardScreenState extends State<CaDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Contractor Admin',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Contract Overview'),
              const SizedBox(height: 12),
              _buildKPIs(),
              const SizedBox(height: 24),
              _buildSectionTitle('Active Worker Deployment'),
              const SizedBox(height: 12),
              _buildWorkerSummary(),
              const SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${widget.user.fullName}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kRailwayBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your contract zones, workers, and field supervisors.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildKPIs() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard('Trains Today', '8', Icons.train, Colors.blue),
        _buildKpiCard('Total Coaches', '142', Icons.view_column, Colors.purple),
        _buildKpiCard('Field Supervisors', '12', Icons.admin_panel_settings, Colors.teal),
        _buildKpiCard('Pending Approvals', '24', Icons.pending_actions, kWarningOrange),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildWorkerRow('Present (Active)', '156', Colors.green),
          const Divider(),
          _buildWorkerRow('Pending Sign-in', '24', kWarningOrange),
          const Divider(),
          _buildWorkerRow('Absent', '5', kErrorRed),
        ],
      ),
    );
  }

  Widget _buildWorkerRow(String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.edit_document,
          title: 'Manage Tasks & Assignments',
          subtitle: 'Assign workers and edit tasks for coaches',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CaManageAssignmentsScreen(user: widget.user)));
          },
        ),
        _buildActionTile(
          icon: Icons.assignment_ind,
          title: 'Assign Field Supervisors',
          subtitle: 'Manage CS and CTS assignments',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CsFieldExecutionScreen(user: widget.user)));
          },
        ),
        _buildActionTile(
          icon: Icons.checklist_rtl,
          title: 'Review Submissions',
          subtitle: 'Check pending approvals or escalated issues',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ObhsSupervisorApprovalScreen()));
          },
        ),
        _buildActionTile(
          icon: Icons.report_problem,
          title: 'Complaints',
          subtitle: 'View and manage escalations',
          onTap: () {
            // Placeholder for complaint screen
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kRailwayBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kRailwayBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
