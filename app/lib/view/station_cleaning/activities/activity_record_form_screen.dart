import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/repositories/daily_activity_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';

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
  bool _uploadingPhoto = false;

  late TextEditingController _activityCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _rejectionReasonCtrl;
  late TextEditingController _resubmissionRemarksCtrl;

  String _selectedShift = 'morning';
  String _selectedArea = '';
  String _selectedFrequency = 'once_per_day';
  List<StationArea> _areas = [];

  String _beforePhoto = '';
  String _afterPhoto = '';

  bool get isEdit => widget.activityRecord != null;

  @override
  void initState() {
    super.initState();
    final r = widget.activityRecord;
    _activityCtrl = TextEditingController(text: r?.activityName ?? '');
    _remarksCtrl = TextEditingController(text: r?.remarks ?? '');
    _rejectionReasonCtrl = TextEditingController(text: r?.rejectionReason ?? '');
    _resubmissionRemarksCtrl = TextEditingController(text: r?.resubmissionRemarks ?? '');

    if (r != null) {
      _selectedArea = r.areaName;
      _selectedShift = r.shift;
      _selectedFrequency = r.scheduledFrequency;
      _beforePhoto = r.beforePhotoUrl;
      _afterPhoto = r.afterPhotoUrl;
    }
    _loadAreas();
  }

  @override
  void dispose() {
    _activityCtrl.dispose();
    _remarksCtrl.dispose();
    _rejectionReasonCtrl.dispose();
    _resubmissionRemarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    _areas = [];
    if (mounted) setState(() {});
    try {
      _areas = await ApiService.getStationAreas(widget.stationId);
      if (_areas.isNotEmpty && _selectedArea.isEmpty) _selectedArea = _areas.first.name;
    } catch (e) {
      debugPrint('_loadAreas error: $e');
    }
    if (mounted) setState(() {});
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  Future<String?> _capturePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return null;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final token = await _getToken();
      if (token == null) return null;
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/evidence/upload/base64'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'image': base64Encode(bytes), 'fileName': 'activity_${DateTime.now().millisecondsSinceEpoch}.jpg'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] ?? data['imageUrl'] ?? '';
      }
    } catch (_) {}
    setState(() => _uploadingPhoto = false);
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      final areaId = widget.activityRecord?.areaId ?? _areas.firstWhere((a) => a.name == _selectedArea, orElse: () => StationArea(stationId: '', name: '')).uid ?? _selectedArea;
      final payload = {
        'stationId': widget.stationId,
        'areaName': _selectedArea,
        'activityName': _activityCtrl.text.trim(),
        'areaId': areaId,
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

  Widget _photoCard(String label, String photoUrl, bool isBefore) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            if (isEdit && (widget.activityRecord?.status == DailyActivityStatus.completed || widget.activityRecord?.status == DailyActivityStatus.approved)) return;
            final url = await _capturePhoto();
            if (url != null) setState(() { if (isBefore) _beforePhoto = url; else _afterPhoto = url; });
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: photoUrl.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(photoUrl, fit: BoxFit.cover, width: double.infinity, height: 120))
                : const Center(child: Icon(Icons.add_a_photo, size: 36, color: Colors.grey)),
          ),
        ),
        if (!isEdit || (widget.activityRecord?.status != DailyActivityStatus.completed && widget.activityRecord?.status != DailyActivityStatus.approved))
          TextButton.icon(
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Capture', style: TextStyle(fontSize: 12)),
            onPressed: () async {
              final url = await _capturePhoto();
              if (url != null) setState(() { if (isBefore) _beforePhoto = url; else _afterPhoto = url; });
            },
          ),
      ],
    );
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
                      if (isEdit)
                        TextFormField(
                          initialValue: _selectedArea,
                          decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
                          readOnly: true,
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedArea.isNotEmpty ? _selectedArea : null,
                          decoration: const InputDecoration(labelText: 'Area *', border: OutlineInputBorder()),
                          items: _areas.isNotEmpty
                              ? _areas.map((a) => DropdownMenuItem(value: a.name, child: Text(a.name))).toList()
                              : [const DropdownMenuItem(value: '', child: Text('No areas configured', style: TextStyle(color: Colors.grey)))],
                          onChanged: (v) { if (v != null) setState(() => _selectedArea = v); },
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
                  Expanded(child: _photoCard('Before Photo', _beforePhoto, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _photoCard('After Photo', _afterPhoto, false)),
                ],
              ),
              if (_uploadingPhoto) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
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
