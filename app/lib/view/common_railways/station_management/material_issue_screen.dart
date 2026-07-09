import 'package:flutter/material.dart';
import 'package:crm_train/repositories/base_repository.dart';
import 'package:crm_train/repositories/material_repository.dart';
import 'package:crm_train/model/material_model.dart';
import 'package:crm_train/utills/app_colors.dart';

class MaterialIssueScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;

  const MaterialIssueScreen({super.key, this.stationId, this.stationName});

  @override
  State<MaterialIssueScreen> createState() => _MaterialIssueScreenState();
}

class _MaterialIssueScreenState extends State<MaterialIssueScreen> {
  bool _isLoading = true;
  String? _error;

  List<MaterialItem> _materials = [];
  MaterialItem? _selectedMaterial;

  List<Map<String, dynamic>> _workers = [];
  Map<String, dynamic>? _selectedWorker;

  final _qtyCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _materials = await MaterialRepository.getAll(stationId: widget.stationId);

      final workerResult = await BaseRepository.apiCall(
        method: 'GET',
        path: '/api/users/workers',
        parser: (d) => d,
      );
      _workers = (workerResult['workers'] as List? ?? []).map((w) => w as Map<String, dynamic>).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _issue() async {
    if (_selectedMaterial == null || _selectedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select material and worker'), backgroundColor: kWarningOrange),
      );
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid quantity'), backgroundColor: kWarningOrange),
      );
      return;
    }
    if (qty > (_selectedMaterial!.currentStock)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient stock'), backgroundColor: kErrorRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await MaterialRepository.issue(_selectedMaterial!.uid!, {
        'quantity': qty,
        'issuedTo': _selectedWorker!['fullName'] ?? _selectedWorker!['uid'],
        'workerId': _selectedWorker!['uid'],
        'purpose': _purposeCtrl.text.trim(),
        'stationId': widget.stationId,
        'remarks': 'Issued to ${_selectedWorker!['fullName'] ?? ''} for ${_purposeCtrl.text.trim()}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material issued successfully'), backgroundColor: kSuccessGreen),
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
    final m = _selectedMaterial;
    final remaining = m != null ? m.currentStock - (double.tryParse(_qtyCtrl.text) ?? 0) : 0;
    final lowStock = m != null && m.reorderLevel > 0 && remaining <= m.reorderLevel;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Issue Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
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
                              const Text('Select Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<MaterialItem>(
                                value: _selectedMaterial,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.inventory_2),
                                ),
                                items: _materials.map((mat) => DropdownMenuItem(
                                  value: mat,
                                  child: Text('${mat.materialName} (Stock: ${mat.currentStock} ${mat.unit})'),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedMaterial = v),
                              ),
                              if (_selectedMaterial != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _infoChip('Current Stock', '${_selectedMaterial!.currentStock} ${_selectedMaterial!.unit}', kRailwayBlue),
                                    const SizedBox(width: 8),
                                    _infoChip('Reorder Level', '${_selectedMaterial!.reorderLevel}', kWarningOrange),
                                    if (_selectedMaterial!.unitPrice > 0) ...[
                                      const SizedBox(width: 8),
                                      _infoChip('₹/unit', _selectedMaterial!.unitPrice.toStringAsFixed(0), kSuccessGreen),
                                    ],
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
                              const Text('Issue To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedWorker,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: _workers.map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text('${w['fullName'] ?? ''} (${w['designation'] ?? w['role'] ?? ''})'),
                                )).toList(),
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
                              const Text('Issue Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _qtyCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Quantity *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.numbers),
                                  suffixText: _selectedMaterial?.unit ?? '',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _purposeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Purpose',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedMaterial != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: lowStock ? kWarningOrange.withOpacity(0.05) : kSuccessGreen.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Impact Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 8),
                                _impactRow('Current Stock', '${_selectedMaterial!.currentStock} ${_selectedMaterial!.unit}'),
                                _impactRow('After Issue', '$remaining ${_selectedMaterial!.unit}'),
                                if (lowStock)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning, size: 16, color: kWarningOrange),
                                        const SizedBox(width: 6),
                                        const Expanded(
                                          child: Text('Low stock warning - reorder recommended', style: TextStyle(color: kWarningOrange, fontWeight: FontWeight.w500, fontSize: 12)),
                                        ),
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
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _issue,
                          icon: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.outbox),
                          label: Text(_isSubmitting ? 'Issuing...' : 'Issue Material'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRailwayBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _impactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
