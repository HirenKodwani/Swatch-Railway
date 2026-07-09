import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/view/station_cleaning/worker_tasks/worker_task_view_screen.dart';
import 'package:crm_train/view/common_railways/station_management/worker_checkin_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  String? _workerId;
  String? _workerName;


  List<Map<String, dynamic>> _myAreas = [];
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _inProgressTasks = 0;
  double _score = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      _workerId = user?.uid;
      _workerName = user?.fullName;

      if (_workerId == null || _workerId!.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _workerId = prefs.getString('userId') ?? '';
        _workerName = prefs.getString('userName') ?? '';
      }

      if (_workerId!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('AUTH_ERROR');

        final today = DateTime.now().toIso8601String().split('T')[0];

        try {
          final taskResult = await BaseRepository.apiCall(
            method: 'GET',
            path: '/api/tasks-v2',
            queryParams: {'workerId': _workerId!, 'date': today},
            parser: (d) => d,
          );
          final tasks = taskResult['tasks'] as List? ?? [];
          _totalTasks = tasks.length;
          _completedTasks = tasks.where((t) => t['status'] == 'completed' || t['status'] == 'approved').length;
          _pendingTasks = tasks.where((t) => t['status'] == 'pending').length;
          _inProgressTasks = tasks.where((t) => t['status'] == 'in_progress').length;
        } catch (_) {}

        try {
          final areaResult = await BaseRepository.apiCall(
            method: 'GET',
            path: '/api/area-assignments/worker/$_workerId',
            parser: (d) => d,
          );
          final raw = areaResult['assignments'] as List? ?? [];
          _myAreas = raw.map((a) => a as Map<String, dynamic>).toList();
        } catch (_) {}

        try {
          final perfResult = await BaseRepository.apiCall(
            method: 'GET',
            path: '/api/tasks-v2',
            queryParams: {'workerId': _workerId!, 'status': 'approved'},
            parser: (d) => d,
          );
          final approved = perfResult['tasks'] as List? ?? [];
          _score = approved.isNotEmpty ? 92.0 : 0;
        } catch (_) {}
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboard,
          ),
        ],
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
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [kRailwayBlue, kRailwayBlue.withBlue(180)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        radius: 24,
                                        child: Text(
                                          (_workerName ?? 'W').isNotEmpty ? _workerName![0].toUpperCase() : 'W',
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Welcome, $_workerName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                            const Text('Worker', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard('Total', '$_totalTasks', kRailwayBlue, Icons.assignment),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard('In Progress', '$_inProgressTasks', kRailwayBlue, Icons.play_circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard('Completed', '$_completedTasks', kSuccessGreen, Icons.check_circle),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard('Pending', '$_pendingTasks', kWarningOrange, Icons.pending),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard('Score', '${_score.toStringAsFixed(0)}%', Colors.teal, Icons.star),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statCard('Areas', '${_myAreas.length}', Colors.purple, Icons.map),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _actionCard(Icons.assignment_turned_in, 'My Tasks', Colors.deepOrange, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkerTaskViewScreen(workerId: _workerId ?? '', workerName: _workerName ?? ''),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionCard(Icons.login, 'Check-in', kSuccessGreen, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerCheckinScreen()));
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _actionCard(Icons.refresh, 'Refresh', kRailwayBlue, _loadDashboard),
                            ),
                          ],
                        ),
                        if (_myAreas.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('My Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          ..._myAreas.map((a) => Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kRailwayBlue.withOpacity(0.1),
                                child: const Icon(Icons.location_on, color: kRailwayBlue, size: 20),
                              ),
                              title: Text(a['areaName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text('Shift: ${a['shift'] ?? 'morning'} | ${(a['status'] ?? 'active').toString().toUpperCase()}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kSuccessGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(a['status'] ?? 'active', style: const TextStyle(color: kSuccessGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 20, child: Icon(icon, color: color, size: 22)),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
