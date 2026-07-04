import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'dashboard/station_dashboard_kpi_screen.dart';
import 'attendance/station_attendance_screen.dart';
import 'activities/daily_activity_list_screen.dart';
import 'billing/billing_support_pack_screen.dart';
import 'execution/execution_plan_list_screen.dart';
import 'evidence/evidence_gallery_screen.dart';
import 'supervisor_log/supervisor_log_list_screen.dart';
import 'inspection/inspection_list_screen.dart';
import 'scorecard/scorecard_list_screen.dart';
import 'complaint/complaint_list_screen.dart';
import 'pest_control/pest_control_list_screen.dart';
import 'machine/machine_tracking_screen.dart';
import 'garbage/garbage_management_screen.dart';
import 'reporting/report_list_screen.dart';

class StationCleaningHubScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  final String? contractId;

  const StationCleaningHubScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    this.contractId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(12),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
        children: [
          _moduleCard(context, Icons.dashboard, 'Dashboard', kRailwayBlue, () => _openDashboard(context)),
          _moduleCard(context, Icons.people, 'Attendance', Colors.teal, () => _openAttendance(context)),
          _moduleCard(context, Icons.assignment, 'Activities', Colors.orange, () => _openActivities(context)),
          _moduleCard(context, Icons.calendar_month, 'Execution\nPlan', Colors.indigo, () => _openExecution(context)),
          _moduleCard(context, Icons.camera_alt, 'Evidence', Colors.brown, () => _openEvidence(context)),
          _moduleCard(context, Icons.description, 'Sup. Log', Colors.cyan, () => _openSupervisorLog(context)),
          _moduleCard(context, Icons.search, 'Inspection', Colors.deepPurple, () => _openInspection(context)),
          _moduleCard(context, Icons.star, 'Scorecard', Colors.pink, () => _openScorecard(context)),
          _moduleCard(context, Icons.report, 'Complaints', Colors.red, () => _openComplaint(context)),
          _moduleCard(context, Icons.bug_report, 'Pest\nControl', Colors.green, () => _openPestControl(context)),
          _moduleCard(context, Icons.precision_manufacturing, 'Machines', Colors.blueGrey, () => _openMachine(context)),
          _moduleCard(context, Icons.delete, 'Garbage', Colors.brown.shade700, () => _openGarbage(context)),
          _moduleCard(context, Icons.receipt, 'Billing', Colors.deepOrange, () => _openBilling(context)),
          _moduleCard(context, Icons.assessment, 'Reports', Colors.purple, () => _openReports(context)),
        ],
      ),
    );
  }

  Widget _moduleCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), radius: 24, child: Icon(icon, color: color, size: 26)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _openDashboard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StationDashboardKpiScreen(stationId: stationId, stationName: stationName)));
  }

  void _openAttendance(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StationAttendanceScreen(stationId: stationId, stationName: stationName)));
  }

  void _openActivities(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DailyActivityListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openExecution(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ExecutionPlanListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openEvidence(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EvidenceGalleryScreen(stationId: stationId, stationName: stationName)));
  }

  void _openSupervisorLog(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorLogListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openInspection(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => InspectionListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openScorecard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ScorecardListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openComplaint(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openPestControl(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PestControlListScreen(stationId: stationId, stationName: stationName)));
  }

  void _openMachine(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MachineTrackingScreen(stationId: stationId, stationName: stationName)));
  }

  void _openGarbage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GarbageManagementScreen(stationId: stationId, stationName: stationName)));
  }

  void _openBilling(BuildContext context) {
    if (contractId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BillingSupportPackScreen(contractId: contractId!, stationId: stationId, stationName: stationName)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contract linked to this station')));
    }
  }

  void _openReports(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReportListScreen(stationId: stationId, stationName: stationName)));
  }
}
