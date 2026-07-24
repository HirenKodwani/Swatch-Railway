import 'package:flutter/material.dart';
import 'package:crm_train/model/platform_model.dart';
import 'package:crm_train/repositories/platform_repository.dart';
import 'package:crm_train/repositories/station_cleaning_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

double _calcTendered(double basicAreaSqFt, String frequencyType, int frequencyTimes) {
  final area = basicAreaSqFt;
  final times = frequencyTimes;
  switch (frequencyType.toLowerCase()) {
    case 'monthly':
      return (area * times) / 30;
    case 'weekly':
      return (area * times) / 7;
    case 'daily':
    default:
      return area * times;
  }
}

String _num(dynamic v) {
  if (v == null) return '-';
  final n = (v is num) ? v : double.tryParse(v.toString()) ?? 0;
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1);
}

class AreaConfigScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String? platformId;

  const AreaConfigScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    this.platformId,
  });

  @override
  State<AreaConfigScreen> createState() => _AreaConfigScreenState();
}

class _AreaConfigScreenState extends State<AreaConfigScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _areas = [];
  List<Platform> _platforms = [];
  Platform? _selectedPlatform;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    try {
      final platforms = await PlatformRepository.getByStation(widget.stationId);
      Platform? preSelected;
      if (widget.platformId != null) {
        preSelected = platforms.where((p) => p.uid == widget.platformId).firstOrNull;
      }
      if (mounted) {
        setState(() {
          _platforms = platforms;
          _selectedPlatform = preSelected;
        });
      }
    } catch (_) {}
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() => _isLoading = true);
    try {
      final result = await StationCleaningRepository.listAreas(widget.stationId);
      final list = (result['areas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      List<Map<String, dynamic>> filtered = list;
      if (_selectedPlatform?.uid != null) {
        filtered = filtered.where((a) => a['platformId'] == _selectedPlatform!.uid).toList();
      } else if (widget.platformId != null) {
        filtered = filtered.where((a) => a['platformId'] == widget.platformId).toList();
      }
      if (mounted) {
        setState(() {
          _areas = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('AUTH_ERROR') ? 'Session expired' : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _existingMainAreas {
    final set = <String>{};
    for (final a in _areas) {
      final m = a['mainArea'] as String?;
      if (m != null && m.isNotEmpty) set.add(m);
    }
    final sorted = set.toList()..sort();
    return sorted;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedAreas {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final area in _areas) {
      final main = (area['mainArea'] as String?)?.isNotEmpty == true ? area['mainArea'] as String : 'Uncategorized';
      grouped.putIfAbsent(main, () => []);
      grouped[main]!.add(area);
    }
    final keys = grouped.keys.toList()..sort((a, b) {
      if (a == 'Uncategorized') return 1;
      if (b == 'Uncategorized') return -1;
      return a.compareTo(b);
    });
    final sortedGrouped = <String, List<Map<String, dynamic>>>{};
    for (final k in keys) {
      sortedGrouped[k] = grouped[k]!;
    }
    return sortedGrouped;
  }

  double get _totalBasicArea {
    double total = 0;
    for (final a in _areas) {
      total += (a['basicAreaSqFt'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double get _totalTenderedArea {
    double total = 0;
    for (final a in _areas) {
      total += (a['tenderedAreaPerDay'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<void> _showConfigDialog({Map<String, dynamic>? area}) async {
    final isEditing = area != null;
    final areaId = area?['uid'] ?? area?['id'] ?? '';

    final nameCtrl = TextEditingController(text: area?['areaName'] ?? '');
    final basicCtrl = TextEditingController(text: (area?['basicAreaSqFt'] as num?)?.toString() ?? '');
    final timesCtrl = TextEditingController(text: ((area?['frequencyTimes'] as num?)?.toInt() ?? 1).toString());

    String selectedMainArea = area?['mainArea'] as String? ?? '';
    String frequencyType = area?['frequencyType'] as String? ?? 'daily';
    bool showCustomMain = false;
    final customMainCtrl = TextEditingController(text: '');

    if (selectedMainArea.isNotEmpty && !_existingMainAreas.contains(selectedMainArea)) {
      showCustomMain = true;
      customMainCtrl.text = selectedMainArea;
    }

    Platform? dialogPlatform = area != null
        ? _platforms.where((p) => p.uid == (area['platformId'])).firstOrNull
        : _selectedPlatform;

    double calcTendered() {
      final basic = double.tryParse(basicCtrl.text) ?? 0;
      final times = int.tryParse(timesCtrl.text) ?? 1;
      return _calcTendered(basic, frequencyType, times);
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tendered = calcTendered();

          return AlertDialog(
            title: Text(isEditing ? 'Edit Area' : 'Add Area'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_platforms.isNotEmpty) ...[
                    DropdownButtonFormField<Platform>(
                      value: dialogPlatform,
                      decoration: const InputDecoration(
                        labelText: 'Platform',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.view_quilt),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Platform')),
                        ..._platforms.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (v) => setDialogState(() => dialogPlatform = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!showCustomMain)
                    DropdownButtonFormField<String>(
                      value: selectedMainArea.isNotEmpty && _existingMainAreas.contains(selectedMainArea)
                          ? selectedMainArea
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Main Area',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: [
                        ..._existingMainAreas.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                        const DropdownMenuItem(
                          value: '__add_new__',
                          child: Text('+ Add new', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == '__add_new__') {
                          setDialogState(() {
                            showCustomMain = true;
                            selectedMainArea = '';
                          });
                        } else {
                          setDialogState(() => selectedMainArea = v!);
                        }
                      },
                    ),
                  if (showCustomMain)
                    TextField(
                      controller: customMainCtrl,
                      decoration: InputDecoration(
                        labelText: 'Main Area (custom)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setDialogState(() {
                            showCustomMain = false;
                            customMainCtrl.clear();
                            selectedMainArea = _existingMainAreas.isNotEmpty ? _existingMainAreas.first : '';
                          }),
                        ),
                      ),
                      onChanged: (v) => selectedMainArea = v,
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sub-area Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: basicCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Basic Area (sq.ft.)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: frequencyType,
                    decoration: const InputDecoration(
                      labelText: 'Frequency Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (v) => setDialogState(() => frequencyType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Times per Period',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
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
                        Text(
                          'Tendered Area/day: ${_num(tendered)} sq.ft.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final mainArea = showCustomMain ? customMainCtrl.text : selectedMainArea;
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sub-area name is required')),
                    );
                    return;
                  }
                  if (!showCustomMain && mainArea.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select or add a main area')),
                    );
                    return;
                  }

                  final data = {
                    'areaName': nameCtrl.text.trim(),
                    'stationId': widget.stationId,
                    'platformId': dialogPlatform?.uid,
                    'mainArea': mainArea,
                    'basicAreaSqFt': double.tryParse(basicCtrl.text) ?? 0,
                    'frequencyType': frequencyType,
                    'frequencyTimes': int.tryParse(timesCtrl.text) ?? 1,
                  };

                  try {
                    if (isEditing) {
                      await StationCleaningRepository.updateArea(areaId, data);
                    } else {
                      await StationCleaningRepository.createArea(data);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadAreas();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedAreas;
    final totalBasic = _totalBasicArea;
    final totalTendered = _totalTenderedArea;

    return Scaffold(
      appBar: AppBar(title: Text('Area Config - ${widget.stationName}')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showConfigDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    if (_platforms.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: Colors.white,
                        child: DropdownButtonFormField<Platform>(
                          value: _selectedPlatform,
                          decoration: const InputDecoration(
                            labelText: 'Platform',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.view_quilt),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Platforms')),
                            ..._platforms.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.displayName, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedPlatform = v);
                            _loadAreas();
                          },
                        ),
                      ),
                    Expanded(
                      child: _areas.isEmpty
                          ? const Center(child: Text('No areas configured'))
                          : RefreshIndicator(
                              onRefresh: _loadAreas,
                              child: ListView(
                                children: [
                                  for (final entry in grouped.entries)
                                    _AreaGroupTile(
                                      mainArea: entry.key,
                                      areas: entry.value,
                                      onEdit: (a) => _showConfigDialog(area: a),
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                    ),
                    if (_areas.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kRailwayBlue.withOpacity(0.08),
                          border: Border(top: BorderSide(color: kRailwayBlue.withOpacity(0.3))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_areas.length} areas',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Basic area: ${_num(totalBasic)} sq.ft.'),
                                  Text('Tendered/day: ${_num(totalTendered)} sq.ft.',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadAreas,
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _AreaGroupTile extends StatelessWidget {
  final String mainArea;
  final List<Map<String, dynamic>> areas;
  final void Function(Map<String, dynamic> area) onEdit;

  const _AreaGroupTile({
    required this.mainArea,
    required this.areas,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: mainArea != 'Uncategorized',
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(mainArea, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${areas.length} area${areas.length == 1 ? '' : 's'}'),
        children: areas.map((area) {
          final basic = area['basicAreaSqFt'] as num?;
          final freqType = area['frequencyType'] as String?;
          final freqTimes = area['frequencyTimes'] as num?;
          final tendered = area['tenderedAreaPerDay'] as num?;
          final hasBoq = basic != null || freqType != null;

          String freqLabel;
          if (freqType != null && freqTimes != null) {
            freqLabel = '$freqType ${freqTimes}x';
          } else {
            freqLabel = area['cleaningFrequency'] as String? ?? '-';
          }

          return ListTile(
            dense: true,
            title: Text(area['areaName'] ?? 'Unnamed'),
            subtitle: hasBoq
                ? Text('Basic: ${_num(basic)} sq.ft. | Freq: $freqLabel | Tendered: ${_num(tendered)}/day')
                : Text('Freq: $freqLabel | Code: ${area['areaCode'] ?? '-'}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => onEdit(area),
            ),
          );
        }).toList(),
      ),
    );
  }
}
