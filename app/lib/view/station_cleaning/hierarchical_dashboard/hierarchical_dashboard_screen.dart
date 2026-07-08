import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/helper/api_error_handler.dart';

class HierarchicalDashboardScreen extends StatefulWidget {
  final String? initialLevel;
  final String? levelId;

  const HierarchicalDashboardScreen({
    super.key,
    this.initialLevel,
    this.levelId,
  });

  @override
  State<HierarchicalDashboardScreen> createState() => _HierarchicalDashboardScreenState();
}

class _HierarchicalDashboardScreenState extends State<HierarchicalDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;
  String? _currentLevel;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel ?? 'admin';
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('AUTH_ERROR');

      String path;
      if (_currentLevel == 'admin') {
        path = '/api/dashboard/admin';
      } else if (_currentLevel == 'zone') {
        path = '/api/dashboard/zone/${widget.levelId}';
      } else if (_currentLevel == 'station') {
        path = '/api/dashboard/station/${widget.levelId}';
      } else if (_currentLevel == 'platform') {
        path = '/api/dashboard/platform/${widget.levelId}';
      } else if (_currentLevel == 'area') {
        path = '/api/dashboard/area/${widget.levelId}';
      } else {
        throw Exception('Invalid level: $_currentLevel');
      }

      final uri = Uri.parse('${ApiService.baseUrl}$path');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as Map<String, dynamic>? ?? body;
        setState(() {
          _data = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('AUTH_ERROR');
      } else {
        throw Exception(ApiErrorHandler.getErrorMessage(response.body, response.statusCode));
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('AUTH_ERROR') ? 'Session expired' : e.toString();
        _isLoading = false;
      });
    }
  }

  Color _taskColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.amber.shade700;
      case 'completed': return Colors.green;
      case 'approved': return Colors.teal;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatCard(String label, dynamic value, {Color? color, IconData? icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (icon != null) Icon(icon, color: color ?? Colors.blue, size: 28),
            const SizedBox(height: 4),
            Text(value?.toString() ?? '0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCleaningStats(Map<String, dynamic>? cleaning) {
    if (cleaning == null || cleaning.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Cleaning Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          childAspectRatio: 1.3,
          children: cleaning.entries.map((e) => _buildStatCard(
            e.key.replaceAll('_', ' '),
            e.value,
            color: _taskColor(e.key),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAdminDashboard() {
    if (_data == null) return const SizedBox.shrink();
    final summary = _data!['summary'] as Map<String, dynamic>? ?? {};
    final cleaningTasks = _data!['cleaningTasks'] as Map<String, dynamic>? ?? {};
    final zones = _data!['zones'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Admin Dashboard',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          childAspectRatio: 1.2,
          children: summary.entries.map((e) => _buildStatCard(
            e.key.replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' '),
            e.value,
          )).toList(),
        ),
        _buildCleaningStats(cleaningTasks),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...zones.map((z) => ListTile(
          leading: const Icon(Icons.map, color: Colors.blue),
          title: Text(z['zoneName'] ?? 'Zone'),
          subtitle: Text('${z['stationCount'] ?? 0} stations'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToLevel('zone', z['zoneId'], z['zoneName'] ?? 'Zone'),
        )),
      ],
    );
  }

  Widget _buildZoneDashboard() {
    if (_data == null) return const SizedBox.shrink();
    final stations = _data!['stations'] as List<dynamic>? ?? [];
    final zoneName = _data!['zoneName'] ?? 'Zone';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zone: $zoneName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${_data!['stationCount'] ?? 0} stations',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        ...stations.map((s) {
          final todayTasks = s['todayTasks'] as Map<String, dynamic>? ?? {};
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: Text(s['stationName'] ?? s['stationCode'] ?? 'Station'),
              subtitle: Text('Platforms: ${s['platformCount'] ?? 0} | Tasks today: ${todayTasks['total'] ?? 0}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (todayTasks['pending'] != null && todayTasks['pending'] > 0)
                    Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: Text('${todayTasks['pending']}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _navigateToLevel('station', s['stationId'], s['stationName'] ?? 'Station'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStationDashboard() {
    if (_data == null) return const SizedBox.shrink();
    final scorecard = _data!['scorecard'] as Map<String, dynamic>? ?? {};
    final attendance = _data!['attendance'] as Map<String, dynamic>? ?? {};
    final feedback = _data!['feedback'] as Map<String, dynamic>? ?? {};
    final cleaning = _data!['cleaning'] as Map<String, dynamic>? ?? {};
    final platforms = _data!['platforms'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Station: ${_data!['stationName'] ?? _data!['stationCode'] ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          childAspectRatio: 1.3,
          children: [
            _buildStatCard('Avg Score', scorecard['averageScore'], icon: Icons.star, color: Colors.amber),
            _buildStatCard('Attendance', '${attendance['attendanceRate'] ?? 0}%', icon: Icons.people, color: Colors.teal),
            _buildStatCard('Rating', feedback['averageRating'], icon: Icons.thumb_up, color: Colors.green),
            _buildStatCard('Complaints', (_data!['complaints'] as Map)['open'] ?? 0, icon: Icons.report, color: Colors.red),
          ],
        ),
        _buildCleaningStats(cleaning),
        if (platforms.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Platforms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...platforms.map((p) => ListTile(
            leading: const Icon(Icons.subway, color: Colors.blueGrey),
            title: Text(p['platformName'] ?? p['platformNumber'] ?? 'Platform'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToLevel('platform', p['platformId'], p['platformName'] ?? 'Platform'),
          )),
        ],
      ],
    );
  }

  Widget _buildPlatformDashboard() {
    if (_data == null) return const SizedBox.shrink();
    final cleaning = _data!['cleaning'] as Map<String, dynamic>? ?? {};
    final areas = _data!['areas'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform: ${_data!['platformName'] ?? _data!['platformNumber'] ?? ''}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${_data!['areaCount'] ?? 0} areas | ${_data!['runCount'] ?? 0} runs today',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        _buildCleaningStats(cleaning),
        if (areas.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Areas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...areas.map((a) => ListTile(
            leading: const Icon(Icons.cleaning_services, color: Colors.lightBlue),
            title: Text(a['areaName'] ?? a['name'] ?? 'Area'),
            subtitle: Text('Freq: ${a['cleaningFrequency'] ?? a['frequency'] ?? '-'} | Shift: ${a['defaultShift'] ?? '-'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToLevel('area', a['areaId'] ?? a['id'], a['areaName'] ?? 'Area'),
          )),
        ],
      ],
    );
  }

  Widget _buildAreaDashboard() {
    if (_data == null) return const SizedBox.shrink();
    final cleaning = _data!['cleaning'] as Map<String, dynamic>? ?? {};
    final tasks = _data!['scheduledTasks'] as List<dynamic>? ?? [];
    final workers = _data!['workers'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Area: ${_data!['areaName'] ?? ''}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Code: ${_data!['areaCode'] ?? '-'} | Freq: ${_data!['cleaningFrequency'] ?? '-'} | Shift: ${_data!['defaultShift'] ?? '-'}',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text('Workers: ${_data!['workerCount'] ?? 0} | Priority: ${_data!['priority'] ?? 3}',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        _buildCleaningStats(cleaning),
        if (workers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Assigned Workers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...workers.map((w) => ListTile(
            leading: CircleAvatar(child: Text((w['workerName'] ?? '?')[0])),
            title: Text(w['workerName'] ?? 'Unknown'),
            subtitle: Text('Shift: ${w['shift'] ?? '-'} ${w['isPrimary'] == true ? '(Primary)' : ''}'),
          )),
        ],
        if (tasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Scheduled Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...tasks.map((t) {
            final status = t['status'] ?? 'pending';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                dense: true,
                leading: Icon(
                  status == 'completed' || status == 'approved' ? Icons.check_circle : Icons.schedule,
                  color: _taskColor(status),
                ),
                title: Text('${t['scheduledTime'] ?? '--:--'} - ${t['workerName'] ?? ''}'),
                subtitle: Text('Status: $status'),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _navigateToLevel(String level, String levelId, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HierarchicalDashboardScreen(initialLevel: level, levelId: levelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentLevel?.toUpperCase()} Dashboard'),
        actions: [
          if (_currentLevel != 'admin')
            TextButton.icon(
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              label: const Text('Up', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    child: _buildBody(),
                  ),
                ),
    );
  }

  Widget _buildBody() {
    switch (_currentLevel) {
      case 'admin':
        return _buildAdminDashboard();
      case 'zone':
        return _buildZoneDashboard();
      case 'station':
        return _buildStationDashboard();
      case 'platform':
        return _buildPlatformDashboard();
      case 'area':
        return _buildAreaDashboard();
      default:
        return const Center(child: Text('Unknown dashboard level'));
    }
  }
}
