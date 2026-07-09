import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/garbage_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class GarbageFormScreen extends StatefulWidget {
  final GarbageCollection? record;
  final String stationId;
  final String stationName;
  const GarbageFormScreen({super.key, this.record, required this.stationId, required this.stationName});

  @override
  State<GarbageFormScreen> createState() => _GarbageFormScreenState();
}

class _GarbageFormScreenState extends State<GarbageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  DateTime _collectionDate = DateTime.now();
  final _wetKgCtrl = TextEditingController();
  final _dryKgCtrl = TextEditingController();
  final _hazardousKgCtrl = TextEditingController();
  final _collectedByCtrl = TextEditingController();
  final _disposalAgencyCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();

  bool get isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    if (r != null) {
      _collectionDate = DateTime.tryParse(r.collectionDate) ?? DateTime.now();
      _wetKgCtrl.text = r.wetKg.toString();
      _dryKgCtrl.text = r.dryKg.toString();
      _hazardousKgCtrl.text = r.hazardousKg.toString();
      _collectedByCtrl.text = r.collectedBy;
      _disposalAgencyCtrl.text = r.disposalAgency ?? '';
      _vehicleNumberCtrl.text = r.vehicleNumber ?? '';
    }
  }

  @override
  void dispose() {
    _wetKgCtrl.dispose();
    _dryKgCtrl.dispose();
    _hazardousKgCtrl.dispose();
    _collectedByCtrl.dispose();
    _disposalAgencyCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECORDED':
        return kRailwayBlue;
      case 'VERIFIED':
        return kWarningOrange;
      case 'APPROVED':
        return kSuccessGreen;
      case 'DISPOSED':
        return Colors.grey;
      case 'REJECTED':
        return kErrorRed;
      default:
        return Colors.grey;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final payload = {
        'stationId': widget.stationId,
        'collectionDate': '${_collectionDate.year}-${_collectionDate.month.toString().padLeft(2, '0')}-${_collectionDate.day.toString().padLeft(2, '0')}',
        'wetKg': double.tryParse(_wetKgCtrl.text.trim()) ?? 0,
        'dryKg': double.tryParse(_dryKgCtrl.text.trim()) ?? 0,
        'hazardousKg': double.tryParse(_hazardousKgCtrl.text.trim()) ?? 0,
        'collectedBy': _collectedByCtrl.text.trim(),
        'disposalAgency': _disposalAgencyCtrl.text.trim().isEmpty ? null : _disposalAgencyCtrl.text.trim(),
        'vehicleNumber': _vehicleNumberCtrl.text.trim().isEmpty ? null : _vehicleNumberCtrl.text.trim(),
      };
      await GarbageRepository.recordStationGarbage(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Garbage record created'), backgroundColor: kSuccessGreen),
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

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await GarbageRepository.recordStationGarbage({
        'uid': widget.record!.uid,
        'status': newStatus,
        'stationId': widget.stationId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: kSuccessGreen),
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

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Garbage Record Detail' : 'New Garbage Record', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              if (isEdit) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(r!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor(r.status)),
                    ),
                    child: Text(
                      'Status: ${r.status.toUpperCase()}',
                      style: TextStyle(color: _statusColor(r.status), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _collectionDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _collectionDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Collection Date', border: OutlineInputBorder()),
                          child: Text('${_collectionDate.year}-${_collectionDate.month.toString().padLeft(2, '0')}-${_collectionDate.day.toString().padLeft(2, '0')}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _wetKgCtrl,
                        decoration: const InputDecoration(labelText: 'Wet Waste (kg)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dryKgCtrl,
                        decoration: const InputDecoration(labelText: 'Dry Waste (kg)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hazardousKgCtrl,
                        decoration: const InputDecoration(labelText: 'Hazardous Waste (kg)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _collectedByCtrl,
                        decoration: const InputDecoration(labelText: 'Collected By', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _disposalAgencyCtrl,
                        decoration: const InputDecoration(labelText: 'Disposal Agency (optional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehicleNumberCtrl,
                        decoration: const InputDecoration(labelText: 'Vehicle Number (optional)', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!isEdit)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (isEdit) ...[
                if (r!.status.toUpperCase() == 'RECORDED') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('verified'),
                      style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                      child: const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('rejected'),
                      style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                      child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (r.status.toUpperCase() == 'VERIFIED') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('approved'),
                      style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                      child: const Text('Approve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('rejected'),
                      style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                      child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (r.status.toUpperCase() == 'APPROVED') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('disposed'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                      child: const Text('Mark Disposed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
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
