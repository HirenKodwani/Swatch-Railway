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

  Station? _selectedStation;
  Platform? _selectedPlatform; // Null means "All Platforms"
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  String _selectedFrequency = 'daily';
  RailwayWorkerModel? _selectedSupervisor;

  String? _assignedPlatformId;
  bool _isStationLocked = false;
  bool _isPlatformLocked = false;

  // Selected areas and worker assignments
  final Set<String> _selectedAreaIds = {};
  final Map<String, List<RailwayWorkerModel>> _areaWorkerAssignments = {};

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
      
      final assignedPlatformId = (user?.areaId != null && user!.areaId!.isNotEmpty)
          ? user.areaId
          : user?.platformId;

      final stData = await ApiService.getStations(active: true);
      List<Station> filtered = stData;
      bool stationLocked = false;
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
        }
      }
      final wkData = await OBHSRepository.getWorkers();
      final seen = <String>{};
      final uniqueWorkers = wkData.where((w) => seen.add(w.uid)).toList();

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
          _assignedPlatformId = assignedPlatformId;
          _isPlatformLocked = false;
          _isStationLocked = stationLocked;
          if (_stations.isNotEmpty) {
            if (user?.stationId != null && user!.stationId!.isNotEmpty) {
              final match = _stations.where((s) => s.uid == user!.stationId).firstOrNull;
              if (match != null) _selectedStation = match;
            }
            _selectedStation ??= _stations.first;
          }
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
          
          if (_isPlatformLocked && _assignedPlatformId != null && _assignedPlatformId!.isNotEmpty) {
            _selectedPlatform = _platforms.where((p) => p.uid == _assignedPlatformId).firstOrNull;
          } else {
            _selectedPlatform = null;
          }
          
          _selectedAreaIds.clear();
          _areaWorkerAssignments.clear();
        });
      }
    } catch (e) {
      debugPrint('Error loading platforms: $e');
      if (mounted) {
        setState(() {
          _platforms = [];
          _allAreas = [];
          _selectedPlatform = null;
          _isPlatformLocked = false;
          _selectedAreaIds.clear();
          _areaWorkerAssignments.clear();
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

    final availableWorkers = _selectedStation == null
        ? _workers
        : _workers.where((w) {
            if (w.stationId == _selectedStation!.uid) return true;
            if (w.depot != null && w.depot!.isNotEmpty) {
              final sName = _selectedStation!.stationName.toLowerCase();
              final wDepot = w.depot!.toLowerCase();
              if (sName.contains(wDepot) || wDepot.contains(sName)) return true;
            }
            return false;
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
                                'No workers registered at this station.',
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
    setState(() {
      if (_selectedAreaIds.contains(areaId)) {
        _selectedAreaIds.remove(areaId);
        _areaWorkerAssignments.remove(areaId);
      } else {
        _selectedAreaIds.add(areaId);
        _areaWorkerAssignments[areaId] = [];
      }
    });
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
      await AreaCleaningRepository.generateTasks(
        areaIds: areaIds,
        date: todayStr,
        workerIds: workerIds.isNotEmpty ? workerIds : null,
        supervisorId: _selectedSupervisor?.uid,
        frequency: _selectedFrequency,
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Parameters Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Task Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                });
                                _loadPlatforms(v.uid!);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

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

                          // Date Picker
                          InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                              child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Shift Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedShift,
                            decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), prefixIcon: Icon(Icons.schedule)),
                            items: ['Morning', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedShift = v);
                            },
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
                          Text(
                            'Select Areas (${_selectedAreaIds.length} selected)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          if (areas.isEmpty)
                            const Center(
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
                                            ],
                                          ),
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
