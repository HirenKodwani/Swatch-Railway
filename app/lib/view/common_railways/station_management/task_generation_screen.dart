import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/auth_provider.dart';
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
  Station? _selectedStation;
  bool _isLoadingStations = true;
  bool _isSubmitting = false;
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  String _shift = 'morning';

  List<Map<String, dynamic>> _contractors = [];
  String? _selectedContractorId;
  bool _isLoadingContractors = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _loadContractors();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoadingStations = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final role = user?.role ?? '';
      _stations = await ApiService.getStations(active: true);
      if (widget.stationId != null) {
        _stations = _stations.where((s) => s.uid == widget.stationId).toList();
      } else if (role == 'Station Master' || role == 'Area Master' || role == 'Platform Master') {
        if (user?.stationId != null && user!.stationId!.isNotEmpty) {
          _stations = _stations.where((s) => s.uid == user.stationId).toList();
        }
      }
      if (_stations.isNotEmpty) {
        _selectedStation = _stations.first;
      }
    } catch (e) {
      debugPrint('Error loading stations: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStations = false);
    }
  }

  Future<void> _loadContractors() async {
    setState(() => _isLoadingContractors = true);
    try {
      final res = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/users',
        queryParams: {'role': 'CONTRACTOR'},
        parser: (data) => data,
      );
      final List list = res['users'] ?? [];
      setState(() {
        _contractors = list.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error loading contractors: $e');
    } finally {
      if (mounted) setState(() => _isLoadingContractors = false);
    }
  }

  Future<void> _generateTasks() async {
    if (_selectedStation == null || _selectedContractorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Station and a Contractor')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await BaseRepository.apiCall(
        method: 'POST',
        path: '/api/station-runs',
        body: {
          'stationId': _selectedStation!.uid,
          'stationName': _selectedStation!.stationName,
          'date': _selectedDate,
          'shift': _shift,
          'contractorId': _selectedContractorId,
          'status': 'active'
        },
        parser: (d) => d,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Station Run generated successfully!'), backgroundColor: kSuccessGreen),
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
      body: _isLoadingStations || _isLoadingContractors
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
                          DropdownButtonFormField<Station>(
                            value: _selectedStation,
                            decoration: const InputDecoration(labelText: 'Station', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                            items: _stations.map((s) => DropdownMenuItem(value: s, child: Text(s.stationName))).toList(),
                            onChanged: _stations.length == 1 ? null : (v) {
                              if (v != null) {
                                setState(() { _selectedStation = v; });
                              }
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
                              if (picked != null) {
                                setState(() { _selectedDate = picked.toIso8601String().substring(0, 10); });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _shift,
                            decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), prefixIcon: Icon(Icons.schedule)),
                            items: ['morning', 'afternoon', 'evening', 'night'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _shift = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedContractorId,
                            decoration: const InputDecoration(labelText: 'Assign Contractor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.handshake)),
                            items: _contractors.map((c) => DropdownMenuItem(value: c['uid'].toString(), child: Text(c['companyName'] ?? c['fullName'] ?? 'Unknown Contractor'))).toList(),
                            onChanged: (v) {
                              setState(() => _selectedContractorId = v);
                            },
                            hint: const Text('Select a Contractor'),
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
                        onPressed: _isSubmitting || _selectedStation == null || _selectedContractorId == null ? null : _generateTasks,
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
