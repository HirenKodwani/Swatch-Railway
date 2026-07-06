import 'package:flutter/material.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

class AreaFormScreen extends StatefulWidget {
  final String stationId;
  const AreaFormScreen({super.key, required this.stationId});

  @override
  State<AreaFormScreen> createState() => _AreaFormScreenState();
}

class _AreaFormScreenState extends State<AreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');
  bool _active = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.createStationArea({
        'stationId': widget.stationId,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 0,
        'active': _active,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area created'), backgroundColor: kSuccessGreen),
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
        title: const Text('Add Area', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Area Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                      : const Text('Save Area'),
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
