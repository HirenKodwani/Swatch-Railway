import 'package:flutter/material.dart';
import 'package:crm_train/model/station_models.dart';
import 'package:crm_train/services/api_services.dart';
import 'package:crm_train/utills/app_colors.dart';
import 'area_form_screen.dart';

class AreaListScreen extends StatefulWidget {
  const AreaListScreen({super.key});

  @override
  State<AreaListScreen> createState() => _AreaListScreenState();
}

class _AreaListScreenState extends State<AreaListScreen> {
  List<Station> _stations = [];
  List<StationArea> _areas = [];
  Station? _selectedStation;
  bool _isLoadingStations = true;
  bool _isLoadingAreas = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoadingStations = true);
    try {
      _stations = await ApiService.getStations(active: true);
      if (_stations.isNotEmpty) {
        _selectedStation = _stations.first;
        _loadAreas();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoadingStations = false);
    }
  }

  Future<void> _loadAreas() async {
    if (_selectedStation == null) return;
    setState(() => _isLoadingAreas = true);
    try {
      _areas = await ApiService.getStationAreas(_selectedStation!.uid ?? _selectedStation!.stationCode);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoadingAreas = false);
    }
  }

  Future<void> _openForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AreaFormScreen(stationId: _selectedStation!.uid ?? _selectedStation!.stationCode)),
    );
    if (result == true) _loadAreas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Area Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingStations
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kErrorRed),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadStations, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: DropdownButtonFormField<Station>(
                        value: _selectedStation,
                        decoration: const InputDecoration(
                          labelText: 'Station',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.train),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _stations.map((s) => DropdownMenuItem(value: s, child: Text('${s.stationCode} - ${s.stationName}'))).toList(),
                        onChanged: (v) {
                          setState(() => _selectedStation = v);
                          _loadAreas();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _isLoadingAreas
                          ? const Center(child: CircularProgressIndicator())
                          : _areas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      const Text('No areas configured', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      Text('Add areas for ${_selectedStation?.stationName ?? "this station"}', style: TextStyle(color: Colors.grey[400])),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadAreas,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: _areas.length,
                                    itemBuilder: (context, index) {
                                      final a = _areas[index];
                                      return Card(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: kRailwayBlue.withOpacity(0.1),
                                            child: Text('${a.order}', style: TextStyle(color: kRailwayBlue, fontWeight: FontWeight.bold)),
                                          ),
                                          title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(a.description.isNotEmpty ? a.description : 'No description'),
                                          trailing: Icon(a.active ? Icons.check_circle : Icons.cancel, color: a.active ? kSuccessGreen : Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
      floatingActionButton: _selectedStation != null
          ? FloatingActionButton(
              onPressed: _openForm,
              backgroundColor: kRailwayBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
