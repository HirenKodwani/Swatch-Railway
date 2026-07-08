import 'package:flutter/material.dart';
import 'package:crm_train/model/area_cleaning_models.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

class AreaPerformanceDashboard extends StatefulWidget {
  final String? areaId;
  final String? areaName;
  const AreaPerformanceDashboard({super.key, this.areaId, this.areaName});

  @override
  State<AreaPerformanceDashboard> createState() => _AreaPerformanceDashboardState();
}

class _AreaPerformanceDashboardState extends State<AreaPerformanceDashboard> {
  List<Station> _stations = [];
  String? _selectedAreaId;
  String _selectedAreaName = '';
  AreaDashboard? _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedAreaId = widget.areaId;
    _selectedAreaName = widget.areaName ?? '';
    if (_selectedAreaId != null) {
      _loadDashboard();
    } else {
      _loadStations();
    }
  }

  Future<void> _loadStations() async {
    try {
      _stations = await ApiService.getStations(active: true);
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    if (_selectedAreaId == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/dashboard/area/$_selectedAreaId',
        parser: (d) => d,
      );
      _dashboard = AreaDashboard.fromJson(result);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadScoreTrend() async {
    try {
      await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/station-reports/score-trend',
        queryParams: {'stationId': _dashboard?.stationId ?? '', 'months': '6'},
        parser: (d) => d,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_selectedAreaName.isNotEmpty ? 'Performance: $_selectedAreaName' : 'Area Performance',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                    ],
                  ),
                )
              : _dashboard == null
                  ? const Center(child: Text('No data'))
                  : RefreshIndicator(
                      onRefresh: _loadDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCard(),
                            const SizedBox(height: 12),
                            _buildCleaningCard(),
                            const SizedBox(height: 12),
                            _buildWorkersCard(),
                            const SizedBox(height: 12),
                            _buildTodayTasksCard(),
                            const SizedBox(height: 12),
                            _buildScorecardSection(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOverviewCard() {
    final c = _dashboard!.cleaning;
    final completed = (c['completedTasks'] ?? 0).toString();
    final pending = (c['pendingTasks'] ?? 0).toString();
    final score = (c['averageScore'] ?? 0).toStringAsFixed(1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.speed, color: kRailwayBlue, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            Row(
              children: [
                _statItem('Score', score, kRailwayBlue),
                _statItem('Completed', completed, kSuccessGreen),
                _statItem('Pending', pending, kWarningOrange),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statItem('Frequency', _dashboard!.cleaningFrequency, Colors.teal),
                _statItem('Priority', 'P${_dashboard!.priority}', _dashboard!.priority <= 2 ? kErrorRed : kSuccessGreen),
                _statItem('Shift', _dashboard!.defaultShift, Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleaningCard() {
    final c = _dashboard!.cleaning;
    final coverage = (c['coverage'] ?? 0).toStringAsFixed(1);
    final missed = (c['missedActivities'] ?? 0).toString();
    final runs = _dashboard!.runs.toString();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kSuccessGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.cleaning_services, color: kSuccessGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Cleaning Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            Row(
              children: [
                _statItem('Coverage', '$coverage%', kSuccessGreen),
                _statItem('Missed', missed, kErrorRed),
                _statItem('Runs', runs, kRailwayBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.people, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Workers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            Text('Total: ${_dashboard!.workerCount}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTasksCard() {
    final tasks = _dashboard!.scheduledTasks;
    final pending = tasks.where((t) => t.status == 'pending').length;
    final completed = tasks.where((t) => t.status == 'completed' || t.status == 'approved').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kWarningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.list_alt, color: kWarningOrange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Today\'s Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            Row(
              children: [
                _statItem('Total', '${tasks.length}', kRailwayBlue),
                _statItem('Pending', '$pending', kWarningOrange),
                _statItem('In Progress', '$inProgress', Colors.teal),
                _statItem('Done', '$completed', kSuccessGreen),
              ],
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: tasks.length.clamp(0, 3),
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            t.status == 'completed' || t.status == 'approved'
                                ? Icons.check_circle : t.status == 'in_progress'
                                    ? Icons.play_circle : Icons.schedule,
                            size: 16,
                            color: t.status == 'completed' || t.status == 'approved'
                                ? kSuccessGreen : t.status == 'in_progress'
                                    ? kRailwayBlue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(t.activityType ?? 'Task', style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text(t.scheduledTime, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardSection() {
    final c = _dashboard!.cleaning;
    final avgScore = (c['averageScore'] as num?)?.toDouble() ?? 0;
    final completionRate = (c['completionRate'] as num?)?.toDouble() ?? 0;
    final missed = (c['missedActivities'] as num?)?.toDouble() ?? 0;

    if (avgScore == 0 && completionRate == 0) return const SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.assessment, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Scorecard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            _scoreBar('Avg Score', avgScore, Colors.teal),
            _scoreBar('Completion', completionRate, kRailwayBlue),
            _scoreBar('Missed', missed.clamp(0, 100), kErrorRed),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(String label, dynamic value, Color color) {
    final v = (value is num) ? value.toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text('${v.toStringAsFixed(0)}/100', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
        ],
      ),
    );
  }
}
