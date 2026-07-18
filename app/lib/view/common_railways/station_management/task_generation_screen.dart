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

  Station? _selectedStation;
  Platform? _selectedPlatform; // Null means "All Platforms"
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  String _selectedFrequency = 'daily';

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
      } else if (role == 'Station Master' || role == 'Area Master' || role == 'Platform Master') {
        if (user?.stationId != null && user!.stationId!.isNotEmpty) {
          filtered = stData.where((s) => s.uid == user.stationId).toList();
          stationLocked = true;
        }
      }
      final wkData = await OBHSRepository.getWorkers();
      final seen = <String>{};
      final uniqueWorkers = wkData.where((w) => seen.add(w.uid)).toList();
      
      final selectedSt = filtered.isNotEmpty ? filtered.first : null;
      final stationWorkers = selectedSt != null
          ? uniqueWorkers.where((w) => w.stationId == selectedSt.uid).toList()
          : uniqueWorkers;

      if (mounted) {
        setState(() {
          _stations = filtered;
          _workers = stationWorkers;
          _assignedPlatformId = assignedPlatformId;
          _isPlatformLocked = (role == 'Area Master' || role == 'Platform Master') &&
              assignedPlatformId != null &&
              assignedPlatformId.isNotEmpty;
          _isStationLocked = stationLocked;
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

    final availableWorkers = _workers;

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
        // Default assign empty list of workers so they must choose
        _areaWorkerAssignments[areaId] = [];
        // Proactively show worker dialog
        _showWorkerSelectionForArea(area);
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

      List<RailwayWorkerModel> workersToAssign = _areaWorkerAssignments[areaId] ?? [];

      if (workersToAssign.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please assign at least one worker for area: ${area.name}'),
            backgroundColor: kErrorRed,
          ),
        );
        return;
      }

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
      final areaIds = platformAssignments.map((pa) => pa.areaId).whereType<String>().toSet().toList();
      await AreaCleaningRepository.generateTasks(
        areaIds: areaIds,
        date: todayStr,
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
                                final allWorkers = await OBHSRepository.getWorkers();
                                final seen = <String>{};
                                final uniqueWorkers = allWorkers.where((w) => seen.add(w.uid)).toList();
                                final stationWorkers = uniqueWorkers.where((w) => w.stationId == v.uid).toList();
                                setState(() {
                                  _selectedStation = v;
                                  _workers = stationWorkers;
                                  _selectedAreaIds.clear();
                                  _areaWorkerAssignments.clear();
                                });
                                _loadPlatforms(v.uid!);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Platform Dropdown (Optional)
                          DropdownButtonFormField<Platform?>(
                            decoration: InputDecoration(
                              labelText: 'Platform',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.view_quilt),
                              hintText: _isPlatformLocked ? 'Assigned Platform (locked)' : null,
                            ),
                            value: _selectedPlatform,
                            items: [
                              const DropdownMenuItem<Platform?>(
                                value: null,
                                child: Text('All Platforms'),
                              ),
                              ..._platforms.map((p) => DropdownMenuItem<Platform?>(value: p, child: Text(p.displayName))),
                            ],
                            onChanged: _isPlatformLocked ? null : (v) {
                              setState(() {
                                _selectedPlatform = v;
                              });
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
                            items: ['Morning', 'Afternoon', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedShift = v);
                            },
                          ),
                          const SizedBox(height: 12),

                          // Frequency Dropdown
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
                                final assignedText = assigned.isEmpty
                                    ? '(No assigned worker)'
                                    : assigned.map((w) => w.fullName).join(', ');

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _toggleAreaSelection(area),
                                    style: OutlinedButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      side: BorderSide(color: isSelected ? kRailwayBlue : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      backgroundColor: isSelected ? kRailwayBlue.withOpacity(0.04) : Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: isSelected ? kRailwayBlue : Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${area.name} (${_getPlatformName(area.platformId)}) - $assignedText',
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.black87 : Colors.black54,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelected)
                                                IconButton(
                                                  icon: const Icon(Icons.person_add_alt_1, size: 20, color: kRailwayBlue),
                                                  onPressed: () {
                                                    // Explicitly manage workers
                                                    _showWorkerSelectionForArea(area);
                                                  },
                                                ),
                                            ],
                                          ),
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
