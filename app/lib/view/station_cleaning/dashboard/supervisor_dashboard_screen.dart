import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/providers/station_cleaning_provider.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/common_railways/widgets/hierarchy_breadcrumb.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String? platformId;
  const SupervisorDashboardScreen({super.key, required this.stationId, required this.stationName, this.platformId});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  String? _supervisorId;
  Map<String, dynamic>? _dashboardData;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _supervisorId = prefs.getString('userId');
      await _fetchDashboard();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _fetchDashboard() async {
    if (_supervisorId == null) return;
    final date = _selectedDate?.toIso8601String().split('T')[0];
    final provider = context.read<StationCleaningProvider>();
    final data = await provider.fetchSupervisorDashboard(_supervisorId!, date: date);
    setState(() { _dashboardData = data; _isLoading = false; _error = data == null ? 'Failed to load' : null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUserAndData),
        ],
      ),
      body: Column(
        children: [
          HierarchyBreadcrumb(stationName: widget.stationName, platformName: widget.platformId != null ? 'Platform' : null),
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12), Text(_error!), const SizedBox(height: 8),
                  ElevatedButton(onPressed: _fetchDashboard, child: const Text('Retry')),
                ]))
              : RefreshIndicator(onRefresh: _fetchDashboard, child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _dashboardData;
    if (d == null) return const SizedBox();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _summaryCard('${d['totalTasks'] ?? 0} Total Tasks', Icons.assignment, Colors.blueGrey),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _statChip('Completed', '${d['completedTasks'] ?? 0}', kSuccessGreen),
            _statChip('In Progress', '${d['inProgressTasks'] ?? 0}', kRailwayBlue),
            _statChip('Pending', '${d['pendingTasks'] ?? 0}', kWarningOrange),
            _statChip('Approved', '${d['approvedTasks'] ?? 0}', Colors.teal),
            _statChip('Rejected', '${d['rejectedTasks'] ?? 0}', kErrorRed),
            _statChip('Overdue', '${d['overdueTasks'] ?? 0}', Colors.deepOrange),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Area Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...(d['areaPerformance'] as List? ?? []).map((a) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${a['total'] ?? 0}')),
            title: Text(a['areaName'] ?? 'Unknown Area'),
            subtitle: LinearProgressIndicator(value: (a['total'] ?? 0) > 0 ? (a['completed'] ?? 0) / a['total'] : 0, backgroundColor: Colors.grey.withValues(alpha: 0.5)),
            trailing: Text('Score: ${a['score'] ?? 0}', style: TextStyle(color: _scoreColor(a['score']), fontWeight: FontWeight.bold)),
          ),
        )),
        const SizedBox(height: 16),
        const Text('Worker Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...(d['workerPerformance'] as List? ?? []).take(10).map((w) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${w['total'] ?? 0}')),
            title: Text(w['workerName'] ?? 'Unknown'),
            subtitle: Text('${w['completed'] ?? 0}/${w['total'] ?? 0} tasks'),
            trailing: Text('${w['score'] ?? 0}', style: TextStyle(color: _scoreColor(w['score']), fontWeight: FontWeight.bold)),
          ),
        )),
      ],
    );
  }

  Widget _summaryCard(String label, IconData icon, Color color) {
    return Card(child: ListTile(leading: Icon(icon, color: color), title: Text(label)));
  }

  Widget _statChip(String label, String value, Color color) {
    return Chip(label: Text('$label: $value', style: TextStyle(color: color, fontWeight: FontWeight.w600)), backgroundColor: color.withValues(alpha: 0.1));
  }

  Color _scoreColor(dynamic score) {
    final s = (score is int ? score : int.tryParse(score.toString())) ?? 0;
    return s >= 80 ? kSuccessGreen : s >= 60 ? kWarningOrange : kErrorRed;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) { setState(() => _selectedDate = picked); _fetchDashboard(); }
  }
}
