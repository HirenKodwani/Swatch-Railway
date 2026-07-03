import 'package:flutter/material.dart';
import 'package:crm_train/model/material_model.dart';
import 'package:crm_train/repositories/material_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class MaterialFormScreen extends StatefulWidget {
  final MaterialItem? existing;
  const MaterialFormScreen({super.key, this.existing});

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _openCtrl;
  late TextEditingController _reorderCtrl;
  late TextEditingController _priceCtrl;

  String _type = 'consumable';

  bool get _isEdit => widget.existing != null;

  static const _types = ['consumable', 'chemical', 'equipment', 'ppe', 'tool', 'other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.materialName ?? '');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _openCtrl = TextEditingController(text: e?.openingBalance.toString() ?? '');
    _reorderCtrl = TextEditingController(text: e?.reorderLevel.toString() ?? '');
    _priceCtrl = TextEditingController(text: e?.unitPrice.toString() ?? '');
    if (e != null) _type = e.materialType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _openCtrl.dispose();
    _reorderCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final body = {
        'materialName': _nameCtrl.text.trim(),
        'materialType': _type,
        'unit': _unitCtrl.text.trim(),
        'openingBalance': double.tryParse(_openCtrl.text) ?? 0,
        'reorderLevel': double.tryParse(_reorderCtrl.text) ?? 0,
        'unitPrice': double.tryParse(_priceCtrl.text) ?? 0,
      };
      if (_isEdit) {
        await MaterialRepository.update(widget.existing!.uid!, body);
      } else {
        await MaterialRepository.create(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Material updated' : 'Material created'), backgroundColor: kSuccessGreen),
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
        title: Text('${_isEdit ? 'Edit' : 'Add'} Material', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          child: const Icon(Icons.inventory_2, color: kRailwayBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Material Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Material Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Material Type *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _type = v); },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit * (e.g., kg, litre, nos)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.straighten)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.balance, color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Stock Configuration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _openCtrl,
                              decoration: const InputDecoration(labelText: 'Opening Balance', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _reorderCtrl,
                              decoration: const InputDecoration(labelText: 'Reorder Level', border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning_amber)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(labelText: 'Unit Price (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
                        keyboardType: TextInputType.number,
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
                      : Text(_isEdit ? 'Update Material' : 'Create Material'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
