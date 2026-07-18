import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/model/station_run_model.dart';
import 'package:crm_train/repositories/station_run_repository.dart';
import 'package:crm_train/repositories/obhs_repository.dart';
import 'package:crm_train/model/railway_worker_model.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:intl/intl.dart';

class TaskGenerationScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;
  const TaskGenerationScreen({super.key, this.stationId, this.stationName});

  @override
  State<TaskGenerationScreen> createState() => _TaskGenerationScreenState();
}

class _TaskGenerationScreenState extends State<TaskGenerationScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<Station> _stations = [];
  List<StationArea> _platforms = [];
  List<RailwayWorkerModel> _workers = [];

  Station? _selectedStation;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';

  final List<StationPlatformAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final role = user?.role ?? '';
      final stData = await ApiService.getStations(active: true);
      List<Station> filtered = stData;
      if (widget.stationId != null) {
        filtered = stData.where((s) => s.uid == widget.stationId).toList();
      } else if (role == 'Station Master' || role == 'Area Master' || role == 'Platform Master') {
        if (user?.stationId != null && user!.stationId!.isNotEmpty) {
          filtered = stData.where((s) => s.uid == user.stationId).toList();
        }
      }
      final wkData = await OBHSRepository.getWorkers();
      final seen = <String>{};
      final uniqueWorkers = wkData.where((w) => seen.add(w.uid)).toList();
      if (mounted) {
        setState(() {
          _stations = filtered;
          _workers = uniqueWorkers;
          if (_stations.isNotEmpty) _selectedStation = _stations.first;
        });
        if (_selectedStation != null) {
          await _loadPlatforms(_selectedStation!.uid!);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlatforms(String stationId) async {
    try {
      final areas = await ApiService.getStationAreas(stationId);
      if (mounted) {
        setState(() {
          final seen = <String>{};
          _platforms = areas.where((a) => a.name.toLowerCase().contains('platform')).where((a) {
            final id = a.uid ?? a.name;
            if (seen.contains(id)) return false;
            seen.add(id);
            return true;
          }).toList();
          if (_platforms.isEmpty) {
            _platforms = [
              StationArea(uid: 'fallback_p1_$stationId', stationId: stationId, name: 'Platform 1'),
              StationArea(uid: 'fallback_p2_$stationId', stationId: stationId, name: 'Platform 2'),
            ];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _platforms = [
            StationArea(uid: 'fallback_p1_$stationId', stationId: stationId, name: 'Platform 1'),
            StationArea(uid: 'fallback_p2_$stationId', stationId: stationId, name: 'Platform 2'),
          ];
        });
      }
    }
  }

  void _addPlatformAssignment(StationArea platform) {
    if (_assignments.any((a) => a.platformNumber == platform.name)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platform already added')));
      return;
    }
    setState(() {
      _assignments.add(StationPlatformAssignment(platformNumber: platform.name, janitorId: '', janitorName: ''));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _generateTasks() async {
    if (_selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a station')));
      return;
    }
    if (_assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign at least one platform with a worker')));
      return;
    }
    final incomplete = _assignments.where((a) => a.janitorId.isEmpty);
    if (incomplete.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign a worker for all platforms')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final run = StationCleaningRunModel(
        runInstanceId: 'SCR-${DateTime.now().millisecondsSinceEpoch}',
        stationId: _selectedStation!.uid ?? '',
        stationName: _selectedStation!.stationName,
        shift: _selectedShift,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        status: 'active',
        platforms: _assignments,
      );
      await StationRunRepository.createStationRun(run);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Station run generated successfully!'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Generate Station Run', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          // 1. Station
                          DropdownButtonFormField<Station>(
                            value: _selectedStation,
                            decoration: const InputDecoration(labelText: 'Station', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                            items: _stations.map((s) => DropdownMenuItem(value: s, child: Text(s.stationName))).toList(),
                            onChanged: _stations.length == 1 ? null : (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedStation = v;
                                  _assignments.clear();
                                });
                                _loadPlatforms(v.uid!);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          // 2. Platform
                          if (_selectedStation != null)
                            DropdownButtonFormField<StationArea>(
                              key: ValueKey('platform_dropdown_${_selectedStation!.uid}'),
                              decoration: const InputDecoration(labelText: 'Add Platform', border: OutlineInputBorder(), prefixIcon: Icon(Icons.view_quilt)),
                              items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                              onChanged: (v) { if (v != null) _addPlatformAssignment(v); },
                            ),
                          const SizedBox(height: 12),
                          // 3. Date
                          InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                              child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 4. Shift
                          DropdownButtonFormField<String>(
                            value: _selectedShift,
                            decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), prefixIcon: Icon(Icons.schedule)),
                            items: ['Morning', 'Afternoon', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedShift = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 5. Workers/Areas assignments
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Platform & Worker Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          ..._assignments.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final a = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Platform: ${a.platformNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => setState(() => _assignments.removeAt(idx)),
                                        ),
                                      ],
                                    ),
                                    DropdownButtonFormField<RailwayWorkerModel>(
                                      key: ValueKey('worker_${idx}_${a.platformNumber}'),
                                      value: a.janitorId.isEmpty
                                          ? null
                                          : (_workers.any((w) => w.uid == a.janitorId)
                                              ? _workers.firstWhere((w) => w.uid == a.janitorId)
                                              : null),
                                      decoration: const InputDecoration(labelText: 'Assign Worker', border: OutlineInputBorder()),
                                      items: _workers.map((w) => DropdownMenuItem(value: w, child: Text('${w.fullName} (${w.role})'))).toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() {
                                            _assignments[idx] = StationPlatformAssignment(
                                              platformNumber: a.platformNumber,
                                              janitorId: v.uid,
                                              janitorName: v.fullName,
                                              status: a.status,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (_assignments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('Add platforms above to assign workers', style: TextStyle(color: Colors.grey[500])),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _generateTasks,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isSubmitting ? 'Generating...' : 'Create Station Run'),
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
