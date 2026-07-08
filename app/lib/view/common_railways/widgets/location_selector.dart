import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm_train/providers/station_cleaning_provider.dart';

class LocationSelector extends StatefulWidget {
  final bool showStation;
  final bool showPlatform;
  final bool showArea;
  final String? initialStationId;
  final String? initialPlatformId;
  final String? initialAreaId;
  final ValueChanged<String>? onStationChanged;
  final ValueChanged<String>? onPlatformChanged;
  final ValueChanged<String>? onAreaChanged;

  const LocationSelector({
    super.key,
    this.showStation = true,
    this.showPlatform = true,
    this.showArea = true,
    this.initialStationId,
    this.initialPlatformId,
    this.initialAreaId,
    this.onStationChanged,
    this.onPlatformChanged,
    this.onAreaChanged,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _platforms = [];
  List<Map<String, dynamic>> _areas = [];
  bool _loadingStations = false;
  bool _loadingPlatforms = false;
  bool _loadingAreas = false;

  String? _selStationId;
  String? _selPlatformId;

  @override
  void initState() {
    super.initState();
    _selStationId = widget.initialStationId;
    _selPlatformId = widget.initialPlatformId;
    if (widget.showStation) _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _loadingStations = true);
    final provider = context.read<StationCleaningProvider>();
    _stations = await provider.fetchStations();
    setState(() => _loadingStations = false);
    if (_selStationId != null) _loadPlatforms(_selStationId!);
  }

  Future<void> _loadPlatforms(String stationId) async {
    setState(() => _loadingPlatforms = true);
    final provider = context.read<StationCleaningProvider>();
    _platforms = await provider.fetchPlatforms(stationId);
    setState(() => _loadingPlatforms = false);
    if (_selPlatformId != null) _loadAreas(stationId, _selPlatformId!);
  }

  Future<void> _loadAreas(String stationId, String? platformId) async {
    setState(() => _loadingAreas = true);
    final provider = context.read<StationCleaningProvider>();
    _areas = await provider.fetchAreas(stationId, platformId: platformId);
    setState(() => _loadingAreas = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showStation) _buildDropdown('Station', _stations, _selStationId, _loadingStations, (v) {
              setState(() {
                _selStationId = v;
                _selPlatformId = null;
                _areas = [];
              });
              widget.onStationChanged?.call(v ?? '');
              if (v != null) {
                _loadPlatforms(v);
                context.read<StationCleaningProvider>().selectStation(
                  v, _stations.firstWhere((s) => s['uid'] == v || s['id'] == v)['stationName'] ?? '');
              }
            }),
            if (widget.showPlatform && _selStationId != null) ...[
              const SizedBox(height: 8),
              _buildDropdown('Platform', _platforms, _selPlatformId, _loadingPlatforms, (v) {
                setState(() {
                  _selPlatformId = v;
                  _areas = [];
                });
                widget.onPlatformChanged?.call(v ?? '');
                if (v != null) {
                  _loadAreas(_selStationId!, v);
                  context.read<StationCleaningProvider>().selectPlatform(
                    v, _platforms.firstWhere((p) => p['uid'] == v || p['id'] == v)['platformName'] ?? '');
                }
              }),
            ],
            if (widget.showArea && _selStationId != null && _selPlatformId != null) ...[
              const SizedBox(height: 8),
              _buildDropdown('Area', _areas, null, _loadingAreas, (v) {
                widget.onAreaChanged?.call(v ?? '');
                if (v != null) {
                  context.read<StationCleaningProvider>().selectArea(
                    v, _areas.firstWhere((a) => a['uid'] == v || a['id'] == v)['areaName'] ?? '');
                }
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, String? selected, bool loading, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label, border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: loading ? SizedBox(width: 20, height: 20, child: Padding(
          padding: const EdgeInsets.all(10), child: const CircularProgressIndicator(strokeWidth: 2),
        )) : null,
      ),
      isExpanded: true,
      items: [
        if (selected == null) DropdownMenuItem(value: null, child: Text('Select $label')),
        ...items.map((item) {
          final id = item['uid'] ?? item['id'] ?? '';
          final name = item['stationName'] ?? item['platformName'] ?? item['areaName'] ?? item['name'] ?? '';
          return DropdownMenuItem(value: id.toString(), child: Text(name));
        }),
      ],
      onChanged: loading ? null : onChanged,
    );
  }
}
