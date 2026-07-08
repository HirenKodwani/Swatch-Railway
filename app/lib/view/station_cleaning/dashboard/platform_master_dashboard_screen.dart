import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/station_cleaning_provider.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/common_railways/widgets/hierarchy_breadcrumb.dart';

class PlatformMasterDashboardScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String platformId;
  final String platformName;

  const PlatformMasterDashboardScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.platformId,
    this.platformName = 'Platform',
  });

  @override
  State<PlatformMasterDashboardScreen> createState() => _PlatformMasterDashboardScreenState();
}

class _PlatformMasterDashboardScreenState extends State<PlatformMasterDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _areas = [];
  Map<String, dynamic>? _dailyReport;
  bool _showAreas = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<StationCleaningProvider>();
      _areas = await provider.fetchAreas(widget.stationId, platformId: widget.platformId);
      final today = DateTime.now().toIso8601String().split('T')[0];
      _dailyReport = await provider.fetchDailyReport(widget.stationId, date: today);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showAreas ? Icons.dashboard : Icons.list),
            onPressed: () => setState(() => _showAreas = !_showAreas),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          HierarchyBreadcrumb(stationName: widget.stationName, platformName: widget.platformName),
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12), Text(_error!), const SizedBox(height: 8),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(onRefresh: _load, child: _showAreas ? _buildAreaView() : _buildReportView())),
        ],
      ),
    );
  }

  Widget _buildAreaView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('${_areas.length} Areas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._areas.map((a) => Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: kRailwayBlue.withValues(alpha: 0.1),
              child: Icon(Icons.cleaning_services, color: kRailwayBlue, size: 20),
            ),
            title: Text(a['areaName'] ?? 'Unknown Area'),
            subtitle: Text('Type: ${a['areaType'] ?? 'N/A'}'),
            trailing: Chip(
              label: Text(a['status'] ?? 'active', style: const TextStyle(fontSize: 11)),
              backgroundColor: (a['status'] == 'active' ? kSuccessGreen : Colors.grey).withValues(alpha: 0.1),
            ),
          ),
        )),
        if (_areas.isEmpty) const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No areas found for this platform', style: TextStyle(color: Colors.grey)),
        )),
      ],
    );
  }

  Widget _buildReportView() {
    final dr = _dailyReport;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (dr != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('Today\'s Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kRailwayBlue)),
                const SizedBox(height: 12),
                _statRow('Total Tasks', '${dr['totalTasks'] ?? 0}', Icons.assignment, Colors.blueGrey),
                _statRow('Completed', '${dr['completedTasks'] ?? 0}', Icons.check_circle, kSuccessGreen),
                _statRow('Pending', '${dr['pendingTasks'] ?? 0}', Icons.hourglass_empty, kWarningOrange),
                _statRow('Average Score', '${dr['averageScore'] ?? 0}%', Icons.star, Colors.amber),
                _statRow('Grade', dr['grade'] ?? 'N/A', Icons.grade, _gradeColor(dr['grade'])),
              ]),
            ),
          ),
        ] else ...[
          const Center(child: Text('No report data available', style: TextStyle(color: Colors.grey))),
        ],
      ],
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: color, size: 20), const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Color _gradeColor(String? grade) {
    switch (grade) {
      case 'A': return kSuccessGreen;
      case 'B': return Colors.blue;
      case 'C': return kWarningOrange;
      default: return kErrorRed;
    }
  }
}
