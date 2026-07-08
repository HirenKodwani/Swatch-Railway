import 'package:flutter/material.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class MachineAssignmentScreen extends StatefulWidget {
  const MachineAssignmentScreen({super.key});

  @override
  State<MachineAssignmentScreen> createState() => _MachineAssignmentScreenState();
}

class _MachineAssignmentScreenState extends State<MachineAssignmentScreen> {
  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _workers = [];
  Map<String, dynamic>? _selectedMachine;
  Map<String, dynamic>? _selectedWorker;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _purpose = 'cleaning';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final machineResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/machines',
        queryParams: {'status': 'active'},
        parser: (d) => d,
      );
      _machines = (machineResult['machines'] as List? ?? []).map((m) => m as Map<String, dynamic>).toList();

      final workerResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/users/workers',
        parser: (d) => d,
      );
      _workers = (workerResult['workers'] as List? ?? []).map((w) => w as Map<String, dynamic>).toList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deploy() async {
    if (_selectedMachine == null || _selectedWorker == null) return;
    setState(() => _isSubmitting = true);
    try {
      await BaseRepository.apiCall(
        method: 'POST',
        path: '/api/machines/deploy',
        body: {
          'machineId': _selectedMachine!['uid'],
          'machineName': _selectedMachine!['machineName'],
          'workerId': _selectedWorker!['uid'],
          'workerName': _selectedWorker!['fullName'],
          'purpose': _purpose,
          'deployedAt': DateTime.now().toIso8601String(),
        },
        parser: (d) => d,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Machine deployed'), backgroundColor: kSuccessGreen));
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
        title: const Text('Assign Machine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          const Text('Select Machine', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedMachine,
                            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.precision_manufacturing)),
                            items: _machines.map((m) => DropdownMenuItem(value: m, child: Text(m['machineName'] ?? ''))).toList(),
                            onChanged: (v) => setState(() => _selectedMachine = v),
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
                          const Text('Assign To Worker', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedWorker,
                            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                            items: _workers.map((w) => DropdownMenuItem(value: w, child: Text(w['fullName'] ?? ''))).toList(),
                            onChanged: (v) => setState(() => _selectedWorker = v),
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
                          const Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _purpose,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: ['cleaning', 'scrubbing', 'sweeping', 'washing', 'vacuuming', 'other']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1))))
                                .toList(),
                            onChanged: (v) { if (v != null) setState(() => _purpose = v); },
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
                      onPressed: _isSubmitting || _selectedMachine == null || _selectedWorker == null ? null : _deploy,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Deploying...' : 'Deploy Machine'),
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
