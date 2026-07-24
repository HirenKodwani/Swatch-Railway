import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/repositories/worker_repo.dart';
import 'package:crm_train/utills/app_colors.dart';

class ShiftSummaryScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String supervisorId;
  final String supervisorName;
  final String shift;
  final String date;
  final List<Map<String, dynamic>> areas;

  const ShiftSummaryScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.supervisorId,
    required this.supervisorName,
    required this.shift,
    required this.date,
    required this.areas,
  });

  @override
  State<ShiftSummaryScreen> createState() => _ShiftSummaryScreenState();
}

class _ShiftSummaryScreenState extends State<ShiftSummaryScreen> {
  final _picker = ImagePicker();
  bool _isSubmitting = false;
  late Map<String, XFile?> _areaPhotos;

  @override
  void initState() {
    super.initState();
    _areaPhotos = {for (var a in widget.areas) (a['uid'] ?? a['areaId'] ?? a['areaName']) as String: null};
  }

  bool get _allPhotosTaken => _areaPhotos.values.every((p) => p != null);
  int get _takenCount => _areaPhotos.values.where((p) => p != null).length;

  Future<void> _takePhoto(String key) async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1280);
    if (photo != null) {
      setState(() => _areaPhotos[key] = photo);
    }
  }

  Future<void> _submit() async {
    if (!_allPhotosTaken) return;
    setState(() => _isSubmitting = true);
    try {
      final areasPayload = <Map<String, dynamic>>[];
      for (final a in widget.areas) {
        final key = (a['uid'] ?? a['areaId'] ?? a['areaName']) as String;
        final photo = _areaPhotos[key];
        if (photo == null) continue;
        final photoUrl = await WorkerRepository.uploadMedia(photo.path);
        areasPayload.add({
          'areaId': a['areaId'] ?? a['uid'] ?? '',
          'areaName': a['areaName'] ?? '',
          'photoUrl': photoUrl,
          'scheduledTime': a['scheduledTime'] ?? '',
          'taskId': a['uid'] ?? a['taskId'] ?? null,
        });
      }

      await ApiService.submitShiftSummary({
        'supervisorId': widget.supervisorId,
        'supervisorName': widget.supervisorName,
        'stationId': widget.stationId,
        'stationName': widget.stationName,
        'date': widget.date,
        'shift': widget.shift,
        'areas': areasPayload,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift summary submitted!'), backgroundColor: kSuccessGreen),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Shift Summary — ${widget.stationName}'),
        backgroundColor: kRailwayBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: kRailwayBlue.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.shift} Shift — ${widget.date}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${widget.areas.length} area(s) — $_takenCount photos taken',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.areas.length,
              itemBuilder: (ctx, i) {
                final a = widget.areas[i];
                final key = (a['uid'] ?? a['areaId'] ?? a['areaName']) as String;
                final photo = _areaPhotos[key];
                final areaName = a['areaName'] ?? '';
                final time = a['scheduledTime'] ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cleaning_services, size: 20, color: kRailwayBlue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(areaName, style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (photo != null)
                          Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(image: FileImage(File(photo.path)), fit: BoxFit.cover),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to take photo', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(photo != null ? Icons.refresh : Icons.camera_alt, size: 16),
                            label: Text(photo != null ? 'Retake' : 'Take Photo'),
                            onPressed: () => _takePhoto(key),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: photo != null ? Colors.green[100] : kRailwayBlue,
                              foregroundColor: photo != null ? Colors.green[800] : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle),
                  label: Text(_isSubmitting
                      ? 'Submitting...'
                      : _allPhotosTaken
                          ? 'Submit Summary (${widget.areas.length} photos)'
                          : 'Take all ${widget.areas.length - _takenCount} remaining photo(s)'),
                  onPressed: (_allPhotosTaken && !_isSubmitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccessGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
