import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/execution_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class ExecutionPlanFormScreen extends StatefulWidget {
  final ExecutionPlan? plan;
  final String stationId;
  final String stationName;
  const ExecutionPlanFormScreen({super.key, this.plan, required this.stationId, required this.stationName});

  @override
  State<ExecutionPlanFormScreen> createState() => _ExecutionPlanFormScreenState();
}

class _ExecutionPlanFormScreenState extends State<ExecutionPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _contractIdCtrl;
  late TextEditingController _manpowerPlanCtrl;
  late TextEditingController _machinePlanCtrl;
  late TextEditingController _garbagePlanCtrl;
  late TextEditingController _materialCtrl;
  late TextEditingController _rejectionReasonCtrl;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _morningSelected = false;
  bool _afternoonSelected = false;
  bool _nightSelected = false;

  List<String> _materials = [];

  bool get isEdit => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _contractIdCtrl = TextEditingController(text: p?.contractId ?? '');
    _manpowerPlanCtrl = TextEditingController(text: p != null ? _mapToString(p.manpowerPlan) : '{}');
    _machinePlanCtrl = TextEditingController(text: p != null ? _mapToString(p.machinePlan) : '{}');
    _garbagePlanCtrl = TextEditingController(text: p != null ? _mapToString(p.garbageDisposalPlan) : '{}');
    _materialCtrl = TextEditingController();
    _rejectionReasonCtrl = TextEditingController();

    if (p != null) {
      _selectedMonth = p.month;
      _selectedYear = p.year;
      _morningSelected = p.shiftPlan['morning'] == true || (p.shiftPlan['morning'] is int && (p.shiftPlan['morning'] as int) > 0);
      _afternoonSelected = p.shiftPlan['afternoon'] == true || (p.shiftPlan['afternoon'] is int && (p.shiftPlan['afternoon'] as int) > 0);
      _nightSelected = p.shiftPlan['night'] == true || (p.shiftPlan['night'] is int && (p.shiftPlan['night'] as int) > 0);
      _materials = p.materialPlan.map((e) => e.toString()).toList();
    }
  }

  @override
  void dispose() {
    _contractIdCtrl.dispose();
    _manpowerPlanCtrl.dispose();
    _machinePlanCtrl.dispose();
    _garbagePlanCtrl.dispose();
    _materialCtrl.dispose();
    _rejectionReasonCtrl.dispose();
    super.dispose();
  }

  String _mapToString(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final shiftPlan = <String, dynamic>{
        'morning': _morningSelected,
        'afternoon': _afternoonSelected,
        'night': _nightSelected,
      };
      final manpowerMap = <String, dynamic>{};
      for (final line in _manpowerPlanCtrl.text.split('\n')) {
        final parts = line.split(':');
        if (parts.length == 2) manpowerMap[parts[0].trim()] = parts[1].trim();
      }
      final machineMap = <String, dynamic>{};
      for (final line in _machinePlanCtrl.text.split('\n')) {
        final parts = line.split(':');
        if (parts.length == 2) machineMap[parts[0].trim()] = parts[1].trim();
      }
      final garbageMap = <String, dynamic>{};
      for (final line in _garbagePlanCtrl.text.split('\n')) {
        final parts = line.split(':');
        if (parts.length == 2) garbageMap[parts[0].trim()] = parts[1].trim();
      }

      final payload = {
        'contractId': _contractIdCtrl.text.trim(),
        'stationId': widget.stationId,
        'month': _selectedMonth,
        'year': _selectedYear,
        'shiftPlan': shiftPlan,
        'manpowerPlan': manpowerMap,
        'machinePlan': machineMap,
        'materialPlan': _materials,
        'garbageDisposalPlan': garbageMap,
        'weeklySchedule': [],
      };

      if (isEdit) {
        await ExecutionRepository.updatePlan(widget.plan!.uid, payload);
      } else {
        await ExecutionRepository.createPlan(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Plan updated' : 'Plan created'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ExecutionRepository.submitPlan(widget.plan!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan submitted'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await ExecutionRepository.approvePlan(widget.plan!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan approved'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    final reason = _rejectionReasonCtrl.text.trim();
    if (reason.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ExecutionRepository.rejectPlan(widget.plan!.uid, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan rejected'), backgroundColor: kErrorRed),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addMaterial() {
    final text = _materialCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _materials.add(text);
        _materialCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Plan' : 'New Execution Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _contractIdCtrl,
                        decoration: const InputDecoration(labelText: 'Contract ID *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(labelText: 'Month *', border: OutlineInputBorder()),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Month ${i + 1}'))),
                        onChanged: isEdit ? null : (v) {
                          if (v != null) setState(() => _selectedMonth = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(labelText: 'Year *', border: OutlineInputBorder()),
                        items: [
                          for (int y = DateTime.now().year - 2; y <= DateTime.now().year + 1; y++)
                            DropdownMenuItem(value: y, child: Text(y.toString())),
                        ],
                        onChanged: isEdit ? null : (v) {
                          if (v != null) setState(() => _selectedYear = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shift Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Morning'),
                        value: _morningSelected,
                        onChanged: (v) => setState(() => _morningSelected = v ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Afternoon'),
                        value: _afternoonSelected,
                        onChanged: (v) => setState(() => _afternoonSelected = v ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Night'),
                        value: _nightSelected,
                        onChanged: (v) => setState(() => _nightSelected = v ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manpower Plan (key:value per line)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _manpowerPlanCtrl,
                        decoration: const InputDecoration(labelText: 'e.g. supervisor:2\\nworker:5', border: OutlineInputBorder()),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Material Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _materialCtrl,
                              decoration: const InputDecoration(labelText: 'Add material', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: kRailwayBlue),
                            onPressed: _addMaterial,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _materials.map((m) => Chip(
                          label: Text(m),
                          onDeleted: () => setState(() => _materials.remove(m)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Machine Plan (key:value per line)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _machinePlanCtrl,
                        decoration: const InputDecoration(labelText: 'e.g. scrubber:2', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Garbage Disposal Plan (key:value per line)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _garbagePlanCtrl,
                        decoration: const InputDecoration(labelText: 'e.g. wet:100kg', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (p == null || p.status == 'DRAFT')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                      child: Text(isEdit ? 'Update Plan' : 'Create Plan'),
                    ),
                  ),
                if (p != null && p.status == 'DRAFT') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                      child: const Text('Submit for Approval'),
                    ),
                  ),
                ],
                if (p != null && p.status == 'SUBMITTED') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _approve,
                          style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reject Plan'),
                                content: TextField(
                                  controller: _rejectionReasonCtrl,
                                  decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _reject();
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
