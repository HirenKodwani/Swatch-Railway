import 'dart:convert';
import 'package:crm_train/model/cleaning_form_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/auth_provider.dart';

class CleaningFormScreen extends StatefulWidget {
  final FormType formType;
  final String? editFormUid;

  const CleaningFormScreen({
    super.key,
    required this.formType,
    this.editFormUid,
  });

  @override
  State<CleaningFormScreen> createState() => _CleaningFormScreenState();
}

class _CleaningFormScreenState extends State<CleaningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _loadedFormUid;

  final _cleaningDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _manpowerController = TextEditingController();
  final _machineController = TextEditingController();
  final _remarksController = TextEditingController();

  final _trainNumberController = TextEditingController();
  final _trainNameController = TextEditingController();
  final _coachNumberController = TextEditingController();

  final _premiseNameController = TextEditingController();
  final _areaCoveredController = TextEditingController();
  final _areaUncleanedController = TextEditingController();
  final _garbageCollectedController = TextEditingController();

  String _cleaningShift = 'Morning';
  String _coachType = 'AC Chair Car';
  String _premiseType = 'Platform';

  bool _wateringDone = false;
  bool _toiletriesAvailable = false;
  bool _dustbinsAvailable = false;

  double _latitude = 0;
  double _longitude = 0;

  final List<String> _beforePhotos = [];
  final List<String> _afterPhotos = [];

  final Map<String, bool> _checkedActivities = {};

  String _appBarTitle = '';

  @override
  void initState() {
    super.initState();
    _appBarTitle = widget.formType == FormType.coach
        ? 'New Coach Cleaning Form'
        : 'New Premise Cleaning Form';

    final activities = widget.formType == FormType.coach
        ? cleaningActivities['coach']!
        : cleaningActivities['premise']!;
    for (final category in activities) {
      for (final item in category['items'] as List<String>) {
        _checkedActivities[item] = false;
      }
    }

    if (widget.editFormUid != null) {
      _loadExistingForm(widget.editFormUid!);
    }
  }

  Future<void> _loadExistingForm(String uid) async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getCleaningFormDetail(uid);
      final form = CleaningForm.fromJson(data['form']);

      _cleaningDateController.text = form.cleaningDate;
      _cleaningShift = form.cleaningShift;
      _startTimeController.text = form.startTime;
      _endTimeController.text = form.endTime;
      _manpowerController.text = form.manpowerCount.toString();
      _machineController.text = form.machineCount.toString();
      _remarksController.text = form.remarks;
      _latitude = form.latitude;
      _longitude = form.longitude;

      if (form.coachDetails != null) {
        _trainNumberController.text = form.coachDetails!['trainNumber'] ?? '';
        _trainNameController.text = form.coachDetails!['trainName'] ?? '';
        _coachNumberController.text = form.coachDetails!['coachNumber'] ?? '';
        _coachType = form.coachDetails!['coachType'] ?? 'AC Chair Car';
        _wateringDone = form.coachDetails!['wateringDone'] ?? false;
        _toiletriesAvailable = form.coachDetails!['toiletriesAvailable'] ?? false;
        _dustbinsAvailable = form.coachDetails!['dustbinsAvailable'] ?? false;
      }

      if (form.premiseDetails != null) {
        _premiseNameController.text = form.premiseDetails!['premiseName'] ?? '';
        _premiseType = form.premiseDetails!['premiseType'] ?? 'Platform';
        _areaCoveredController.text = (form.premiseDetails!['areaCovered'] ?? 0).toString();
        _areaUncleanedController.text = (form.premiseDetails!['areaUncleaned'] ?? 0).toString();
        _garbageCollectedController.text = (form.premiseDetails!['garbageCollected'] ?? 0).toString();
      }

      for (final photo in form.photos) {
        if (photo.type == 'before') {
          _beforePhotos.add(photo.url);
        } else {
          _afterPhotos.add(photo.url);
        }
      }

      if (form.scoringData != null && form.scoringData!['activities'] != null) {
        final savedActivities = form.scoringData!['activities'] as Map<String, dynamic>;
        for (final entry in savedActivities.entries) {
          if (_checkedActivities.containsKey(entry.key)) {
            _checkedActivities[entry.key] = entry.value as bool;
          }
        }
      }

      _loadedFormUid = form.uid;
      _appBarTitle = widget.formType == FormType.coach
          ? 'Edit Coach Cleaning Form'
          : 'Edit Premise Cleaning Form';
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading form: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cleaningDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _manpowerController.dispose();
    _machineController.dispose();
    _remarksController.dispose();
    _trainNumberController.dispose();
    _trainNameController.dispose();
    _coachNumberController.dispose();
    _premiseNameController.dispose();
    _areaCoveredController.dispose();
    _areaUncleanedController.dispose();
    _garbageCollectedController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFormData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    Map<String, dynamic>? coachDetails;
    Map<String, dynamic>? premiseDetails;

    if (widget.formType == FormType.coach) {
      coachDetails = {
        'trainNumber': _trainNumberController.text.trim(),
        'trainName': _trainNameController.text.trim(),
        'coachNumber': _coachNumberController.text.trim(),
        'coachType': _coachType,
        'wateringDone': _wateringDone,
        'toiletriesAvailable': _toiletriesAvailable,
        'dustbinsAvailable': _dustbinsAvailable,
      };
    } else {
      premiseDetails = {
        'premiseName': _premiseNameController.text.trim(),
        'premiseType': _premiseType,
        'areaCovered': double.tryParse(_areaCoveredController.text.trim()) ?? 0,
        'areaUncleaned': double.tryParse(_areaUncleanedController.text.trim()) ?? 0,
        'garbageCollected': double.tryParse(_garbageCollectedController.text.trim()) ?? 0,
      };
    }

    final photos = <Map<String, dynamic>>[
      ..._beforePhotos.map((url) => {
        'url': url,
        'type': 'before',
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': _latitude,
        'longitude': _longitude,
      }),
      ..._afterPhotos.map((url) => {
        'url': url,
        'type': 'after',
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': _latitude,
        'longitude': _longitude,
      }),
    ];

    final activitiesData = Map<String, dynamic>.from(_checkedActivities);

    return {
      if (_loadedFormUid != null) 'uid': _loadedFormUid,
      'formType': widget.formType.name,
      'division': user?.division ?? '',
      'depot': user?.depot ?? '',
      'contractId': user?.entityId ?? '',
      'entityId': user?.entityId ?? '',
      'entityName': user?.entityDetails?['companyName'] ?? user?.fullName ?? '',
      'submittedBy': user?.uid ?? '',
      'submittedByName': user?.fullName ?? '',
      'cleaningDate': _cleaningDateController.text.trim(),
      'cleaningShift': _cleaningShift,
      'startTime': _startTimeController.text.trim(),
      'endTime': _endTimeController.text.trim(),
      'manpowerCount': int.tryParse(_manpowerController.text.trim()) ?? 0,
      'machineCount': int.tryParse(_machineController.text.trim()) ?? 0,
      'remarks': _remarksController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'deviceId': '',
      'gpsAddress': '',
      'photos': photos,
      if (coachDetails != null) 'coachDetails': coachDetails,
      if (premiseDetails != null) 'premiseDetails': premiseDetails,
      'scoringData': {'activities': activitiesData},
    };
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = _buildFormData();
      if (_loadedFormUid != null) {
        await ApiService.saveCleaningFormDraft(_loadedFormUid!, data);
      } else {
        final result = await ApiService.createCleaningForm(data);
        final uid = result['form'] != null
            ? (result['form'] is Map ? result['form']['uid'] : result['uid'])
            : result['uid'];
        if (uid != null) {
          await ApiService.saveCleaningFormDraft(uid.toString(), data);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving draft: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final data = _buildFormData();
      String uid;
      if (_loadedFormUid != null) {
        uid = _loadedFormUid!;
        await ApiService.saveCleaningFormDraft(uid, data);
      } else {
        final result = await ApiService.createCleaningForm(data);
        uid = result['form'] != null
            ? (result['form'] is Map ? result['form']['uid'] : result['uid'])
            : result['uid'];
        if (uid == null) throw Exception('No UID returned from create');
        await ApiService.saveCleaningFormDraft(uid.toString(), data);
      }
      await ApiService.submitCleaningForm(uid.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _cleaningDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCommonFields(),
                    const SizedBox(height: 16),
                    if (widget.formType == FormType.coach)
                      _buildCoachFields()
                    else
                      _buildPremiseFields(),
                    const SizedBox(height: 16),
                    _buildGpsSection(),
                    const SizedBox(height: 16),
                    _buildPhotoSection(),
                    const SizedBox(height: 16),
                    _buildActivitiesSection(),
                    const SizedBox(height: 24),
                    _buildBottomButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kRailwayBlue)),
    );
  }

  Widget _buildCommonFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cleaning Details'),
            TextFormField(
              controller: _cleaningDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Cleaning Date *',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onTap: _pickDate,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _cleaningShift,
              decoration: InputDecoration(
                labelText: 'Cleaning Shift *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                DropdownMenuItem(value: 'Night', child: Text('Night')),
              ],
              onChanged: (v) => setState(() => _cleaningShift = v ?? 'Morning'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start Time *',
                      suffixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onTap: () => _pickTime(_startTimeController),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'End Time *',
                      suffixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onTap: () => _pickTime(_endTimeController),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _manpowerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Manpower Count *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _machineController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Machine Count',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Coach Details'),
            TextFormField(
              controller: _trainNumberController,
              decoration: InputDecoration(
                labelText: 'Train Number *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _trainNameController,
              decoration: InputDecoration(
                labelText: 'Train Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coachNumberController,
              decoration: InputDecoration(
                labelText: 'Coach Number *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _coachType,
              decoration: InputDecoration(
                labelText: 'Coach Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'AC Chair Car', child: Text('AC Chair Car')),
                DropdownMenuItem(value: 'Sleeper', child: Text('Sleeper')),
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'AC 3 Tier', child: Text('AC 3 Tier')),
                DropdownMenuItem(value: 'AC 2 Tier', child: Text('AC 2 Tier')),
                DropdownMenuItem(value: 'First AC', child: Text('First AC')),
              ],
              onChanged: (v) => setState(() => _coachType = v ?? 'AC Chair Car'),
            ),
            const SizedBox(height: 16),
            const Text('Amenities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Watering Done'),
              value: _wateringDone,
              onChanged: (v) => setState(() => _wateringDone = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Toiletries Available'),
              value: _toiletriesAvailable,
              onChanged: (v) => setState(() => _toiletriesAvailable = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Dustbins Available'),
              value: _dustbinsAvailable,
              onChanged: (v) => setState(() => _dustbinsAvailable = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiseFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Premise Details'),
            TextFormField(
              controller: _premiseNameController,
              decoration: InputDecoration(
                labelText: 'Premise Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _premiseType,
              decoration: InputDecoration(
                labelText: 'Premise Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Platform', child: Text('Platform')),
                DropdownMenuItem(value: 'Office', child: Text('Office')),
                DropdownMenuItem(value: 'Waiting Hall', child: Text('Waiting Hall')),
                DropdownMenuItem(value: 'Staircase', child: Text('Staircase')),
                DropdownMenuItem(value: 'Track Area', child: Text('Track Area')),
                DropdownMenuItem(value: 'Pit Area', child: Text('Pit Area')),
              ],
              onChanged: (v) => setState(() => _premiseType = v ?? 'Platform'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaCoveredController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Area Covered (sq m)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _areaUncleanedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Area Uncleaned (sq m)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _garbageCollectedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Garbage Collected (kg)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('GPS Location'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: kRailwayBlue, size: 20),
                      const SizedBox(width: 8),
                      Text('Latitude: ', style: TextStyle(color: Colors.grey.shade600)),
                      Text(_latitude.toStringAsFixed(4), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      Text('Longitude: ', style: TextStyle(color: Colors.grey.shade600)),
                      Text(_longitude.toStringAsFixed(4), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _latitude = 12.9716;
                          _longitude = 77.5946;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location set to default (Bangalore)'),
                            backgroundColor: kRailwayBlue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Get Current Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kRailwayBlue,
                        side: const BorderSide(color: kRailwayBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Photos'),
            _buildPhotoList('Before Photos', _beforePhotos),
            const SizedBox(height: 12),
            _buildPhotoList('After Photos', _afterPhotos),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoList(String label, List<String> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  photos.add('placeholder_${photos.length + 1}.jpg');
                });
              },
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Add Photo'),
            ),
          ],
        ),
        if (photos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No photos added', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photos.asMap().entries.map((entry) {
              final idx = entry.key;
              final url = entry.value;
              return Chip(
                label: Text('Photo ${idx + 1}', style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => photos.removeAt(idx)),
                avatar: CircleAvatar(
                  backgroundColor: kRailwayBlue.withOpacity(0.1),
                  child: const Icon(Icons.image, size: 14, color: kRailwayBlue),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    final activities = widget.formType == FormType.coach
        ? cleaningActivities['coach']!
        : cleaningActivities['premise']!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Activities Checklist'),
            ...activities.map((category) => _buildCategoryGroup(
                  category['category'] as String,
                  (category['items'] as List<String>),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(String category, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kRailwayBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kRailwayBlue)),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => CheckboxListTile(
                title: Text(item, style: const TextStyle(fontSize: 14)),
                value: _checkedActivities[item] ?? false,
                onChanged: (v) => setState(() => _checkedActivities[item] = v ?? false),
                contentPadding: const EdgeInsets.only(left: 8),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              )),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_isSaving || _isSubmitting) ? null : _saveDraft,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save Draft'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kRailwayBlue,
              side: const BorderSide(color: kRailwayBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isSaving || _isSubmitting) ? null : _submitForm,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 18),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit for Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRailwayBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
