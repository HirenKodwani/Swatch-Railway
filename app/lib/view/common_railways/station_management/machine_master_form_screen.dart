import 'package:flutter/material.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

class MachineMasterFormScreen extends StatefulWidget {
  final Map<String, dynamic>? machine;
  const MachineMasterFormScreen({super.key, this.machine});

  @override
  State<MachineMasterFormScreen> createState() => _MachineMasterFormScreenState();
}

class _MachineMasterFormScreenState extends State<MachineMasterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  List<Station> _stations = [];

  late TextEditingController _nameCtrl;
  late TextEditingController _serialCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _remarksCtrl;

  String _type = 'scrubber';
  String _workingStatus = 'working';
  String? _stationId;

  bool get _isEdit => widget.machine != null;

  final _types = ['scrubber', 'sweeper', 'vacuum', 'pressure_washer', 'generator', 'blower', 'other'];
  final _statuses = ['working', 'under_maintenance', 'broken'];

  @override
  void initState() {
    super.initState();
    final m = widget.machine;
    _nameCtrl = TextEditingController(text: m?['machineName'] ?? '');
    _serialCtrl = TextEditingController(text: m?['serialNumber'] ?? '');
    _locationCtrl = TextEditingController(text: m?['location'] ?? '');
    _remarksCtrl = TextEditingController(text: m?['remarks'] ?? '');
    if (m != null) {
      _type = m['machineType'] ?? 'scrubber';
      _workingStatus = m['workingStatus'] ?? 'working';
      _stationId = m['stationId'];
    }
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      _stations = await ApiService.getStations(active: true);
      if (_stations.isNotEmpty && !_isEdit) {
        _stationId ??= _stations.first.uid ?? _stations.first.stationCode;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _locationCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final body = {
        'machineName': _nameCtrl.text.trim(),
        'machineType': _type,
        'serialNumber': _serialCtrl.text.trim(),
        'stationId': _stationId ?? '',
        'location': _locationCtrl.text.trim(),
        'workingStatus': _workingStatus,
        'remarks': _remarksCtrl.text.trim(),
      };
      if (_isEdit) {
        await ApiService.updateMachine(widget.machine!['uid'], body);
      } else {
        await ApiService.createMachine(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Machine updated' : 'Machine created'), backgroundColor: kSuccessGreen),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_isEdit ? 'Edit' : 'Add'} Machine', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Machine Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.precision_manufacturing)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Machine Type *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serialCtrl,
                decoration: const InputDecoration(labelText: 'Serial Number *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _stationId,
                decoration: const InputDecoration(labelText: 'Station *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.train)),
                items: _stations.map((s) => DropdownMenuItem(value: s.uid ?? s.stationCode, child: Text('${s.stationCode} - ${s.stationName}'))).toList(),
                onChanged: (v) => setState(() => _stationId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _workingStatus,
                decoration: const InputDecoration(labelText: 'Working Status', border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle)),
                items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _workingStatus = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Update Machine' : 'Create Machine'),
                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
