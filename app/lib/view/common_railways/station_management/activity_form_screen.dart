import 'package:flutter/material.dart';
import 'package:crm_train/model/activity_model.dart';
import 'package:crm_train/repositories/activity_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class ActivityFormScreen extends StatefulWidget {
  final Activity? existing;
  const ActivityFormScreen({super.key, this.existing});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _unitCtrl;

  String _type = 'sweeping';
  String _freq = '';

  bool get _isEdit => widget.existing != null;

  static const _types = [
    'sweeping', 'mopping', 'washing', 'rag_picking', 'toilet_cleaning',
    'drain_cleaning', 'water_booth_cleaning', 'garbage_collection',
    'garbage_disposal', 'cobweb_removal', 'stain_removal', 'pest_control',
    'rodent_control', 'deep_cleaning', 'consumable_refill', 'inspection_closure', 'other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.activityName ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    if (e != null) {
      _type = e.activityType;
      _freq = e.defaultFrequency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final body = {
        'activityName': _nameCtrl.text.trim(),
        'activityType': _type,
        'description': _descCtrl.text.trim(),
        'unit': _unitCtrl.text.trim(),
        'defaultFrequency': _freq,
      };
      if (_isEdit) {
        await ActivityRepository.update(widget.existing!.uid!, body);
      } else {
        await ActivityRepository.create(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Activity updated' : 'Activity created'), backgroundColor: kSuccessGreen),
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
        title: Text('${_isEdit ? 'Edit' : 'Add'} Activity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kRailwayBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.cleaning_services, color: kRailwayBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Activity Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Activity Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Activity Type *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _type = v); },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit (e.g., sqm, nos)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.straighten)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Update Activity' : 'Create Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
