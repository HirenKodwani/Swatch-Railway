import 'package:flutter/material.dart';
import 'package:crm_train/repositories/station_cleaning_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class StationZonesScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const StationZonesScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<StationZonesScreen> createState() => _StationZonesScreenState();
}

class _StationZonesScreenState extends State<StationZonesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _zones = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() => _isLoading = true);
    try {
      final result = await StationCleaningRepository.listZones(widget.stationId);
      setState(() {
        _zones = (result['zones'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
        setState(() { _error = 'Session expired'; _isLoading = false; });
        return;
      }
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _showZoneDialog({Map<String, dynamic>? zone}) async {
    final nameCtrl = TextEditingController(text: zone?['name'] ?? '');
    final areaIdCtrl = TextEditingController(text: zone?['areaId'] ?? '');
    final descCtrl = TextEditingController(text: zone?['description'] ?? '');
    final isEditing = zone != null;
    final zoneUid = zone?['uid'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Zone' : 'Add Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Zone Name')),
              TextField(controller: areaIdCtrl, decoration: const InputDecoration(labelText: 'Area ID')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'stationId': widget.stationId,
                'name': nameCtrl.text,
                'zoneName': nameCtrl.text,
                'areaId': areaIdCtrl.text,
                'description': descCtrl.text,
              };
              try {
                if (isEditing) {
                  await StationCleaningRepository.updateZone(zoneUid, data);
                } else {
                  await StationCleaningRepository.createZone(data);
                }
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
    if (result == true) _loadZones();
  }

  Future<void> _deleteZone(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Zone'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await StationCleaningRepository.deleteZone(uid);
        _loadZones();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zones - ${widget.stationName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showZoneDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _zones.isEmpty
                  ? const Center(child: Text('No zones configured'))
                  : RefreshIndicator(
                      onRefresh: _loadZones,
                      child: ListView.builder(
                        itemCount: _zones.length,
                        itemBuilder: (ctx, i) {
                          final z = _zones[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(z['name'] ?? z['zoneName'] ?? 'Unnamed'),
                              subtitle: Text('Area: ${z['areaId'] ?? '-'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showZoneDialog(zone: z),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteZone(z['uid'] ?? ''),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
