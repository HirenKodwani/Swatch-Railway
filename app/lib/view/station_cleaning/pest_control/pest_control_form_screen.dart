import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/pest_control_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class PestControlFormScreen extends StatefulWidget {
  final PestTreatment? plan;
  final String stationId;
  final String stationName;
  const PestControlFormScreen({super.key, this.plan, required this.stationId, required this.stationName});

  @override
  State<PestControlFormScreen> createState() => _PestControlFormScreenState();
}

class _PestControlFormScreenState extends State<PestControlFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _treatmentType = 'fumigation';
  DateTime _scheduledDate = DateTime.now();
  final _chemicalUsedCtrl = TextEditingController();
  final _quantityUsedCtrl = TextEditingController();
  String _frequency = 'one_time';

  final List<String> _treatmentTypes = ['fumigation', 'spraying', 'baiting', 'fogging', 'other'];
  final List<String> _frequencies = ['one_time', 'weekly', 'monthly', 'quarterly'];

  bool get isEdit => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      _treatmentType = p.treatmentType;
      _scheduledDate = p.scheduledDate;
      _chemicalUsedCtrl.text = p.chemicalUsed ?? '';
      _quantityUsedCtrl.text = p.quantityUsed?.toString() ?? '';
      _frequency = p.frequency ?? 'one_time';
    }
  }

  @override
  void dispose() {
    _chemicalUsedCtrl.dispose();
    _quantityUsedCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_REVIEW':
      case 'PENDINGREVIEW':
        return kWarningOrange;
      case 'APPROVED':
        return kSuccessGreen;
      case 'REJECTED':
        return kErrorRed;
      case 'FOLLOW_UP':
      case 'FOLLOWUP':
        return Colors.purple;
      case 'CLOSED':
        return Colors.grey;
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
        'treatmentType': _treatmentType,
        'scheduledDate': _scheduledDate.toIso8601String(),
        'chemicalUsed': _chemicalUsedCtrl.text.trim(),
        'quantityUsed': double.tryParse(_quantityUsedCtrl.text.trim()) ?? 0,
        'frequency': _frequency,
      };
      await PestControlRepository.createPlan(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pest control plan created'), backgroundColor: kSuccessGreen),
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
    final p = widget.plan;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Plan Detail' : 'New Pest Control Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      color: _statusColor(p!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor(p.status)),
                    ),
                    child: Text(
                      'Status: ${p.status.replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(color: _statusColor(p.status), fontWeight: FontWeight.bold),
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
                      DropdownButtonFormField<String>(
                        value: _treatmentType,
                        decoration: const InputDecoration(labelText: 'Treatment Type', border: OutlineInputBorder()),
                        items: _treatmentTypes.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _treatmentType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _scheduledDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _scheduledDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Scheduled Date', border: OutlineInputBorder()),
                          child: Text('${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _chemicalUsedCtrl,
                        decoration: const InputDecoration(labelText: 'Chemical Used', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantityUsedCtrl,
                        decoration: const InputDecoration(labelText: 'Quantity Used (kg/l)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                        items: _frequencies.map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.replaceAll('_', ' ').toUpperCase()),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
                        },
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
                        : const Text('Save Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
