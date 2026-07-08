import 'dart:convert';
import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/execution_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkerDailyTasksScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  const WorkerDailyTasksScreen({super.key, required this.workerId, required this.workerName});

  @override
  State<WorkerDailyTasksScreen> createState() => _WorkerDailyTasksScreenState();
}

class _WorkerDailyTasksScreenState extends State<WorkerDailyTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = true;
  String? _assignedShift;
  String? _stationId;
  List<Map<String, dynamic>> _areas = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      int month = now.month;
      int year = now.year;

      final plans = await ExecutionRepository.listPlans({
        'workerId': widget.workerId,
        'month': month.toString(),
        'year': year.toString(),
      });

      ExecutionPlan? myPlan;
      for (final p in plans) {
        if (p.status == 'APPROVED' || p.status == 'SUBMITTED') {
          final morning = p.shiftPlan['morning'];
          final afternoon = p.shiftPlan['afternoon'];
          final night = p.shiftPlan['night'];

          if (morning is List && morning.contains(widget.workerId)) myPlan = p;
          if (afternoon is List && afternoon.contains(widget.workerId)) myPlan = p;
          if (night is List && night.contains(widget.workerId)) myPlan = p;

          if (myPlan != null) {
            if (morning is List && morning.contains(widget.workerId)) _assignedShift = 'Morning';
            else if (afternoon is List && afternoon.contains(widget.workerId)) _assignedShift = 'Afternoon';
            else if (night is List && night.contains(widget.workerId)) _assignedShift = 'Night';
            _stationId = myPlan.stationId;
            break;
          }
        }
      }

      if (_stationId != null) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final areaRes = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/areas/by-station/$_stationId'),
          headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
        );
        if (areaRes.statusCode == 200) {
          final data = jsonDecode(areaRes.body);
          _areas = List<Map<String, dynamic>>.from(data['areas'] ?? []);
        }
      }

    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _areasForShift(String shift) {
    if (_assignedShift != null && _assignedShift!.toLowerCase() != shift) return [];
    final areas = _areas.where((a) {
      final sc = (a['shiftConsidered'] as String? ?? '').toLowerCase();
      if (sc.contains('four') && shift == 'morning') return true;
      if (sc.contains('two') && shift == 'afternoon') return true;
      if (sc.contains('three') && shift == 'morning') return true;
      if (sc.contains('six') || sc.contains('eight') || sc.contains('twenty')) return true;
      return sc.contains('once') || sc.contains('one');
    }).toList();
    if (areas.isEmpty && _areas.isNotEmpty) return _areas.take(5).toList();
    return areas;
  }

  Color _freqColor(String freq) {
    if (freq.contains('4') || freq.contains('four')) return Colors.red;
    if (freq.contains('2') || freq.contains('two')) return kWarningOrange;
    if (freq.contains('1') || freq.contains('one')) return kSuccessGreen;
    if (freq.contains('month')) return Colors.purple;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workerName}\'s Tasks', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Morning', icon: Icon(Icons.wb_sunny, size: 18)),
            Tab(text: 'Afternoon', icon: Icon(Icons.cloud, size: 18)),
            Tab(text: 'Night', icon: Icon(Icons.nights_stay, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedShift == null
              ? const Center(child: Text('No tasks assigned for this month'))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: kSuccessGreen.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: kSuccessGreen, size: 20),
                          const SizedBox(width: 8),
                          Text('Assigned: $_assignedShift Shift',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: ['morning', 'afternoon', 'night'].map((shift) {
                          final shiftAreas = _areasForShift(shift);
                          if (shiftAreas.isEmpty) {
                            return const Center(child: Text('No areas assigned for this shift'));
                          }
                          return RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: shiftAreas.length + 1,
                              itemBuilder: (ctx, i) {
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('${shiftAreas.length} areas to clean',
                                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                  );
                                }
                                final area = shiftAreas[i - 1];
                                final name = area['areaName'] ?? '';
                                final surface = area['surfaceType'] ?? '';
                                final freq = area['shiftConsidered'] ?? '';
                                final sqft = area['tenderedAreaPerDay']?.toString() ?? '';

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _freqColor(freq.toString()).withOpacity(0.2),
                                      child: Icon(Icons.cleaning_services,
                                        color: _freqColor(freq.toString()), size: 20),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('$surface • $freq',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    trailing: sqft.isNotEmpty
                                        ? Text('${sqft}sqft', style: TextStyle(color: Colors.grey[500], fontSize: 11))
                                        : null,
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
