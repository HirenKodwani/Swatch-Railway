import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/model/platform_model.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/model/boq_data.dart';
import 'package:crm_train/providers/auth_provider.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'package:crm_train/repositories/station_cleaning_repository.dart';

final _boqMainAreas = (() {
  final set = <String>{};
  for (final item in boqData) {
    set.add(item.mainArea);
  }
  final list = set.toList()..sort((a, b) {
    final sa = int.tryParse(a.split(' ').first) ?? 99;
    final sb = int.tryParse(b.split(' ').first) ?? 99;
    return sa.compareTo(sb);
  });
  return list;
})();

Map<String, List<BoqItem>> get _boqGrouped {
  final map = <String, List<BoqItem>>{};
  for (final item in boqData) {
    map.putIfAbsent(item.mainArea, () => []);
    map[item.mainArea]!.add(item);
  }
  return map;
}

double _calcTendered(double basicAreaSqFt, String frequencyType, int boqTimesPerPeriod) {
  final area = basicAreaSqFt;
  final times = boqTimesPerPeriod;
  switch (frequencyType.toLowerCase()) {
    case 'monthly': return (area * times) / 30;
    case 'weekly': return (area * times) / 7;
    case 'daily':
    default: return area * times;
  }
}

class AreaFormScreen extends StatefulWidget {
  final String stationId;
  final String? platformId;
  final String? platformName;
  final List<Platform>? platforms;
  final Map<String, dynamic>? existingArea;
  final List<StationArea>? allStationAreas;
  const AreaFormScreen({super.key, required this.stationId, this.platformId, this.platformName, this.platforms, this.existingArea, this.allStationAreas});

  @override
  State<AreaFormScreen> createState() => _AreaFormScreenState();
}

class _AreaFormScreenState extends State<AreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _useCustomMain = false;
  bool _useCustomSub = false;

  final _customMainCtrl = TextEditingController();
  final _customSubCtrl = TextEditingController();
  final _basicCtrl = TextEditingController();
  final _timesCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');

  String _selectedMainArea = '';
  String _selectedSubArea = '';
  String _frequencyType = 'daily';
  bool _active = true;
  String? _selectedPlatformId;

  @override
  void initState() {
    super.initState();
    final e = widget.existingArea;
    if (e != null) {
      _selectedMainArea = e['mainArea'] as String? ?? '';
      _selectedSubArea = e['areaName'] as String? ?? e['name'] as String? ?? '';
      _frequencyType = e['frequencyType'] as String? ?? 'daily';
      _basicCtrl.text = (e['basicAreaSqFt'] as num?)?.toString() ?? '';
      _timesCtrl.text = ((e['boqTimesPerPeriod'] as num?)?.toInt() ?? 1).toString();
      _descCtrl.text = e['description'] ?? '';
      _orderCtrl.text = '${e['order'] ?? 0}';
      _active = e['active'] ?? true;

      if (_selectedMainArea.isNotEmpty && !_boqMainAreas.contains(_selectedMainArea)) {
        _useCustomMain = true;
        _customMainCtrl.text = _selectedMainArea;
      }
      if (_selectedMainArea.isNotEmpty && _boqGrouped[_selectedMainArea]?.any((i) => i.subArea == _selectedSubArea) != true) {
        _useCustomSub = true;
        _customSubCtrl.text = _selectedSubArea;
      }
    }
    if (widget.platforms != null && widget.platformId != null) {
      final matched = widget.platforms!.where((p) => p.uid == widget.platformId).firstOrNull;
      _selectedPlatformId = matched?.uid;
    }
    _selectedPlatformId ??= (widget.platforms != null && widget.platforms!.isNotEmpty) ? widget.platforms!.first.uid : widget.platformId;
  }

  @override
  void dispose() {
    _customMainCtrl.dispose();
    _customSubCtrl.dispose();
    _basicCtrl.dispose();
    _timesCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  double _calcTenderedArea() {
    final basic = double.tryParse(_basicCtrl.text) ?? 0;
    final times = int.tryParse(_timesCtrl.text) ?? 1;
    return _calcTendered(basic, _frequencyType, times);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mainArea = _useCustomMain ? _customMainCtrl.text.trim() : _selectedMainArea;
    final subArea = _useCustomSub ? _customSubCtrl.text.trim() : _selectedSubArea;
    if (mainArea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Main area is required'), backgroundColor: kErrorRed));
      return;
    }
    if (subArea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sub-area name is required'), backgroundColor: kErrorRed));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'stationId': widget.stationId,
        'areaName': subArea,
        'mainArea': mainArea,
        'basicAreaSqFt': double.tryParse(_basicCtrl.text) ?? 0,
        'frequencyType': _frequencyType,
        'boqTimesPerPeriod': int.tryParse(_timesCtrl.text) ?? 1,
        'description': _descCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 0,
        'active': _active,
        'platformId': _selectedPlatformId ?? widget.platformId,
      };

      if (widget.existingArea != null) {
        final uid = widget.existingArea!['uid'] ?? widget.existingArea!['id'];
        await StationCleaningRepository.updateArea(uid, data);
      } else {
        await StationCleaningRepository.createArea(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingArea != null ? 'Area updated' : 'Area created'), backgroundColor: kSuccessGreen),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: kErrorRed));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingArea != null;
    final tendered = _calcTenderedArea();

    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? 'Edit' : 'Add'} Area', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              Text(isEdit ? 'Edit Area Details' : 'Add Area', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (widget.platforms != null && widget.platforms!.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: widget.platforms!.any((p) => p.uid == _selectedPlatformId) ? _selectedPlatformId : null,
                  decoration: const InputDecoration(
                    labelText: 'Platform', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.view_quilt),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: widget.platforms!.map((p) => DropdownMenuItem(value: p.uid, child: Text(p.displayName))).toList(),
                  onChanged: (v) => setState(() => _selectedPlatformId = v),
                ),
                const SizedBox(height: 12),
              ],
              if (!_useCustomMain)
                DropdownButtonFormField<String>(
                  value: _selectedMainArea.isNotEmpty && _boqMainAreas.contains(_selectedMainArea) ? _selectedMainArea : null,
                  decoration: const InputDecoration(
                    labelText: 'Main Area', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    ..._boqMainAreas.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem(value: '__custom__', child: Text('+ Custom', style: TextStyle(color: Colors.blue))),
                  ],
                  onChanged: (v) {
                    if (v == '__custom__') {
                      setState(() {
                        _useCustomMain = true;
                        _selectedMainArea = '';
                        _selectedSubArea = '';
                      });
                    } else {
                      setState(() {
                        _selectedMainArea = v!;
                        _selectedSubArea = '';
                        _basicCtrl.clear();
                        _timesCtrl.text = '1';
                        _frequencyType = 'daily';
                      });
                    }
                  },
                ),
              if (_useCustomMain)
                TextField(
                  controller: _customMainCtrl,
                  decoration: InputDecoration(
                    labelText: 'Main Area (custom)', border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _useCustomMain = false;
                        _customMainCtrl.clear();
                        _selectedMainArea = _boqMainAreas.isNotEmpty ? _boqMainAreas.first : '';
                      }),
                    ),
                  ),
                  onChanged: (v) => _selectedMainArea = v,
                ),
              const SizedBox(height: 12),
              if (_selectedMainArea.isNotEmpty && _boqGrouped.containsKey(_selectedMainArea) && !_useCustomMain && !_useCustomSub)
                DropdownButtonFormField<String>(
                  value: _selectedSubArea.isNotEmpty && _boqGrouped[_selectedMainArea]!.any((i) => i.subArea == _selectedSubArea) ? _selectedSubArea : null,
                  decoration: const InputDecoration(
                    labelText: 'Sub-area', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    ..._boqGrouped[_selectedMainArea]!.map((i) => DropdownMenuItem(value: i.subArea, child: Text(i.subArea, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem(value: '__custom_sub__', child: Text('+ Custom', style: TextStyle(color: Colors.blue))),
                  ],
                  onChanged: (v) {
                    if (v == '__custom_sub__') {
                      setState(() => _useCustomSub = true);
                    } else {
                      final item = _boqGrouped[_selectedMainArea]!.firstWhere((i) => i.subArea == v);
                      setState(() {
                        _selectedSubArea = v!;
                        _basicCtrl.text = item.basicAreaSqFt.toString();
                        _timesCtrl.text = item.boqTimesPerPeriod.toString();
                        _frequencyType = item.frequencyType;
                      });
                    }
                  },
                ),
              if (_useCustomSub || (_selectedMainArea.isNotEmpty && !_boqGrouped.containsKey(_selectedMainArea)))
                TextField(
                  controller: _customSubCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sub-area Name', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                  onChanged: (v) => _selectedSubArea = v,
                ),
              if (!_useCustomSub && !_useCustomMain && _selectedMainArea.isNotEmpty && _boqGrouped.containsKey(_selectedMainArea) && _selectedSubArea.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _boqGrouped[_selectedMainArea]!.firstWhere((i) => i.subArea == _selectedSubArea).frequencyDescription,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _basicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Basic Area (sq.ft.)', border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.square_foot),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _frequencyType,
                      decoration: const InputDecoration(
                        labelText: 'Frequency', border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      ],
                      onChanged: (v) => setState(() => _frequencyType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Times per Period', border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRailwayBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kRailwayBlue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate, color: kRailwayBlue),
                    const SizedBox(width: 8),
                    Text('Tendered/day: ${tendered.toStringAsFixed(tendered == tendered.roundToDouble() ? 0 : 1)} sq.ft.',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderCtrl,
                decoration: const InputDecoration(labelText: 'Display Order', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sort)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeColor: kRailwayBlue,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: kRailwayBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Update Area' : 'Create Area'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
