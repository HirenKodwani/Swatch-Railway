import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/model/platform_model.dart';
import 'package:crm_train/repositories/platform_repository.dart';
import 'package:crm_train/model/station_run_model.dart';
import 'package:crm_train/repositories/station_run_repository.dart';
import 'package:crm_train/repositories/obhs_repository.dart';
import 'package:crm_train/repositories/area_cleaning_repository.dart';
import 'package:crm_train/model/railway_worker_model.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/model/task_type_model.dart';
import 'package:crm_train/repositories/task_type_repository.dart';
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
  List<Platform> _platforms = [];
  List<StationArea> _allAreas = [];
  List<RailwayWorkerModel> _workers = [];
  List<RailwayWorkerModel> _supervisors = [];
  List<TaskType> _taskTypes = [];

  Station? _selectedStation;
  Platform? _selectedPlatform; // Null means "All Platforms"
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  String _selectedFrequency = 'daily';
  RailwayWorkerModel? _selectedSupervisor;
  TaskType? _selectedActivity;

  String? _assignedPlatformId;
  bool _isStationLocked = false;
  bool _isPlatformLocked = false;

  // Selected areas and worker assignments
  final Set<String> _selectedAreaIds = {};
  final Map<String, List<RailwayWorkerModel>> _areaWorkerAssignments = {};
  final Map<String, List<TaskType>> _areaActivities = {};

  String? _loadError;
  bool _areaLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final role = user?.role ?? '';
      
      final assignedPlatformId = (user?.areaId != null && user!.areaId!.isNotEmpty)
          ? user.areaId
          : user?.platformId;

      List<Station> filtered = [];
      bool stationLocked = false;
      try {
        final stData = await ApiService.getStations(active: true);
        if (widget.stationId != null) {
          filtered = stData.where((s) => s.uid == widget.stationId).toList();
          stationLocked = true;
        } else if (role == 'Contractor Admin' || role == 'Contractor Master') {
          final userStationIds = <String>{};
          if (user?.stationId != null && user!.stationId!.isNotEmpty) {
            userStationIds.add(user.stationId!);
          }
          if (user?.stations != null && user!.stations.isNotEmpty) {
            userStationIds.addAll(user.stations);
          }
          if (userStationIds.isNotEmpty) {
            filtered = stData.where((s) => s.uid != null && userStationIds.contains(s.uid)).toList();
            stationLocked = true;
          } else {
            filtered = stData;
          }
        } else {
          filtered = stData;
        }
      } catch (e) {
        debugPrint('Error loading stations: $e');
        if (mounted) {
          setState(() => _loadError = 'Failed to load stations. Check your connection and try again.');
        }
      }

      List<RailwayWorkerModel> uniqueWorkers = [];
      try {
        final wkData = await OBHSRepository.getWorkers();
        final seen = <String>{};
        uniqueWorkers = wkData.where((w) => seen.add(w.uid)).toList();
      } catch (e) {
        debugPrint('Error loading workers: $e');
      }

      List<TaskType> cleaningTypes = [];
      try {
        final taskTypes = await TaskTypeRepository.list(isActive: true);
        cleaningTypes = taskTypes.where((t) => t.category == 'cleaning' || t.category.isEmpty).toList();
        if (cleaningTypes.isEmpty) cleaningTypes = taskTypes;
      } catch (e) {
        debugPrint('Error loading task types: $e');
      }

      // Load only Contractor Supervisors (approved, real users)
      final supList = uniqueWorkers.where((w) {
        final role = w.role.toLowerCase().replaceAll('_', ' ');
        return role.contains('contractor supervisor') && w.status == 'APPROVED';
      }).toList();

      if (mounted) {
        setState(() {
          _stations = filtered;
          _workers = uniqueWorkers;
          _supervisors = supList;
          _taskTypes = cleaningTypes;
          _assignedPlatformId = assignedPlatformId;
          _isPlatformLocked = false;
          _isStationLocked = stationLocked;
          if (_stations.isNotEmpty) {
            if (widget.stationId != null) {
              _selectedStation = _stations.where((s) => s.uid == widget.stationId).firstOrNull ?? _stations.first;
            } else if (user?.stationId != null && user!.stationId!.isNotEmpty) {
              _selectedStation = _stations.where((s) => s.uid == user.stationId).firstOrNull;
            }
            _selectedStation ??= _stations.first;
          }
        });
        if (_selectedStation != null) {
          await _loadStationData(_selectedStation!.uid!);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStationData(String stationId) async {
    await Future.wait([_loadPlatforms(stationId), _loadAreas(stationId)]);
  }

  Future<void> _loadPlatforms(String stationId) async {
    try {
      final platforms = await PlatformRepository.getByStation(stationId);
      if (mounted) {
        setState(() {
          _platforms = platforms;
          if (_isPlatformLocked && _assignedPlatformId != null && _assignedPlatformId!.isNotEmpty) {
            _selectedPlatform = _platforms.where((p) => p.uid == _assignedPlatformId).firstOrNull;
          } else {
            _selectedPlatform = null;
          }
          _selectedAreaIds.clear();
          _areaWorkerAssignments.clear();
          _areaActivities.clear();
        });
      }
    } catch (e) {
      debugPrint('Error loading platforms: $e');
      if (mounted) {
        setState(() {
          _platforms = [];
          _selectedPlatform = null;
          _isPlatformLocked = false;
        });
      }
    }
  }

  Future<void> _loadAreas(String stationId) async {
    try {
      final areas = await ApiService.getStationAreas(stationId);
      if (mounted) {
        setState(() {
          _allAreas = areas;
          _areaLoadFailed = false;
          _selectedAreaIds.clear();
          _areaWorkerAssignments.clear();
          _areaActivities.clear();
        });
      }
    } catch (e) {
      debugPrint('Error loading areas: $e');
      if (mounted) {
        setState(() {
          _allAreas = [];
          _areaLoadFailed = true;
          _selectedAreaIds.clear();
          _areaWorkerAssignments.clear();
          _areaActivities.clear();
        });
      }
    }
  }

  List<StationArea> get _filteredAreas {
    if (_selectedPlatform == null) {
      return _allAreas;
    }
    return _allAreas.where((a) => a.platformId == _selectedPlatform!.uid).toList();
  }

  String _getPlatformName(String? platformId) {
    if (platformId == null || platformId.isEmpty) return 'Entire Station';
    final plat = _platforms.where((p) => p.uid == platformId).firstOrNull;
    return plat?.displayName ?? 'Platform $platformId';
  }

  String _frequencyLabel(String f) {
    switch (f) {
      case 'daily': return 'Daily (1x)';
      case 'twice_daily': return 'Twice Daily (2x)';
      case 'shift_wise': return 'Shift Wise (3x)';
      case 'four_times_daily': return 'Four Times (4x)';
      case '4hrs': return 'Every 4 Hours (5x)';
      case 'hourly': return 'Hourly (17x)';
      case '2hrs': return 'Every 2 Hours';
      case 'weekly': return 'Weekly';
      case 'fortnightly': return 'Fortnightly';
      case 'monthly': return 'Monthly';
      default: return f;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _showWorkerSelectionForArea(StationArea area) async {
    final areaId = area.uid ?? area.name;
    final currentAssigned = _areaWorkerAssignments[areaId] ?? [];
    final selectedWorkers = List<RailwayWorkerModel>.from(currentAssigned);

    // Show only actual workers (exclude supervisors) so the supervisor can
    // manually assign them per area. Unassigned workers (no station/depot)
    // are offered so they can be assigned to any station.
    final availableWorkers = _workers.where((w) {
      final role = w.role.toLowerCase().replaceAll('_', ' ');
      if (role.contains('supervisor')) return false;
      if (_selectedStation == null) return true;
      if (w.stationId == _selectedStation!.uid) return true;
      if (w.depot != null && w.depot!.isNotEmpty) {
        final sName = _selectedStation!.stationName.toLowerCase();
        final wDepot = w.depot!.toLowerCase();
        if (sName.contains(wDepot) || wDepot.contains(sName)) return true;
      }
      final wStationId = w.stationId ?? '';
      final wDepot = w.depot ?? '';
      return wStationId.isEmpty && wDepot.isEmpty;
    }).toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign Workers: ${area.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select one or more workers for this area.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: availableWorkers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No workers available for this station.',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableWorkers.length,
                              itemBuilder: (context, index) {
                                final worker = availableWorkers[index];
                                final isSelected = selectedWorkers.any((w) => w.uid == worker.uid);
                                return CheckboxListTile(
                                  title: Text(worker.fullName),
                                  subtitle: Text(worker.role),
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
                      if (selectedWorkers.isEmpty) {
                        _areaWorkerAssignments.remove(areaId);
                        _selectedAreaIds.remove(areaId);
                      } else {
                        _areaWorkerAssignments[areaId] = selectedWorkers;
                        _selectedAreaIds.add(areaId);
                      }
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

  void _toggleAreaSelection(StationArea area) {
    final areaId = area.uid ?? area.name;
    if (_selectedAreaIds.contains(areaId)) {
      setState(() {
        _selectedAreaIds.remove(areaId);
        _areaWorkerAssignments.remove(areaId);
        _areaActivities.remove(areaId);
      });
      return;
    }
    _pickActivities(area).then((picked) {
      if (picked == null || picked.isEmpty) return;
      setState(() {
        _selectedAreaIds.add(areaId);
        _areaWorkerAssignments[areaId] = [];
        _areaActivities[areaId] = picked;
      });
    });
  }

  Future<void> _changeActivity(StationArea area) async {
    final picked = await _pickActivities(area);
    if (picked == null || picked.isEmpty) return;
    setState(() {
      _areaActivities[area.uid ?? area.name] = picked;
    });
  }

  String _activityLabel(String areaId) {
    final list = _areaActivities[areaId];
    if (list != null && list.isNotEmpty) {
      return list.map((t) => t.label).join(', ');
    }
    final tt = _selectedActivity;
    return tt != null ? tt.label : 'Cleaning';
  }

  Future<List<TaskType>?> _pickActivities(StationArea area) async {
    final areaId = area.uid ?? area.name;
    final current = List<TaskType>.from(_areaActivities[areaId] ?? []);
    if (_taskTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No activities configured. Add them under Task Master first.'), backgroundColor: kWarningOrange),
      );
      return null;
    }
    return showDialog<List<TaskType>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = List<TaskType>.from(current);
          return AlertDialog(
            title: Text('Select Activities: ${area.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select one or more cleaning activities for this area.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _taskTypes.length,
                      itemBuilder: (context, index) {
                        final tt = _taskTypes[index];
                        final isSelected = selected.any((t) => t.uid == tt.uid || t.name == tt.name);
                        return CheckboxListTile(
                          title: Text(tt.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(tt.name),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                if (!selected.any((t) => t.uid == tt.uid || t.name == tt.name)) {
                                  selected.add(tt);
                                }
                              } else {
                                selected.removeWhere((t) => t.uid == tt.uid || t.name == tt.name);
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
                  Navigator.pop(context, selected);
                },
                style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                child: const Text('Select'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateTasks() async {
    if (_selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a station')));
      return;
    }
    if (_selectedAreaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one area')));
      return;
    }

    // Check if worker overrides are needed or individual assignments are valid
    final List<StationPlatformAssignment> platformAssignments = [];

    for (final areaId in _selectedAreaIds) {
      final area = _allAreas.where((a) => (a.uid ?? a.name) == areaId).firstOrNull;
      if (area == null) continue;
      final platformName = _getPlatformName(area.platformId);

      final workersToAssign = _areaWorkerAssignments[areaId] ?? [];

      for (final worker in workersToAssign) {
        platformAssignments.add(StationPlatformAssignment(
          platformNumber: platformName.replaceAll('Platform ', '').trim(),
          areaId: area.uid,
          areaName: area.name,
          janitorId: worker.uid,
          janitorName: worker.fullName,
        ));
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final runInstanceId = '${_selectedStation!.uid}_${_selectedShift.toLowerCase()}_$todayStr';

      final run = StationCleaningRunModel(
        runInstanceId: runInstanceId,
        stationId: _selectedStation!.uid ?? '',
        stationName: _selectedStation!.stationName,
        shift: _selectedShift,
        date: todayStr,
        status: 'Pending',
        platforms: platformAssignments,
      );

      // Save run instance
      await StationRunRepository.createStationRun(run);

      // Trigger task generation via repository
      final areaIds = platformAssignments.isNotEmpty
          ? platformAssignments.map((pa) => pa.areaId).whereType<String>().toSet().toList()
          : _selectedAreaIds.toList();
      final workerIds = platformAssignments.map((pa) => pa.janitorId).whereType<String>().toSet().toList();
      final areaActivities = <String, dynamic>{};
      for (final entry in _areaActivities.entries) {
        areaActivities[entry.key] = entry.value.map((tt) => {
          'uid': tt.uid,
          'name': tt.name,
          'label': tt.label,
        }).toList();
      }
      await AreaCleaningRepository.generateTasks(
        areaIds: areaIds,
        date: todayStr,
        workerIds: workerIds.isNotEmpty ? workerIds : null,
        supervisorId: _selectedSupervisor?.uid,
        frequency: _selectedFrequency,
        activityType: _selectedActivity?.name,
        taskTypeId: _selectedActivity?.uid,
        taskTypeName: _selectedActivity?.name,
        areaActivities: areaActivities.isNotEmpty ? areaActivities : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasks generated successfully!'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating tasks: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = _filteredAreas;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Generate Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_stations.isEmpty)
              ? _LoadFailureView(
                  message: _loadError ?? 'No stations available for your account.',
                  onRetry: () {
                    _loadInitialData();
                  },
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Location & Schedule Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.map, color: kRailwayBlue, size: 20),
                              const SizedBox(width: 8),
                              const Text('Location & Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Station Dropdown
                          DropdownButtonFormField<Station>(
                            value: _selectedStation,
                            decoration: InputDecoration(
                              labelText: 'Station',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.business),
                              hintText: _isStationLocked ? 'Assigned Station (locked)' : null,
                            ),
                            items: _stations.map((s) => DropdownMenuItem(value: s, child: Text(s.stationName))).toList(),
                            onChanged: _isStationLocked ? null : (v) async {
                              if (v != null) {
                                setState(() {
                                  _selectedStation = v;
                                  _selectedAreaIds.clear();
                                  _areaWorkerAssignments.clear();
                                  _areaActivities.clear();
                                });
                                await _loadStationData(v.uid!);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Date & Shift side by side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                                    child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedShift,
                                  decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), prefixIcon: Icon(Icons.schedule)),
                                  items: ['Morning', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedShift = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Cleaning Setup Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cleaning_services, color: kRailwayBlue, size: 20),
                              const SizedBox(width: 8),
                              const Text('Cleaning Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Frequency Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedFrequency,
                            decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(), prefixIcon: Icon(Icons.repeat)),
                            items: const [
                              DropdownMenuItem(value: 'daily', child: Text('Daily (1x)')),
                              DropdownMenuItem(value: 'twice_daily', child: Text('Twice Daily (2x)')),
                              DropdownMenuItem(value: 'shift_wise', child: Text('Shift Wise (3x)')),
                              DropdownMenuItem(value: 'four_times_daily', child: Text('Four Times (4x)')),
                              DropdownMenuItem(value: '4hrs', child: Text('Every 4hrs (5x)')),
                              DropdownMenuItem(value: 'hourly', child: Text('Hourly (17x)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedFrequency = v);
                            },
                          ),
                          const SizedBox(height: 12),

                          // Activity (Cleaning Task Type) Dropdown - default applied to all areas
                          DropdownButtonFormField<TaskType>(
                            value: _taskTypes.isEmpty ? null : _selectedActivity,
                            decoration: const InputDecoration(labelText: 'Default Activity', border: OutlineInputBorder(), prefixIcon: Icon(Icons.checklist), hintText: 'Cleaning (default)'),
                            items: [
                              const DropdownMenuItem<TaskType>(value: null, child: Text('Cleaning (default)')),
                              ..._taskTypes.map((tt) => DropdownMenuItem(value: tt, child: Text(tt.label))),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedActivity = v);
                            },
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'Per-area activities can be set after selecting an area.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Supervisor Assignment
                          DropdownButtonFormField<RailwayWorkerModel>(
                            value: _selectedSupervisor,
                            decoration: const InputDecoration(
                              labelText: 'Assign to Supervisor (optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.supervisor_account),
                            ),
                            items: [
                              const DropdownMenuItem<RailwayWorkerModel>(
                                value: null,
                                child: Text('None'),
                              ),
                              ..._supervisors.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.fullName),
                              )),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedSupervisor = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Select Areas Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dashboard_outlined, color: kRailwayBlue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Select Areas (${_selectedAreaIds.length} selected)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap an area to choose its activities. Then assign workers (and set per-area activities) using the buttons on the selected card.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          if (areas.isEmpty)
                            _areaLoadFailed
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Failed to load areas. Please retry.',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton.icon(
                                            onPressed: () => _loadAreas(_selectedStation?.uid ?? ''),
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24),
                                      child: Text('No areas configured for this selection', style: TextStyle(color: Colors.grey)),
                                    ),
                                  )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: areas.length,
                              itemBuilder: (context, index) {
                                final area = areas[index];
                                final areaId = area.uid ?? area.name;
                                final isSelected = _selectedAreaIds.contains(areaId);
                                
                                final List<RailwayWorkerModel> assigned = _areaWorkerAssignments[areaId] ?? [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _toggleAreaSelection(area),
                                    style: OutlinedButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      side: BorderSide(color: isSelected ? kRailwayBlue : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      backgroundColor: isSelected ? kRailwayBlue.withOpacity(0.04) : Colors.white,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                            color: isSelected ? kRailwayBlue : Colors.grey.shade400,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (area.mainArea != null && area.mainArea!.isNotEmpty)
                                                Text(
                                                  area.mainArea!,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                              if (area.mainArea != null && area.mainArea!.isNotEmpty)
                                                const SizedBox(height: 2),
                                              Text(
                                                area.name,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _frequencyLabel(area.cleaningFrequency ?? 'daily'),
                                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                               const SizedBox(height: 4),
                                               Row(
                                                 children: [
                                                   Icon(Icons.cleaning_services, size: 14, color: isSelected ? kRailwayBlue : Colors.grey[500]),
                                                   const SizedBox(width: 4),
                                                   Expanded(
                                                     child: Text(
                                                       _activityLabel(areaId),
                                                       style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? kRailwayBlue : Colors.grey[600]),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               if (isSelected && assigned.isNotEmpty) ...[
                                                 const SizedBox(height: 4),
                                                 Row(
                                                   children: [
                                                     Icon(Icons.people, size: 14, color: kRailwayBlue),
                                                     const SizedBox(width: 4),
                                                     Expanded(
                                                       child: Text(
                                                         '${assigned.length} worker${assigned.length > 1 ? 's' : ''} · ${assigned.map((w) => w.fullName).take(3).join(', ')}${assigned.length > 3 ? '…' : ''}',
                                                         style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                               ],
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          IconButton(
                                            icon: const Icon(Icons.cleaning_services, size: 20, color: kRailwayBlue),
                                            tooltip: 'Change Activities',
                                            onPressed: () => _changeActivity(area),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        if (isSelected)
                                          IconButton(
                                            icon: const Icon(Icons.person_add_alt_1, size: 20, color: kRailwayBlue),
                                            onPressed: () => _showWorkerSelectionForArea(area),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate Tasks Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _generateTasks,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isSubmitting ? 'Generating...' : '+ Generate Tasks (${_selectedAreaIds.length} areas)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRailwayBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LoadFailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadFailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
