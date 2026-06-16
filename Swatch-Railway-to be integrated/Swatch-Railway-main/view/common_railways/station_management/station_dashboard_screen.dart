import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/view/common_railways/station_management/station_master_screen.dart';
import 'package:crm_train/view/common_railways/station_management/station_cleaning_form_screen.dart';
import 'package:crm_train/view/common_railways/station_management/station_form_detail_screen.dart';

class StationDashboardScreen extends StatefulWidget {
  const StationDashboardScreen({super.key});

  @override
  State<StationDashboardScreen> createState() => _StationDashboardScreenState();
}

class _StationDashboardScreenState extends State<StationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isDashboardLoading = true;
  bool isStationsLoading = true;
  bool isFormsLoading = true;
  String? dashboardError;
  String? stationsError;
  String? formsError;

  StationDashboardSummary? dashboard;
  List<Station> stations = [];
  List<StationCleaningForm> forms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
    _loadStations();
    _loadForms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() { isDashboardLoading = true; dashboardError = null; });
    try {
      final data = await ApiService.getStationDashboard();
      if (mounted) setState(() { dashboard = StationDashboardSummary.fromJson(data); isDashboardLoading = false; });
    } catch (e) {
      if (mounted) setState(() { isDashboardLoading = false; dashboardError = e.toString(); });
    }
  }

  Future<void> _loadStations() async {
    setState(() { isStationsLoading = true; stationsError = null; });
    try {
      final role = Provider.of<AuthProvider>(context, listen: false).currentUser?.role ?? '';
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final data = await ApiService.getStations();
      if (mounted) {
        List<Station> all = (data['stations'] as List).map((s) => Station.fromJson(s)).toList();
        if (role == 'Railway Supervisor') {
          all = all.where((s) => s.division == user?.division).toList();
        } else if (role == 'Contractor' || role == 'Contractor Master') {
          all = all.where((s) => s.uid == user?.entityId).toList();
        }
        setState(() { stations = all; isStationsLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { isStationsLoading = false; stationsError = e.toString(); });
    }
  }

  Future<void> _loadForms() async {
    setState(() { isFormsLoading = true; formsError = null; });
    try {
      final role = Provider.of<AuthProvider>(context, listen: false).currentUser?.role ?? '';
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final data = await ApiService.getStationCleaningForms();
      if (mounted) {
        List<StationCleaningForm> all = (data['forms'] as List).map((f) => StationCleaningForm.fromJson(f)).toList();
        if (role == 'Railway Supervisor') {
          all = all.where((f) => f.division == user?.division).toList();
        } else if (role == 'Contractor' || role == 'Contractor Master') {
          all = all.where((f) => f.submittedBy == user?.uid).toList();
        }
        setState(() { forms = all; isFormsLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { isFormsLoading = false; formsError = e.toString(); });
    }
  }

  Color _statusColor(StationFormStatus status) {
    switch (status) {
      case StationFormStatus.draft: return Colors.grey;
      case StationFormStatus.submitted: return Colors.blue;
      case StationFormStatus.approved: return kSuccessGreen;
      case StationFormStatus.scored: return Colors.purple;
      case StationFormStatus.locked: return Colors.grey.shade800;
      case StationFormStatus.rejected: return kErrorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context).currentUser?.role ?? '';
    final isAdmin = role == 'Railway Admin' || role == 'Railway Master' || role == 'Company Master';
    final isSupervisor = role == 'Railway Supervisor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 18)),
            Tab(text: 'Stations', icon: Icon(Icons.train, size: 18)),
            Tab(text: 'Cleaning Forms', icon: Icon(Icons.cleaning_services, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isAdmin, isSupervisor),
          _buildStationsTab(isAdmin),
          _buildFormsTab(isAdmin, isSupervisor),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isAdmin, bool isSupervisor) {
    if (isDashboardLoading) return const Center(child: CircularProgressIndicator());
    if (dashboardError != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
      const SizedBox(height: 16),
      Text(dashboardError!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
    ]));
    final d = dashboard;
    if (d == null) return const Center(child: Text('No data'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              _summaryCard('Total Stations', '${d.totalStations}', kRailwayBlue, Icons.train),
              _summaryCard('Active Stations', '${d.activeStations}', kSuccessGreen, Icons.check_circle),
              _summaryCard('Areas', '${d.totalAreas}', Colors.teal, Icons.layers),
              _summaryCard('Zones', '${d.totalZones}', kWarningOrange, Icons.map),
              _summaryCard('Pending Forms', '${d.pendingReview}', kErrorRed, Icons.pending_actions),
              _summaryCard('Avg Score', '${d.averageScore.toStringAsFixed(1)}%', Colors.purple, Icons.score),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.add_location_alt,
                  title: 'Add Station',
                  subtitle: 'Register new station',
                  color: kRailwayBlue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StationMasterScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  icon: Icons.post_add,
                  title: 'New Cleaning Form',
                  subtitle: 'Create cleaning form',
                  color: kSuccessGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StationCleaningFormScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  icon: Icons.visibility,
                  title: 'View All',
                  subtitle: 'See all stations',
                  color: kWarningOrange,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(2, 3))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStationsTab(bool isAdmin) {
    if (isStationsLoading) return const Center(child: CircularProgressIndicator());
    if (stationsError != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
      const SizedBox(height: 16),
      Text(stationsError!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _loadStations, child: const Text('Retry')),
    ]));
    if (stations.isEmpty) return const Center(child: Text('No stations found'));

    return RefreshIndicator(
      onRefresh: _loadStations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final s = stations[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.train, color: kRailwayBlue, size: 24),
              ),
              title: Text(s.stationName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Code: ${s.stationCode}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(s.categoryLabel, style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${s.zone} / ${s.division}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Station: ${s.stationName} (${s.stationCode})')));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormsTab(bool isAdmin, bool isSupervisor) {
    if (isFormsLoading) return const Center(child: CircularProgressIndicator());
    if (formsError != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
      const SizedBox(height: 16),
      Text(formsError!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _loadForms, child: const Text('Retry')),
    ]));
    if (forms.isEmpty) return const Center(child: Text('No cleaning forms found'));

    return RefreshIndicator(
      onRefresh: _loadForms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: forms.length,
        itemBuilder: (context, index) {
          final f = forms[index];
          final statusColor = _statusColor(f.status);
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.cleaning_services, color: statusColor, size: 22),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(f.formId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(f.statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Station: ${f.stationName}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(height: 2),
                    Text('Date: ${f.cleaningDate} | Shift: ${f.shift}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              isThreeLine: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StationFormDetailScreen(formUid: f.uid ?? ''))),
            ),
          );
        },
      ),
    );
  }
}
