import 'package:flutter/material.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

class TaskGenerationScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;
  const TaskGenerationScreen({super.key, this.stationId, this.stationName});

  @override
  State<TaskGenerationScreen> createState() => _TaskGenerationScreenState();
}

class _TaskGenerationScreenState extends State<TaskGenerationScreen> {
  List<Station> _stations = [];
  List<StationArea> _areas = [];
  List<String> _selectedAreaIds = [];
  Station? _selectedStation;
  bool _isLoadingStations = true;
  bool _isSubmitting = false;
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  String _shift = 'morning';
  String _frequency = 'daily';
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoadingStations = true);
    try {
      _stations = await ApiService.getStations(active: true);
      if (_stations.isNotEmpty) {
        _selectedStation = _stations.first;
        _loadAreas();
      }
    } catch (e) {
      //
    } finally {
      if (mounted) setState(() => _isLoadingStations = false);
    }
  }

  Future<void> _loadAreas() async {
    if (_selectedStation == null) return;
    try {
      _areas = await ApiService.getStationAreas(_selectedStation!.uid ?? '');
    } catch (_) {}
  }

  Future<void> _generateTasks() async {
    if (_selectedAreaIds.isEmpty || _selectedStation == null) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await BaseRepository.apiCall(
        method: 'POST',
        path: '/api/tasks-v2/generate',
        body: {
          'stationId': _selectedStation!.uid,
          'areaIds': _selectedAreaIds,
          'date': _selectedDate,
          'shift': _shift,
          'frequency': _frequency,
        },
        parser: (d) => d,
      );
      _result = result;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['count'] ?? 0} tasks generated'), backgroundColor: kSuccessGreen),
        );
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
        title: const Text('Generate Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingStations
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
                          const Text('Task Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Station>(
                            value: _selectedStation,
                            decoration: const InputDecoration(labelText: 'Station', border: OutlineInputBorder(), prefixIcon: Icon(Icons.train)),
                            items: _stations.map((s) => DropdownMenuItem(value: s, child: Text('${s.stationCode} - ${s.stationName}'))).toList(),
                            onChanged: (v) {
                              setState(() => _selectedStation = v);
                              _loadAreas();
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                            readOnly: true,
                            controller: TextEditingController(text: _selectedDate),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.parse(_selectedDate),
                                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) setState(() => _selectedDate = picked.toIso8601String().substring(0, 10));
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _shift,
                            decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), prefixIcon: Icon(Icons.schedule)),
                            items: ['morning', 'afternoon', 'evening', 'night'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                            onChanged: (v) { if (v != null) setState(() => _shift = v); },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _frequency,
                            decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(), prefixIcon: Icon(Icons.repeat)),
                            items: ['daily', 'weekly', 'monthly'].map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1)))).toList(),
                            onChanged: (v) { if (v != null) setState(() => _frequency = v); },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Areas (${_selectedAreaIds.length} selected)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          if (_areas.isEmpty)
                            const Text('No areas found', style: TextStyle(color: Colors.grey))
                          else
                            Wrap(
                              spacing: 8, runSpacing: 4,
                              children: _areas.map((a) => FilterChip(
                                label: Text(a.name, style: const TextStyle(fontSize: 12)),
                                selected: _selectedAreaIds.contains(a.uid),
                                onSelected: (v) {
                                  setState(() {
                                    if (v) { _selectedAreaIds.add(a.uid!); }
                                    else { _selectedAreaIds.remove(a.uid); }
                                  });
                                },
                                selectedColor: kRailwayBlue.withOpacity(0.2),
                              )).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: kSuccessGreen.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: kSuccessGreen, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_result!['count'] ?? 0} tasks generated', style: const TextStyle(fontWeight: FontWeight.bold, color: kSuccessGreen)),
                                  Text('For ${_result!['date'] ?? _selectedDate} - ${_result!['shift'] ?? _shift}',
                                      style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _selectedAreaIds.isEmpty ? null : _generateTasks,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isSubmitting ? 'Generating...' : 'Generate Tasks (${_selectedAreaIds.length} areas)'),
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
