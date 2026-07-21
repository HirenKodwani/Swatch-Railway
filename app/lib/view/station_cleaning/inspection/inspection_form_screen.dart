import 'dart:convert';
import 'dart:io';
import 'package:crm_train/model/platform_model.dart';
import 'package:crm_train/model/station_cleaning_models.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/repositories/inspection_repository.dart';
import 'package:crm_train/repositories/platform_repository.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late TextEditingController _defDescCtrl;
  late TextEditingController _defAssignedToCtrl;
  late TextEditingController _closeProofCtrl;

  String _inspectionType = 'ad_hoc';
  DateTime _scheduledDate = DateTime.now();
  String? _selectedArea;
  String? _selectedPlatformId;
  String? _selectedDefArea;
  List<StationArea> _areas = [];
  List<Platform> _platforms = [];
  bool _areasLoading = false;
  bool _platformsLoading = false;

  int _cleanliness = 3;
  int _hygiene = 3;
  int _infrastructure = 3;
  int _safety = 3;

  String _defSeverity = 'medium';

  List<File> _photos = [];
  bool _uploadingPhoto = false;

  bool get isEdit => widget.inspection != null;
  String get _currentStatus => widget.inspection?.status ?? '';

  @override
  void initState() {
    super.initState();
    final r = widget.inspection;
    _inspectorNameCtrl = TextEditingController(text: r?.inspectorName ?? '');
    _remarksCtrl = TextEditingController(text: r?.remarks ?? '');
    _defDescCtrl = TextEditingController();
    _defAssignedToCtrl = TextEditingController();
    _closeProofCtrl = TextEditingController();
    _selectedArea = r?.areaId;
    _scheduledDate = DateTime.tryParse(r?.scheduledDate ?? '') ?? DateTime.now();

    if (r != null) {
      _inspectionType = r.inspectionType;
      if (r.ratings.isNotEmpty) {
        _cleanliness = r.ratings['cleanliness'] ?? 3;
        _hygiene = r.ratings['hygiene'] ?? 3;
        _infrastructure = r.ratings['infrastructure'] ?? 3;
        _safety = r.ratings['safety'] ?? 3;
      }
    }
    _loadAreas();
    _loadPlatforms();
  }

  Future<void> _loadAreas() async {
    setState(() => _areasLoading = true);
    try {
      final raw = await ApiService.getStationAreas(widget.stationId);
      final seen = <String>{};
      _areas = [];
      for (final a in raw) {
        final key = a.name.trim();
        if (key.isNotEmpty && seen.add(key)) _areas.add(StationArea(uid: a.uid, stationId: a.stationId, name: a.name, order: a.order, description: a.description, active: a.active, platformId: a.platformId));
      }
      if (_selectedArea != null && _areas.indexWhere((a) => a.name == _selectedArea) == -1) {
        _selectedArea = null;
      }
      final area = _areaByName(_selectedArea ?? '');
      if (area?.platformId != null && area!.platformId != _selectedPlatformId) {
        _selectedPlatformId = area.platformId;
      }
    } catch (_) {}
    if (mounted) setState(() => _areasLoading = false);
  }

  StationArea? _areaByName(String name) {
    final idx = _areas.indexWhere((a) => a.name == name);
    return idx >= 0 ? _areas[idx] : null;
  }

  List<Platform> get _filteredPlatforms {
    final area = _areaByName(_selectedArea ?? '');
    if (area == null || area.platformId == null) return _platforms;
    return _platforms.where((p) => p.uid == area.platformId).toList();
  }

  Future<void> _loadPlatforms() async {
    setState(() => _platformsLoading = true);
    try {
      _platforms = await PlatformRepository.getByStation(widget.stationId);
    } catch (_) {}
    if (mounted) setState(() => _platformsLoading = false);
  }

  @override
  void dispose() {
    _inspectorNameCtrl.dispose();
    _remarksCtrl.dispose();
    _defDescCtrl.dispose();
    _defAssignedToCtrl.dispose();
    _closeProofCtrl.dispose();
    super.dispose();
  }

  Future<String?> _pickAndUploadPhoto() async {
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
        body: jsonEncode({
          'image': base64Encode(bytes),
          'fileName': 'inspection_${DateTime.now().millisecondsSinceEpoch}.jpg',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] ?? data['imageUrl'] ?? '';
      }
    } catch (_) {}
    setState(() => _uploadingPhoto = false);
    return null;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final formattedDate = "${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}";
      final payload = {
        'stationId': widget.stationId,
        'areaId': _selectedArea,
        'platformId': _selectedPlatformId,
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
        'cleanliness': _cleanliness,
        'hygiene': _hygiene,
        'infrastructure': _infrastructure,
        'safety': _safety,
      };
      List<String> photoUrls = [];
      final token = await _getToken();
      for (final photo in _photos) {
        if (token == null) break;
        final bytes = await photo.readAsBytes();
        final resp = await http.post(
          Uri.parse('${ApiService.baseUrl}/api/evidence/upload/base64'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'image': base64Encode(bytes), 'fileName': 'rating_${DateTime.now().millisecondsSinceEpoch}.jpg'}),
        );
        if (resp.statusCode == 200) {
          final d = jsonDecode(resp.body);
          photoUrls.add(d['url'] ?? d['imageUrl'] ?? '');
        }
      }
      await InspectionRepository.submitRatings(widget.inspection!.uid, {
        'ratings': ratings,
        'photos': photoUrls.isNotEmpty ? photoUrls : (widget.inspection?.photos ?? []),
        'remarks': _remarksCtrl.text.trim(),
      });
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

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await InspectionRepository.approveInspection(widget.inspection!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection approved'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final rejected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Inspection'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Rejection Reason *', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => reasonCtrl.text.trim().isEmpty ? null : Navigator.pop(ctx, reasonCtrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (rejected == null || rejected.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await InspectionRepository.rejectInspection(widget.inspection!.uid, rejected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection rejected'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resubmit() async {
    setState(() => _isLoading = true);
    try {
      await InspectionRepository.resubmitInspection(widget.inspection!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection resubmitted'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyDeficiency(Deficiency def) async {
    try {
      await InspectionRepository.verifyDeficiency(widget.inspection!.uid, def.defId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deficiency verified'), backgroundColor: kSuccessGreen),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: kErrorRed),
        );
      }
    }
  }

  Future<void> _pickRatingPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _addDeficiency() {
    _defDescCtrl.clear();
    _defAssignedToCtrl.clear();
    _selectedDefArea = null;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Deficiency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_areas.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedDefArea != null && _areas.any((a) => a.name == _selectedDefArea) ? _selectedDefArea : null,
                  decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Select Area')),
                    ..._areas.map<DropdownMenuItem<String>>((a) => DropdownMenuItem(value: a.name, child: Text(a.name))),
                  ],
                  onChanged: (v) => _selectedDefArea = v,
                )
              else
                TextField(
                  decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
                  onChanged: (v) => _selectedDefArea = v,
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
              if ((_selectedDefArea == null || _selectedDefArea!.isEmpty) || _defDescCtrl.text.trim().isEmpty) return;
              try {
                await InspectionRepository.addDeficiency(widget.inspection!.uid, {
                  'area': _selectedDefArea,
                  'description': _defDescCtrl.text.trim(),
                  'severity': _defSeverity,
                  'assignedTo': _defAssignedToCtrl.text.trim(),
                });
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _closeProofCtrl,
              decoration: const InputDecoration(labelText: 'Proof Photo URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final url = await _pickAndUploadPhoto();
                if (url != null) _closeProofCtrl.text = url;
              },
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Capture Photo'),
            ),
          ],
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

  Widget _buildRatingSelector(String label, int value, ValueChanged<int> onChanged) {
    final labels = ['Poor', 'Below Avg', 'Average', 'Good', 'Excellent'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final idx = i + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(idx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: idx <= value ? kRailwayBlue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: idx <= value ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _hasPermission(String permission) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return false;
    final role = (user.role ?? '').toUpperCase().replaceAll(' ', '_');
    const rolePerms = {
      'SUPER_ADMIN': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'COMPANY_MASTER': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'RAILWAY_MASTER': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'ADMIN': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'RAILWAY_ADMIN': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'STATION_MASTER': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'AREA_MASTER': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'PLATFORM_MASTER': {'VIEW'},
      'RAILWAY_SUPERVISOR': {'VIEW', 'SCORE'},
      'CONTRACTOR_MASTER': {'MANAGE', 'VIEW', 'APPROVE', 'SCORE'},
      'CONTRACTOR_ADMIN': {'VIEW'},
      'CONTRACTOR_SUPERVISOR': {'VIEW'},
    };
    return (rolePerms[role] ?? <String>{}).contains(permission);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.inspection;
    final canManage = _hasPermission('MANAGE');
    final canApprove = _hasPermission('APPROVE');
    final canScore = _hasPermission('SCORE');
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
                          DropdownMenuItem(value: 'ad_hoc', child: Text('Ad Hoc')),
                          DropdownMenuItem(value: 'routine', child: Text('Routine')),
                          DropdownMenuItem(value: 'surprise', child: Text('Surprise')),
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'monthly_review', child: Text('Monthly Review')),
                          DropdownMenuItem(value: 'petty_issue_linked', child: Text('Petty Issue Linked')),
                          DropdownMenuItem(value: 'cleanliness_scorecard', child: Text('Cleanliness Scorecard')),
                          DropdownMenuItem(value: 'complaint_based', child: Text('Complaint Based')),
                          DropdownMenuItem(value: 'random', child: Text('Random')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                        ],
                        onChanged: isEdit ? null : (v) {
                          if (v != null) setState(() => _inspectionType = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_areasLoading)
                        const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      else
                        DropdownButtonFormField<String>(
                          value: _areas.where((a) => a.name == _selectedArea).length == 1 ? _selectedArea : null,
                          decoration: const InputDecoration(labelText: 'Area *', border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Select Area')),
                            ..._areas.map<DropdownMenuItem<String>>((a) => DropdownMenuItem(value: a.name, child: Text(a.name))),
                          ],
                          onChanged: isEdit ? null : (v) {
                            setState(() {
                              _selectedArea = v;
                              final area = _areaByName(v ?? '');
                              _selectedPlatformId = area?.platformId;
                            });
                          },
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      const SizedBox(height: 12),
                      if (_platformsLoading)
                        const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedPlatformId == null || _filteredPlatforms.where((p) => p.uid == _selectedPlatformId).length == 1 ? _selectedPlatformId : null,
                          decoration: const InputDecoration(labelText: 'Platform (optional)', border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('None')),
                            ..._filteredPlatforms.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p.uid, child: Text(p.displayName))),
                          ],
                          onChanged: isEdit ? null : (v) => setState(() => _selectedPlatformId = v),
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
              if (r != null && _currentStatus == 'IN_PROGRESS' && canScore) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Submit Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildRatingSelector('Cleanliness', _cleanliness, (v) => setState(() => _cleanliness = v)),
                        _buildRatingSelector('Hygiene', _hygiene, (v) => setState(() => _hygiene = v)),
                        _buildRatingSelector('Infrastructure', _infrastructure, (v) => setState(() => _infrastructure = v)),
                        _buildRatingSelector('Safety', _safety, (v) => setState(() => _safety = v)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _uploadingPhoto ? null : _pickRatingPhoto,
                              icon: _uploadingPhoto
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.camera_alt, size: 18),
                              label: Text(_photos.isEmpty ? 'Add Photos' : '${_photos.length} photo(s)'),
                            ),
                            if (_photos.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ..._photos.map((f) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(f, width: 40, height: 40, fit: BoxFit.cover),
                                ),
                              )),
                            ],
                          ],
                        ),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (def.closureStatus == DeficiencyStatus.open && canManage)
                              TextButton(
                                onPressed: () => _closeDeficiency(def),
                                child: const Text('Close'),
                              ),
                            if (def.closureStatus == DeficiencyStatus.closed && canApprove)
                              TextButton(
                                onPressed: () => _verifyDeficiency(def),
                                child: const Text('Verify', style: TextStyle(color: Colors.blue)),
                              ),
                            if (def.closureStatus == DeficiencyStatus.railwayVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kSuccessGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: kSuccessGreen),
                                ),
                                child: const Text('VERIFIED', style: TextStyle(color: kSuccessGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    )),
              ],
              if (r != null && (_currentStatus == 'IN_PROGRESS' || _currentStatus == 'COMPLETED') && canManage) ...[
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
                if (!isEdit && canManage)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white),
                      child: const Text('Create Inspection'),
                    ),
                  ),
                if (isEdit && _currentStatus == 'SCHEDULED' && canManage)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _startInspection,
                      style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                      child: const Text('Start Inspection'),
                    ),
                  ),
                if (isEdit && _currentStatus == 'COMPLETED' && canApprove)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _approve,
                              style: ElevatedButton.styleFrom(backgroundColor: kSuccessGreen, foregroundColor: Colors.white),
                              child: const Text('Approve'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _reject,
                              style: ElevatedButton.styleFrom(backgroundColor: kErrorRed, foregroundColor: Colors.white),
                              child: const Text('Reject'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isEdit && _currentStatus == 'REJECTED' && canScore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _resubmit,
                        style: ElevatedButton.styleFrom(backgroundColor: kWarningOrange, foregroundColor: Colors.white),
                        child: const Text('Resubmit Inspection'),
                      ),
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
