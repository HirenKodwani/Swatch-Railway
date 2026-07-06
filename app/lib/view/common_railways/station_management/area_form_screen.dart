import 'package:flutter/material.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

const List<String> _areaTypes = [
  'Platform 1', 'Platform 2', 'Platform 3', 'Toilet/Bathroom',
  'Waiting Room', 'Concourse', 'FOB/Stairs', 'Lift/Escalator',
  'Office', 'Water Booth', 'Track-side Rag Picking Area',
  'Circulating Area', 'Approach Road', 'Garden',
  'Goods Platform/Goods Line', 'Drain', 'Other',
];

class AreaFormScreen extends StatefulWidget {
  final String stationId;
  final Map<String, dynamic>? existingArea;
  const AreaFormScreen({super.key, required this.stationId, this.existingArea});

  @override
  State<AreaFormScreen> createState() => _AreaFormScreenState();
}

class _AreaFormScreenState extends State<AreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');
  String? _selectedArea;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existingArea;
    if (e != null) {
      _selectedArea = e['name'] ?? e['areaName'];
      _descCtrl.text = e['description'] ?? '';
      _orderCtrl.text = '${e['order'] ?? 0}';
      _active = e['active'] ?? true;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'stationId': widget.stationId,
        'name': _selectedArea,
        'areaName': _selectedArea,
        'areaType': _selectedArea,
        'description': _descCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 0,
        'active': _active,
      };
      if (widget.existingArea != null) {
        final uid = widget.existingArea!['uid'] ?? widget.existingArea!['id'];
        await ApiService.updateStationArea(uid, data);
      } else {
        await ApiService.createStationArea(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingArea != null ? 'Area updated' : 'Area created'), backgroundColor: kSuccessGreen),
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
    final isEdit = widget.existingArea != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? 'Edit' : 'Add'} Area', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const Text('Area Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _areaTypes;
                  return _areaTypes.where((a) => a.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                initialValue: TextEditingValue(text: _selectedArea ?? ''),
                onSelected: (v) => _selectedArea = v,
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Area Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                      hintText: 'Select or type area name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (v) => _selectedArea = v,
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _areaTypes.map((a) => ChoiceChip(
                  label: Text(a, style: const TextStyle(fontSize: 11)),
                  selected: _selectedArea == a,
                  onSelected: (v) => setState(() => _selectedArea = a),
                  selectedColor: kRailwayBlue,
                  labelStyle: TextStyle(color: _selectedArea == a ? Colors.white : Colors.black87),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderCtrl,
                decoration: const InputDecoration(labelText: 'Display Order', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sort)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeColor: kRailwayBlue,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Update Area' : 'Save Area'),
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
