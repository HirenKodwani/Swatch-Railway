import 'package:flutter/material.dart';
import 'package:crm_train/model/boq_data.dart';
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

class AreaFormScreen extends StatefulWidget {
  final String stationId;
  final Map<String, dynamic>? existingArea;
  const AreaFormScreen({super.key, required this.stationId, this.existingArea});

  @override
  State<AreaFormScreen> createState() => _AreaFormScreenState();
}

class _AreaFormScreenState extends State<AreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _useCustomMain = false;

  final _customMainCtrl = TextEditingController();
  final _customSubCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');

  String _selectedMainArea = '';
  final Set<String> _selectedSubAreas = {};
  bool _active = true;
  @override
  void initState() {
    super.initState();
    final e = widget.existingArea;
    if (e != null) {
      _selectedMainArea = e['mainArea'] as String? ?? '';
      _selectedSubAreas.add(e['areaName'] as String? ?? e['name'] as String? ?? '');
      _descCtrl.text = e['description'] ?? '';
      _orderCtrl.text = '${e['order'] ?? 0}';
      _active = e['active'] ?? true;
      if (_selectedMainArea.isNotEmpty && !_boqMainAreas.contains(_selectedMainArea)) {
        _useCustomMain = true;
        _customMainCtrl.text = _selectedMainArea;
      }
    }
  }

  @override
  void dispose() {
    _customMainCtrl.dispose();
    _customSubCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mainArea = _useCustomMain ? _customMainCtrl.text.trim() : _selectedMainArea;
    if (mainArea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Main area is required'), backgroundColor: kErrorRed));
      return;
    }

    final allSubAreas = <String>[..._selectedSubAreas];
    if (_customSubCtrl.text.trim().isNotEmpty) {
      allSubAreas.addAll(_customSubCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    if (allSubAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one sub-area'), backgroundColor: kErrorRed));
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final subArea in allSubAreas) {
        BoqItem? matched;
        if (_boqGrouped.containsKey(mainArea)) {
          matched = _boqGrouped[mainArea]!.where((i) => i.subArea == subArea).firstOrNull;
        }

        final data = {
          'stationId': widget.stationId,
          'areaName': subArea,
          'mainArea': mainArea,
          'basicAreaSqFt': matched?.basicAreaSqFt ?? 0,
          'frequencyType': matched?.frequencyType ?? 'daily',
          'boqTimesPerPeriod': matched?.boqTimesPerPeriod ?? 1,
          'tenderedAreaPerDay': matched?.tenderedAreaPerDay ?? 0,
          'description': _descCtrl.text.trim(),
          'order': int.tryParse(_orderCtrl.text) ?? 0,
          'active': _active,
        };

        if (widget.existingArea != null) {
          final uid = widget.existingArea!['uid'] ?? widget.existingArea!['id'];
          await StationCleaningRepository.updateArea(uid, data);
          break;
        } else {
          await StationCleaningRepository.createArea(data);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingArea != null ? 'Area updated' : 'Areas created'), backgroundColor: kSuccessGreen),
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
    final List<BoqItem> subItems = _selectedMainArea.isNotEmpty && _boqGrouped.containsKey(_selectedMainArea)
        ? _boqGrouped[_selectedMainArea]!
        : [];

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
                        _selectedSubAreas.clear();
                      });
                    } else {
                      setState(() {
                        _selectedMainArea = v!;
                        _selectedSubAreas.clear();
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
                        _selectedSubAreas.clear();
                      }),
                    ),
                  ),
                  onChanged: (v) => _selectedMainArea = v,
                ),
              const SizedBox(height: 16),
              if (subItems.isNotEmpty) ...[
                const Text('Select Sub-areas (max 2):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: subItems.map((item) {
                    final isSelected = _selectedSubAreas.contains(item.subArea);
                    final canSelect = !isSelected && _selectedSubAreas.length >= 2;
                    return FilterChip(
                      label: Text(item.subArea, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: canSelect && !isSelected ? null : (v) {
                        setState(() {
                          if (v) {
                            if (_selectedSubAreas.length < 2) {
                              _selectedSubAreas.add(item.subArea);
                            }
                          } else {
                            _selectedSubAreas.remove(item.subArea);
                          }
                        });
                      },
                      selectedColor: kRailwayBlue.withOpacity(0.2),
                      checkmarkColor: kRailwayBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? kRailwayBlue : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                for (final sub in _selectedSubAreas) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kRailwayBlue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kRailwayBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: () {
                              final item = subItems.where((i) => i.subArea == sub).firstOrNull;
                              if (item == null) return [Text(sub)];
                              return [
                                Text(sub, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Basic: ${item.basicAreaSqFt.toStringAsFixed(item.basicAreaSqFt == item.basicAreaSqFt.roundToDouble() ? 0 : 1)} sq.ft. | ${item.frequencyType} ${item.boqTimesPerPeriod}x | Tendered/day: ${item.tenderedAreaPerDay.toStringAsFixed(item.tenderedAreaPerDay == item.tenderedAreaPerDay.roundToDouble() ? 0 : 1)} sq.ft.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ];
                            }(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: kErrorRed),
                          onPressed: () => setState(() => _selectedSubAreas.remove(sub)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                const Divider(),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _customSubCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custom Sub-area (comma-separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_box),
                  hintText: 'e.g. Extra Room A, Store Room',
                ),
              ),
              const SizedBox(height: 16),
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
                      : Text(isEdit ? 'Update Area' : 'Create Areas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
