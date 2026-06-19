import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/station_models.dart';
import '../../model/railway_worker_model.dart';
import '../../model/station_run_model.dart';
import '../../repositories/station_run_repository.dart';
import '../../repositories/obhs_repository.dart';
import '../../services/api_services.dart';
import '../../utills/app_colors.dart';

class StationCleaningCreateRunScreen extends StatefulWidget {
  final StationCleaningRunModel? editInstance;
  const StationCleaningCreateRunScreen({super.key, this.editInstance});

  @override
  State<StationCleaningCreateRunScreen> createState() => _StationCleaningCreateRunScreenState();
}

class _StationCleaningCreateRunScreenState extends State<StationCleaningCreateRunScreen> {
  bool _isLoading = false;
  List<Station> _stations = [];
  List<StationArea> _platforms = [];
  List<RailwayWorkerModel> _workers = [];

  Station? _selectedStation;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';

  final List<StationPlatformAssignment> _assignments = [];

  bool get isEdit => widget.editInstance != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final stData = await ApiService.getStations();
      final wkData = await OBHSRepository.getWorkers();
      if (mounted) {
        setState(() {
          _stations = (stData as List).map((s) => Station.fromJson(s)).toList();
          _workers = wkData.where((w) => w.role == 'Janitor' || w.role == 'Worker').toList();
        });

        if (isEdit) {
          final inst = widget.editInstance!;
          _selectedStation = _stations.firstWhere((s) => s.uid == inst.stationId, orElse: () => _stations.first);
          _selectedShift = inst.shift;
          try { _selectedDate = DateFormat('yyyy-MM-dd').parse(inst.date); } catch(_) {}
          _assignments.addAll(inst.platforms);
          await _loadPlatforms(_selectedStation!.uid!);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e'), backgroundColor: kErrorRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlatforms(String stationId) async {
    try {
      final areas = await ApiService.getStationAreas(stationId);
      if (mounted) {
        setState(() {
          _platforms = (areas as List).map((a) => StationArea.fromJson(a)).where((a) => a.name.toLowerCase().contains('platform')).toList();
          if (_platforms.isEmpty) {
            // fallback generic platforms if none exist
            _platforms = [
              StationArea(stationId: stationId, name: 'Platform 1'),
              StationArea(stationId: stationId, name: 'Platform 2'),
            ];
          }
        });
      }
    } catch (e) {
      // fallback
      setState(() {
        _platforms = [
          StationArea(stationId: stationId, name: 'Platform 1'),
          StationArea(stationId: stationId, name: 'Platform 2'),
        ];
      });
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

  void _addPlatformAssignment(StationArea platform) {
    if (_assignments.any((a) => a.platformNumber == platform.name)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platform already added')));
      return;
    }
    setState(() {
      _assignments.add(StationPlatformAssignment(platformNumber: platform.name, janitorId: '', janitorName: ''));
    });
  }

  void _saveRun() async {
    if (_selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a station')));
      return;
    }
    if (_assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign at least one platform')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final runId = isEdit ? widget.editInstance!.runInstanceId : 'SCR-TEMP';
      final run = StationCleaningRunModel(
        id: widget.editInstance?.id,
        runInstanceId: runId,
        stationId: _selectedStation!.uid ?? '',
        stationName: _selectedStation!.stationName,
        shift: _selectedShift,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        status: isEdit ? widget.editInstance!.status : 'Pending',
        platforms: _assignments,
      );

      if (isEdit) {
        await StationRunRepository.updateStationRun(widget.editInstance!.id ?? widget.editInstance!.runInstanceId, run);
      } else {
        await StationRunRepository.createStationRun(run);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'), backgroundColor: kSuccessGreen));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? 'Edit' : 'Create'} Station Run', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  const Text('Run Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Station>(
                    value: _selectedStation,
                    decoration: const InputDecoration(labelText: 'Select Station', border: OutlineInputBorder()),
                    items: _stations.map((s) => DropdownMenuItem(value: s, child: Text(s.stationName))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedStation = v;
                        _assignments.clear();
                      });
                      if (v != null) _loadPlatforms(v.uid!);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                            child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedShift,
                          decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
                          items: ['Morning', 'Evening', 'Night'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _selectedShift = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Platform Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_selectedStation != null)
                    DropdownButtonFormField<StationArea>(
                      decoration: const InputDecoration(labelText: 'Add Platform', border: OutlineInputBorder()),
                      items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (v) { if (v != null) _addPlatformAssignment(v); },
                    ),
                  const SizedBox(height: 16),
                  ..._assignments.asMap().entries.map((entry) {
                    int idx = entry.key;
                    StationPlatformAssignment a = entry.value;
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
                                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _assignments.removeAt(idx))),
                              ],
                            ),
                            DropdownButtonFormField<RailwayWorkerModel>(
                              value: _workers.any((w) => w.uid == a.janitorId) ? _workers.firstWhere((w) => w.uid == a.janitorId) : null,
                              decoration: const InputDecoration(labelText: 'Assign Janitor'),
                              items: _workers.map((w) => DropdownMenuItem(value: w, child: Text('${w.fullName} (${w.role})'))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _assignments[idx] = StationPlatformAssignment(
                                      platformNumber: a.platformNumber,
                                      janitorId: v.uid ?? '',
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveRun,
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Save Run Instance', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
