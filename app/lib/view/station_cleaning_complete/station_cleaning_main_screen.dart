import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/station_cleaning/station_cleaning_hub_screen.dart';
import 'package:crm_train/view/station_cleaning/billing/billing_support_pack_screen.dart';
import 'package:crm_train/view/station_cleaning/inspection/inspection_list_screen.dart';
import 'package:crm_train/view/station_cleaning/complaint/complaint_list_screen.dart';
import 'package:crm_train/view/station_cleaning/scorecard/scorecard_list_screen.dart';
import 'package:crm_train/view/station_cleaning/feedback/feedback_qr_screen.dart';
import 'package:crm_train/view/station_cleaning/reporting/report_list_screen.dart';
import 'package:crm_train/view/common_railways/station_management/task_generation_screen.dart';
import 'package:crm_train/view/common_railways/station_management/task_approval_screen.dart';
import 'package:crm_train/view/station_cleaning/attendance/station_attendance_screen.dart';
import 'package:crm_train/view/station_cleaning/activities/daily_activity_list_screen.dart';
import 'package:crm_train/view/station_cleaning/cleaning_form/station_cleaning_form_list_screen.dart';
import 'package:crm_train/view/station_cleaning/evidence/evidence_gallery_screen.dart';
import 'package:crm_train/view/station_cleaning/supervisor_log/supervisor_log_list_screen.dart';
import 'package:crm_train/view/station_cleaning/schedule/station_schedule_screen.dart';
import 'package:crm_train/view/station_cleaning/supervisor_review/supervisor_review_screen.dart';
import 'package:crm_train/view/station_cleaning/machine/machine_tracking_screen.dart';
import 'package:crm_train/view/station_cleaning/garbage/garbage_management_screen.dart';
import 'package:crm_train/view/station_cleaning/pest_control/pest_control_list_screen.dart';
import 'package:crm_train/view/station_cleaning/area_config/area_config_screen.dart';

class StationCleaningMainScreen extends StatefulWidget {
  const StationCleaningMainScreen({super.key});

  @override
  State<StationCleaningMainScreen> createState() => _StationCleaningMainScreenState();
}

class _StationCleaningMainScreenState extends State<StationCleaningMainScreen> {
  List<Station> _stations = [];
  bool _stationsLoading = true;
  String? _selectedStationId;
  String _selectedStationName = '';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _stationsLoading = true);
    try {
      _stations = await ApiService.getStations();
    } catch (_) {}
    if (mounted) setState(() => _stationsLoading = false);
  }

  void _openHub() {
    if (_selectedStationId == null || _selectedStationId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a station first'), backgroundColor: kWarningOrange),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StationCleaningHubScreen(
        stationId: _selectedStationId!, stationName: _selectedStationName,
      ),
    ));
  }

  void _openInspection() {
    if (_selectedStationId == null || _selectedStationId!.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => InspectionListScreen(stationId: _selectedStationId!, stationName: _selectedStationName),
    ));
  }

  void _openComplaints() {
    if (_selectedStationId == null || _selectedStationId!.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ComplaintListScreen(stationId: _selectedStationId!, stationName: _selectedStationName),
    ));
  }

  void _openScorecard() {
    if (_selectedStationId == null || _selectedStationId!.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScorecardListScreen(stationId: _selectedStationId!, stationName: _selectedStationName),
    ));
  }

  void _openFeedback() {
    if (_selectedStationId == null || _selectedStationId!.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FeedbackQrScreen(stationId: _selectedStationId!, stationName: _selectedStationName),
    ));
  }

  void _openReports() {
    if (_selectedStationId == null || _selectedStationId!.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ReportListScreen(stationId: _selectedStationId!, stationName: _selectedStationName),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Cleaning Module', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selectedStationId != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              tooltip: 'Open Hub',
              onPressed: _openHub,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Station selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Station', style: TextStyle(fontWeight: FontWeight.bold, color: kRailwayBlue, fontSize: 14)),
                  const SizedBox(height: 8),
                  _stationsLoading
                      ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      : DropdownButtonFormField<String>(
                          value: _selectedStationId,
                          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Choose a station...'),
                          items: _stations.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                            value: s.uid,
                            child: Text(s.stationName ?? s.uid ?? ''),
                          )).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedStationId = v;
                              _selectedStationName = _stations.firstWhere((s) => s.uid == v, orElse: () => Station(stationCode: v ?? '', stationName: v ?? '', zone: '', division: '')).stationName ?? '';
                            });
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick actions grid
          Text('QUICK ACCESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kRailwayBlue)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.0,
            ),
            itemCount: 6,
            itemBuilder: (_, i) {
              final items = [
                _QuickAction('Hub', Icons.dashboard, kRailwayBlue, _selectedStationId != null ? _openHub : null),
                _QuickAction('Inspection', Icons.search, Colors.deepPurple, _selectedStationId != null ? _openInspection : null),
                _QuickAction('Complaints', Icons.report, Colors.red, _selectedStationId != null ? _openComplaints : null),
                _QuickAction('Scorecard', Icons.star, Colors.pink, _selectedStationId != null ? _openScorecard : null),
                _QuickAction('Feedback', Icons.feedback, Colors.amber, _selectedStationId != null ? _openFeedback : null),
                _QuickAction('Reports', Icons.assessment, Colors.purple, _selectedStationId != null ? _openReports : null),
              ];
              final item = items[i];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: item.onTap,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(
                      backgroundColor: item.color.withValues(alpha: 0.15),
                      radius: 24,
                      child: Icon(item.icon, color: item.color, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // All modules list
          Text('ALL MODULES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kRailwayBlue)),
          const SizedBox(height: 8),
          ..._buildModuleList(),
        ],
      ),
    );
  }

  List<Widget> _buildModuleList() {
    final modules = <_Module>[];

    modules.add(_Module('Hub', 'Station Cleaning Hub with all KPIs', Icons.dashboard, Colors.blue, _selectedStationId != null ? _openHub : null));
    modules.add(_Module('Inspection', 'Ad hoc, routine, surprise, scorecard inspections', Icons.search, Colors.deepPurple, _selectedStationId != null ? _openInspection : null));
    modules.add(_Module('Complaints', 'Report & track petty issues', Icons.report, Colors.red, _selectedStationId != null ? _openComplaints : null));
    modules.add(_Module('Scorecard', 'Cleanliness scorecards', Icons.star, Colors.pink, _selectedStationId != null ? _openScorecard : null));

    if (_selectedStationId != null) {
      modules.add(_Module('Attendance', 'Station attendance', Icons.people, Colors.teal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => StationAttendanceScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Activities', 'Daily cleaning activities', Icons.assignment, Colors.orange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DailyActivityListScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Cleaning Forms', 'Station cleaning forms', Icons.cleaning_services, Colors.lightBlue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => StationCleaningFormListScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Evidence', 'Photo evidence gallery', Icons.camera_alt, Colors.brown, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => EvidenceGalleryScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Supervisor Log', 'Daily supervisor logs', Icons.description, Colors.cyan, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorLogListScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Area Config', 'Area configuration', Icons.settings, Colors.blueGrey, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AreaConfigScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Task Generation', 'Generate cleaning tasks', Icons.auto_awesome, Colors.deepPurple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TaskGenerationScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Task Approval', 'Approve/reject tasks', Icons.rate_review_outlined, kWarningOrange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TaskApprovalScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Billing', 'Billing support packs', Icons.receipt, Colors.deepOrange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BillingSupportPackScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Reports', 'Daily/monthly/audit reports', Icons.assessment, Colors.purple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReportListScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Machines', 'Equipment tracking', Icons.precision_manufacturing, Colors.blueGrey, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MachineTrackingScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Garbage', 'Disposal management', Icons.delete, Colors.brown, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => GarbageManagementScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Pest Control', 'Pest treatment log', Icons.bug_report, Colors.green, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PestControlListScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Schedules', 'Station schedules', Icons.schedule, Colors.teal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => StationScheduleScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Feedback', 'Passenger feedback', Icons.feedback, Colors.amber, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackQrScreen(stationId: _selectedStationId!, stationName: _selectedStationName)));
      }));
      modules.add(_Module('Supervisor Review', 'Review completed tasks', Icons.rate_review, Colors.purple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorReviewScreen(stationId: _selectedStationId!)));
      }));
    }

    return modules.map((m) => Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: m.color.withValues(alpha: 0.15), child: Icon(m.icon, color: m.color, size: 22)),
        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(m.subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: m.onTap,
        enabled: m.onTap != null,
      ),
    )).toList();
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  _Module(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
