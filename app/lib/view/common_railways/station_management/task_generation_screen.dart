import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/model/platform_model.dart';
import 'package:crm_train/repositories/platform_repository.dart';
import 'package:crm_train/model/station_run_model.dart';
import 'package:crm_train/repositories/station_run_repository.dart';
import 'package:crm_train/repositories/obhs_repository.dart';
import 'package:crm_train/model/railway_worker_model.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:intl/intl.dart';

class LocalAssignment {
  final String platformNumber;
  final String? platformId;
  final StationArea? area; // Null means Entire Platform
  List<RailwayWorkerModel> workers;

  LocalAssignment({
    required this.platformNumber,
    this.platformId,
    this.area,
    List<RailwayWorkerModel>? workers,
  }) : workers = workers ?? [];
}

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
  List<Platform> _platforms = [];
  List<StationArea> _allAreas = [];
  List<RailwayWorkerModel> _workers = [];

  Station? _selectedStation;
  Platform? _selectedPlatform;
  StationArea? _selectedArea;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  String _selectedFrequency = 'daily';

  final List<LocalAssignment> _assignments = [];

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
      final platforms = await PlatformRepository.getByStation(stationId);
      final areas = await ApiService.getStationAreas(stationId);
      if (mounted) {
        setState(() {
          _platforms = platforms;
          _allAreas = areas;
          if (_platforms.isEmpty) {
            _platforms = [
              Platform(uid: 'fallback_p1_$stationId', platformNumber: '1', stationId: stationId, platformName: 'Platform 1'),
              Platform(uid: 'fallback_p2_$stationId', platformNumber: '2', stationId: stationId, platformName: 'Platform 2'),
            ];
          }
          _selectedPlatform = _platforms.first;
          _selectedArea = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading platforms: $e');
      if (mounted) {
        setState(() {
          _platforms = [
            Platform(uid: 'fallback_p1_$stationId', platformNumber: '1', stationId: stationId, platformName: 'Platform 1'),
            Platform(uid: 'fallback_p2_$stationId', platformNumber: '2', stationId: stationId, platformName: 'Platform 2'),
          ];
          _selectedPlatform = _platforms.first;
          _selectedArea = null;
        });
      }
    }
  }

  void _addLocalAssignment() {
    if (_selectedPlatform == null) return;

    final platName = _selectedPlatform!.displayName;
    final areaName = _selectedArea?.name;

    final isDuplicate = _assignments.any((a) =>
        a.platformId == _selectedPlatform!.uid &&
        a.area?.uid == _selectedArea?.uid);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedArea != null ? areaName : platName} already added to assignments.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _assignments.add(LocalAssignment(
        platformNumber: _selectedPlatform!.platformNumber,
        platformId: _selectedPlatform!.uid,
        area: _selectedArea,
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign at least one platform/area')));
      return;
    }

    final List<StationPlatformAssignment> apiAssignments = [];
    for (final assign in _assignments) {
      if (assign.workers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please assign at least one worker for ${assign.area != null ? assign.area!.name : "Platform " + assign.platformNumber}',
            ),
          ),
        );
        return;
      }
      for (final worker in assign.workers) {
        apiAssignments.add(StationPlatformAssignment(
          platformNumber: assign.platformNumber,
          areaId: assign.area?.uid,
          areaName: assign.area?.name,
          janitorId: worker.uid,
          janitorName: worker.fullName ?? 'Worker',
        ));
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Auth token not available');
      final run = StationCleaningRunModel(
        runInstanceId: 'SCR-${DateTime.now().millisecondsSinceEpoch}',
        stationId: _selectedStation!.uid ?? '',
        stationName: _selectedStation!.stationName,
        shift: _selectedShift,
        frequency: _selectedFrequency,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        status: 'active',
        platforms: apiAssignments,
      );
      final resp = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/station-runs'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(run.toJson()),
      );
      final decoded = jsonDecode(resp.body);
      if (resp.statusCode == 201 && decoded['success'] == true) {
        final tasksCount = decoded['tasksCreated'] ?? 0;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Station run created! $tasksCount task(s) generated.'),
              backgroundColor: kSuccessGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(decoded['error'] ?? 'Failed to create run');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: kErrorRed));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showWorkerSelectionDialog(int assignmentIndex) async {
    final assignment = _assignments[assignmentIndex];
    final selectedWorkers = List<RailwayWorkerModel>.from(assignment.workers);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Workers', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select one or more workers to assign to this platform/area.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _workers.length,
                        itemBuilder: (context, index) {
                          final worker = _workers[index];
                          final isSelected = selectedWorkers.any((w) => w.uid == worker.uid);
                          return CheckboxListTile(
                            title: Text(worker.fullName ?? 'Unknown'),
                            subtitle: Text(worker.role ?? ''),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  if (!selectedWorkers.any((w) => w.uid == worker.uid)) {
                                    selectedWorkers.add(worker);
                                  }
                                } else {
                                  selectedWorkers.removeWhere((w) => w.uid == worker.uid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _assignments[assignmentIndex].workers = selectedWorkers;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
                          if (_selectedStation != null) ...[
                            DropdownButtonFormField<Platform>(
                              key: ValueKey('platform_dropdown_${_selectedStation!.uid}'),
                              decoration: const InputDecoration(labelText: 'Select Platform', border: OutlineInputBorder(), prefixIcon: Icon(Icons.view_quilt)),
                              value: _selectedPlatform,
                              items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedPlatform = v;
                                  _selectedArea = null;
                                });
                              },
                            ),
                            if (_selectedPlatform != null) ...[
                              const SizedBox(height: 12),
                              DropdownButtonFormField<StationArea?>(
                                key: ValueKey('area_dropdown_${_selectedPlatform!.uid}'),
                                decoration: const InputDecoration(labelText: 'Select Specific Area', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                                value: _selectedArea,
                                items: [
                                  const DropdownMenuItem<StationArea?>(
                                    value: null,
                                    child: Text('Entire Platform / All Areas'),
                                  ),
                                  ..._allAreas
                                      .where((a) => a.platformId == _selectedPlatform!.uid)
                                      .map((a) => DropdownMenuItem<StationArea?>(value: a, child: Text(a.name))),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedArea = v;
                                  });
                                },
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),
                          // Add platform/area button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _selectedPlatform == null ? null : _addLocalAssignment,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Platform / Area to Run'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kRailwayBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 12),
                          // 5. Frequency
                          DropdownButtonFormField<String>(
                            value: _selectedFrequency,
                            decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(), prefixIcon: Icon(Icons.repeat)),
                            items: const [
                              DropdownMenuItem(value: 'daily', child: Text('Daily')),
                              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedFrequency = v);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Platform: Platform ${a.platformNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              const SizedBox(height: 4),
                                              Text(
                                                a.area != null ? 'Area: ${a.area!.name}' : 'Area: Entire Platform',
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => setState(() => _assignments.removeAt(idx)),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    const SizedBox(height: 4),
                                    const Text('Assigned Workers:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    if (a.workers.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          'No workers assigned yet.',
                                          style: TextStyle(color: kErrorRed.withOpacity(0.8), fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: a.workers.map((w) {
                                          return Chip(
                                            label: Text(w.fullName ?? 'Worker', style: const TextStyle(fontSize: 11)),
                                            deleteIcon: const Icon(Icons.cancel, size: 14),
                                            onDeleted: () {
                                              setState(() {
                                                a.workers.remove(w);
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: Colors.blue.shade50,
                                            side: BorderSide(color: Colors.blue.shade100),
                                          );
                                        }).toList(),
                                      ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showWorkerSelectionDialog(idx),
                                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                                      label: const Text('Manage Workers'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kRailwayBlue,
                                        side: BorderSide(color: kRailwayBlue.withOpacity(0.5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (_assignments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment_ind_outlined, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text('No platforms or areas added yet.', style: TextStyle(color: Colors.grey[500])),
                                  ],
                                ),
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
