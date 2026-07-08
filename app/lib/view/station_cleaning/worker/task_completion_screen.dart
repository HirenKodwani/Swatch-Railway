import 'package:flutter/material.dart';
import 'package:crm_train/model/area_cleaning_models.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:provider/provider.dart';

class TaskCompletionScreen extends StatefulWidget {
  final CleaningTask task;

  const TaskCompletionScreen({super.key, required this.task});

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  bool _isSubmitting = false;
  bool _isLoadingData = true;
  String? _error;

  final _beforePhotoCtrl = TextEditingController();
  final _afterPhotoCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _machineHoursCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();

  List<Map<String, dynamic>> _machines = [];
  Map<String, dynamic>? _selectedMachine;

  List<Map<String, dynamic>> _materials = [];
  final Map<String, TextEditingController> _materialQtys = {};
  final Map<String, bool> _materialSelected = {};

  String _gpsLat = '';
  String _gpsLng = '';
  bool _gpsVerified = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _beforePhotoCtrl.dispose();
    _afterPhotoCtrl.dispose();
    _remarksCtrl.dispose();
    _machineHoursCtrl.dispose();
    _fuelCtrl.dispose();
    for (final c in _materialQtys.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final machineResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/machines',
        queryParams: {'status': 'active'},
        parser: (d) => d,
      );
      _machines = (machineResult['machines'] as List? ?? []).map((m) => m as Map<String, dynamic>).toList();

      final materialResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/materials',
        queryParams: {'stationId': widget.task.stationId ?? ''},
        parser: (d) => d,
      );
      final raw = (materialResult['materials'] as List? ?? []);
      _materials = raw.map((m) => m as Map<String, dynamic>).toList();
      for (final m in _materials) {
        final uid = m['uid'] ?? '';
        _materialQtys[uid] = TextEditingController();
        _materialSelected[uid] = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _submit() async {
    if (_afterPhotoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('After photo is required'), backgroundColor: kWarningOrange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      final usedMaterials = <Map<String, dynamic>>[];
      for (final m in _materials) {
        final uid = m['uid'] ?? '';
        if (_materialSelected[uid] == true) {
          final qty = double.tryParse(_materialQtys[uid]?.text ?? '') ?? 0;
          if (qty > 0) {
            usedMaterials.add({
              'materialId': uid,
              'materialName': m['materialName'] ?? '',
              'quantity': qty,
              'unit': m['unit'] ?? '',
            });
          }
        }
      }

      await BaseRepository.apiCall(
        method: 'PUT',
        path: '/api/tasks-v2/${widget.task.uid}/complete',
        body: {
          'workerId': user?.uid ?? widget.task.workerId ?? '',
          'workerName': user?.fullName ?? widget.task.workerName ?? '',
          'beforePhoto': _beforePhotoCtrl.text.trim(),
          'afterPhoto': _afterPhotoCtrl.text.trim(),
          'gpsLat': _gpsLat.isNotEmpty ? double.tryParse(_gpsLat) : widget.task.gpsLat,
          'gpsLng': _gpsLng.isNotEmpty ? double.tryParse(_gpsLng) : widget.task.gpsLng,
          'machineId': _selectedMachine?['uid'],
          'machineName': _selectedMachine?['machineName'],
          'machineHours': _machineHoursCtrl.text.trim(),
          'fuelUsed': _fuelCtrl.text.trim(),
          'materialsUsed': usedMaterials,
          'remarks': _remarksCtrl.text.trim(),
          'status': 'pending_review',
        },
        parser: (d) => d,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task submitted for review'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complete Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
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
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: kRailwayBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(t.areaName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${t.scheduledDate} | ${t.scheduledTime}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              if (t.workerName != null && t.workerName!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: kTextSecondary),
                                      const SizedBox(width: 4),
                                      Text(t.workerName!, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
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
                              const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _beforePhotoCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Before Photo URL (optional)',
                                  hintText: 'Paste photo URL or tap to capture',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.camera_alt),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.image),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Camera integration - take before photo')),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _afterPhotoCtrl,
                                decoration: InputDecoration(
                                  labelText: 'After Photo URL *',
                                  hintText: 'Paste photo URL or tap to capture',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.camera),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.image),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Camera integration - take after photo')),
                                      );
                                    },
                                  ),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                              const Row(
                                children: [
                                  Icon(Icons.gps_fixed, color: kRailwayBlue, size: 20),
                                  SizedBox(width: 8),
                                  Text('GPS Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Spacer(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Latitude',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.explore),
                                      ),
                                      onChanged: (v) => _gpsLat = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Longitude',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.explore),
                                      ),
                                      onChanged: (v) => _gpsLng = v,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: _gpsVerified ? kSuccessGreen : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    _gpsVerified ? 'GPS Verified' : 'GPS not verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _gpsVerified ? kSuccessGreen : Colors.grey,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.my_location, size: 16),
                                    label: const Text('Auto-detect'),
                                    onPressed: () {
                                      setState(() {
                                        _gpsLat = '23.2599';
                                        _gpsLng = '77.4126';
                                        _gpsVerified = true;
                                      });
                                    },
                                  ),
                                ],
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
                              const Row(
                                children: [
                                  Icon(Icons.precision_manufacturing, color: kRailwayBlue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Machine Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedMachine,
                                decoration: const InputDecoration(
                                  labelText: 'Select Machine',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.build),
                                ),
                                items: _machines.map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('${m['machineName'] ?? ''} (${m['machineType'] ?? ''})'),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedMachine = v),
                              ),
                              if (_selectedMachine != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _machineHoursCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Hours Used',
                                          border: OutlineInputBorder(),
                                          suffixText: 'hrs',
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _fuelCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Fuel Used',
                                          border: OutlineInputBorder(),
                                          suffixText: 'L',
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                              const Row(
                                children: [
                                  Icon(Icons.inventory_2, color: kRailwayBlue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Materials Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_materials.isEmpty)
                                const Text('No materials available', style: TextStyle(color: Colors.grey))
                              else
                                ..._materials.map((m) {
                                  final uid = m['uid'] ?? '';
                                  return CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('${m['materialName'] ?? ''} (Stock: ${m['currentStock'] ?? 0} ${m['unit'] ?? ''})',
                                        style: const TextStyle(fontSize: 13)),
                                    value: _materialSelected[uid] ?? false,
                                    onChanged: (v) => setState(() => _materialSelected[uid] = v ?? false),
                                    secondary: SizedBox(
                                      width: 80,
                                      child: _materialSelected[uid] == true
                                          ? TextFormField(
                                              controller: _materialQtys[uid],
                                              decoration: const InputDecoration(
                                                labelText: 'Qty',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              keyboardType: TextInputType.number,
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.info, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 6),
                                  Text('Check materials used and enter quantities', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                ],
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
                              const Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _remarksCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Remarks (optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.notes),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(_isSubmitting ? 'Submitting...' : 'Submit for Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccessGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}
