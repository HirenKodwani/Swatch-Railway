import 'package:flutter/material.dart';
import 'package:crm_train/repositories/station_cleaning_repository.dart';
import 'package:crm_train/utills/app_colors.dart';

class ContractorMappingScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  const ContractorMappingScreen({super.key, required this.stationId, required this.stationName});

  @override
  State<ContractorMappingScreen> createState() => _ContractorMappingScreenState();
}

class _ContractorMappingScreenState extends State<ContractorMappingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _mappings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    setState(() => _isLoading = true);
    try {
      final result = await StationCleaningRepository.listContractors(widget.stationId);
      setState(() {
        _mappings = (result['contractors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  Future<void> _showMappingDialog({Map<String, dynamic>? mapping}) async {
    final entityIdCtrl = TextEditingController(text: mapping?['entityId'] ?? '');
    final entityNameCtrl = TextEditingController(text: mapping?['entityName'] ?? '');
    final serviceTypeCtrl = TextEditingController(text: mapping?['serviceType'] ?? 'Station Cleaning');
    final areaIdCtrl = TextEditingController(text: mapping?['areaId'] ?? '');
    final isEditing = mapping != null;
    final mapUid = mapping?['uid'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Mapping' : 'Map Contractor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: entityIdCtrl, decoration: const InputDecoration(labelText: 'Entity ID')),
              TextField(controller: entityNameCtrl, decoration: const InputDecoration(labelText: 'Entity Name')),
              TextField(controller: serviceTypeCtrl, decoration: const InputDecoration(labelText: 'Service Type')),
              TextField(controller: areaIdCtrl, decoration: const InputDecoration(labelText: 'Area ID')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'stationId': widget.stationId,
                'entityId': entityIdCtrl.text,
                'entityName': entityNameCtrl.text,
                'serviceType': serviceTypeCtrl.text,
                'areaId': areaIdCtrl.text,
              };
              try {
                if (isEditing) {
                  await StationCleaningRepository.updateContractorMapping(mapUid, data);
                } else {
                  await StationCleaningRepository.mapContractor(data);
                }
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEditing ? 'Update' : 'Map'),
          ),
        ],
      ),
    );
    if (result == true) _loadMappings();
  }

  Future<void> _deleteMapping(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Mapping'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await StationCleaningRepository.deleteContractorMapping(uid);
        _loadMappings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contractors - ${widget.stationName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: kRailwayBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showMappingDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _mappings.isEmpty
                  ? const Center(child: Text('No contractors mapped'))
                  : RefreshIndicator(
                      onRefresh: _loadMappings,
                      child: ListView.builder(
                        itemCount: _mappings.length,
                        itemBuilder: (ctx, i) {
                          final m = _mappings[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(m['entityName'] ?? 'Unnamed'),
                              subtitle: Text('${m['serviceType'] ?? '-'} | Area: ${m['areaId'] ?? 'All'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showMappingDialog(mapping: m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteMapping(m['uid'] ?? ''),
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
