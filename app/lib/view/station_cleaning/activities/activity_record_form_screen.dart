import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/repositories/daily_activity_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class ActivityRecordFormScreen extends StatefulWidget {
  final DailyActivityRecord? activityRecord;
  final String stationId;
  final String stationName;
  const ActivityRecordFormScreen({super.key, this.activityRecord, required this.stationId, required this.stationName});

  @override
  State<ActivityRecordFormScreen> createState() => _ActivityRecordFormScreenState();
}

class _ActivityRecordFormScreenState extends State<ActivityRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _areaCtrl;
  late TextEditingController _activityCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _rejectionReasonCtrl;
  late TextEditingController _resubmissionRemarksCtrl;

  String _selectedShift = 'morning';
  String _selectedFrequency = 'once_per_day';

  String _beforePhoto = '';
  String _afterPhoto = '';

  bool get isEdit => widget.activityRecord != null;

  @override
  void initState() {
    super.initState();
    final r = widget.activityRecord;
    _areaCtrl = TextEditingController(text: r?.areaName ?? '');
    _activityCtrl = TextEditingController(text: r?.activityName ?? '');
    _remarksCtrl = TextEditingController(text: r?.remarks ?? '');
    _rejectionReasonCtrl = TextEditingController(text: r?.rejectionReason ?? '');
    _resubmissionRemarksCtrl = TextEditingController(text: r?.resubmissionRemarks ?? '');

    if (r != null) {
      _selectedShift = r.shift;
      _selectedFrequency = r.scheduledFrequency;
      _beforePhoto = r.beforePhotoUrl;
      _afterPhoto = r.afterPhotoUrl;
    }
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _activityCtrl.dispose();
    _remarksCtrl.dispose();
    _rejectionReasonCtrl.dispose();
    _resubmissionRemarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      final payload = {
        'stationId': widget.stationId,
        'areaName': _areaCtrl.text.trim(),
        'activityName': _activityCtrl.text.trim(),
        'areaId': widget.activityRecord?.areaId ?? 'general_area',
        'activityId': widget.activityRecord?.activityId ?? 'general_activity',
        'date': widget.activityRecord?.date ?? formattedDate,
        'shift': _selectedShift,
        'scheduledFrequency': _selectedFrequency,
        'beforePhotoUrl': _beforePhoto,
        'afterPhotoUrl': _afterPhoto,
        'remarks': _remarksCtrl.text.trim(),
      };

      if (isEdit) {
        await DailyActivityRepository.updateStatus(
          widget.activityRecord!.uid,
          'completed',
          beforePhotoUrl: _beforePhoto,
          afterPhotoUrl: _afterPhoto,
          remarks: _remarksCtrl.text.trim(),
        );
      } else {
        await DailyActivityRepository.create(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Activity record updated' : 'Activity record created'), backgroundColor: kSuccessGreen),
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

  Future<void> _verify(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await DailyActivityRepository.updateStatus(
        widget.activityRecord!.uid,
        newStatus,
        rejectionReason: newStatus == 'rejected' ? _rejectionReasonCtrl.text.trim() : null,
        resubmissionRemarks: newStatus == 'resubmitted' ? _resubmissionRemarksCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record $newStatus successfully'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification action failed: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _simulatePhotoCapture(bool isBefore) {
    setState(() {
      final mockUrl = 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}';
      if (isBefore) {
        _beforePhoto = mockUrl;
      } else {
        _afterPhoto = mockUrl;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.activityRecord;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Record Detail' : 'New Activity Record', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        controller: _areaCtrl,
                        decoration: const InputDecoration(labelText: 'Area Name *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _activityCtrl,
                        decoration: const InputDecoration(labelText: 'Activity Name *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedShift,
                        decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'afternoon', child: Text('Afternoon')),
                          DropdownMenuItem(value: 'night', child: Text('Night')),
                        ],
                        onChanged: isEdit ? null : (v) {
                          if (v != null) setState(() => _selectedShift = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Photo Evidence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Before Photo'),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _simulatePhotoCapture(true),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _beforePhoto.isNotEmpty
                                ? Image.network(_beforePhoto, fit: BoxFit.cover)
                                : const Center(child: Icon(Icons.add_a_photo, size: 36, color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('After Photo'),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _simulatePhotoCapture(false),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _afterPhoto.isNotEmpty
                                ? Image.network(_afterPhoto, fit: BoxFit.cover)
                                : const Center(child: Icon(Icons.add_a_photo, size: 36, color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              if (r != null && r.rejectionReason != null && r.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kErrorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Rejection Reason: ${r.rejectionReason}', style: const TextStyle(color: kErrorRed, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (r == null || r.status == DailyActivityStatus.pending || r.status == DailyActivityStatus.rejected || r.status == DailyActivityStatus.resubmitted)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                    child: const Text('Submit Activity Evidence'),
                  ),
                ),
              if (r != null && r.status == DailyActivityStatus.completed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _verify('approved'),
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
                              title: const Text('Reject Activity Record'),
                              content: TextField(
                                controller: _rejectionReasonCtrl,
                                decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _verify('rejected');
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
          ),
        ),
      ),
    );
  }
}
