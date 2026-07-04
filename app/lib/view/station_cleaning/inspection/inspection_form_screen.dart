import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/inspection_repository.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class InspectionFormScreen extends StatefulWidget {
  final StationInspection? inspection;
  final String stationId;
  final String stationName;
  const InspectionFormScreen({super.key, this.inspection, required this.stationId, required this.stationName});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _inspectorNameCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _defAreaCtrl;
  late TextEditingController _defDescCtrl;
  late TextEditingController _defAssignedToCtrl;
  late TextEditingController _closeProofCtrl;

  String _inspectionType = 'daily';
  DateTime _scheduledDate = DateTime.now();

  double _cleanlinessScore = 70;
  double _hygieneScore = 70;
  double _infrastructureScore = 70;
  double _safetyScore = 70;

  String _defSeverity = 'medium';
  List<Map<String, dynamic>> _newDeficiencies = [];

  bool get isEdit => widget.inspection != null;
  String get _currentStatus => widget.inspection?.status ?? '';

  @override
  void initState() {
    super.initState();
    final r = widget.inspection;
    _inspectorNameCtrl = TextEditingController(text: r?.inspectorName ?? '');
    _remarksCtrl = TextEditingController(text: r?.remarks ?? '');
    _defAreaCtrl = TextEditingController();
    _defDescCtrl = TextEditingController();
    _defAssignedToCtrl = TextEditingController();
    _closeProofCtrl = TextEditingController();

    if (r != null) {
      _inspectionType = r.inspectionType;
      _scheduledDate = DateTime.tryParse(r.scheduledDate) ?? DateTime.now();
      if (r.ratings.isNotEmpty) {
        _cleanlinessScore = (r.ratings['cleanliness'] ?? 70).toDouble();
        _hygieneScore = (r.ratings['hygiene'] ?? 70).toDouble();
        _infrastructureScore = (r.ratings['infrastructure'] ?? 70).toDouble();
        _safetyScore = (r.ratings['safety'] ?? 70).toDouble();
      }
    }
  }

  @override
  void dispose() {
    _inspectorNameCtrl.dispose();
    _remarksCtrl.dispose();
    _defAreaCtrl.dispose();
    _defDescCtrl.dispose();
    _defAssignedToCtrl.dispose();
    _closeProofCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final formattedDate =
          "${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}";
      final payload = {
        'stationId': widget.stationId,
        'inspectionType': _inspectionType,
        'scheduledDate': formattedDate,
        'inspectorName': _inspectorNameCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
      };
      await InspectionRepository.create(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection created'), backgroundColor: kSuccessGreen),
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

  Future<void> _startInspection() async {
    setState(() => _isLoading = true);
    try {
      await InspectionRepository.start(widget.inspection!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection started'), backgroundColor: kSuccessGreen),
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

  Future<void> _submitRatings() async {
    setState(() => _isLoading = true);
    try {
      final ratings = {
        'cleanliness': _cleanlinessScore.round(),
        'hygiene': _hygieneScore.round(),
        'infrastructure': _infrastructureScore.round(),
        'safety': _safetyScore.round(),
      };
      await InspectionRepository.submitRatings(widget.inspection!.uid, ratings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ratings submitted'), backgroundColor: kSuccessGreen),
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

  void _addDeficiency() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Deficiency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _defAreaCtrl,
                decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _defDescCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _defSeverity,
                decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (v) {
                  if (v != null) _defSeverity = v;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _defAssignedToCtrl,
                decoration: const InputDecoration(labelText: 'Assigned To', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (_defAreaCtrl.text.trim().isEmpty || _defDescCtrl.text.trim().isEmpty) return;
              try {
                await InspectionRepository.addDeficiency(widget.inspection!.uid, {
                  'area': _defAreaCtrl.text.trim(),
                  'description': _defDescCtrl.text.trim(),
                  'severity': _defSeverity,
                  'assignedTo': _defAssignedToCtrl.text.trim(),
                });
                _defAreaCtrl.clear();
                _defDescCtrl.clear();
                _defAssignedToCtrl.clear();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deficiency added'), backgroundColor: kSuccessGreen),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _closeDeficiency(Deficiency def) {
    _closeProofCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Deficiency'),
        content: TextField(
          controller: _closeProofCtrl,
          decoration: const InputDecoration(labelText: 'Proof Photo URL', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (_closeProofCtrl.text.trim().isEmpty) return;
              try {
                await InspectionRepository.closeDeficiency(widget.inspection!.uid, def.defId, _closeProofCtrl.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deficiency closed'), backgroundColor: kSuccessGreen),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed),
                  );
                }
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              label: value.round().toString(),
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 40, child: Text('${value.round()}', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.inspection;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Inspection Detail' : 'New Inspection', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _inspectionType,
                        decoration: const InputDecoration(labelText: 'Inspection Type *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                        ],
                        onChanged: isEdit ? null : (v) {
                          if (v != null) setState(() => _inspectionType = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: isEdit ? null : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _scheduledDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _scheduledDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Scheduled Date *', border: OutlineInputBorder()),
                          child: Text(
                            "${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}",
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _inspectorNameCtrl,
                        decoration: const InputDecoration(labelText: 'Inspector Name *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remarksCtrl,
                        decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              if (r != null && r.status == 'inProgress') ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Submit Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildSlider('Cleanliness', _cleanlinessScore, (v) => setState(() => _cleanlinessScore = v)),
                        _buildSlider('Hygiene', _hygieneScore, (v) => setState(() => _hygieneScore = v)),
                        _buildSlider('Infrastructure', _infrastructureScore, (v) => setState(() => _infrastructureScore = v)),
                        _buildSlider('Safety', _safetyScore, (v) => setState(() => _safetyScore = v)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submitRatings,
                            style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                            child: const Text('Submit Ratings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (r != null && r.deficiencies.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Deficiencies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...r.deficiencies.map((def) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(def.area, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${def.description}\nSeverity: ${def.severity.toUpperCase()}'),
                        isThreeLine: true,
                        trailing: def.closureStatus == DeficiencyStatus.open
                            ? TextButton(
                                onPressed: () => _closeDeficiency(def),
                                child: const Text('Close'),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kSuccessGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: kSuccessGreen),
                                ),
                                child: const Text('CLOSED', style: TextStyle(color: kSuccessGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                      ),
                    )),
              ],
              if (r != null && (r.status == 'inProgress' || r.status == 'completed')) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _addDeficiency,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Deficiency'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (!isEdit)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                      child: const Text('Create Inspection'),
                    ),
                  ),
                if (isEdit && _currentStatus == 'scheduled')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _startInspection,
                      style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                      child: const Text('Start Inspection'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
